-- supabase/schema.sql
-- Personal Wellness Trainer Public Database Schema (FULLY UPDATED)
-- Run this script inside the Supabase SQL Editor.

create extension if not exists "uuid-ossp";

-- ── 1. PROFILES TABLE ────────────────────────────────────────────────────────
create table public.profiles (
    user_id uuid references auth.users on delete cascade primary key,
    business_id uuid not null,
    role text not null check (role in ('owner', 'partner', 'staff', 'client')),
    display_name text not null,
    email text,
    phone text,
    is_active boolean not null default true,
    joined_at timestamp with time zone not null default timezone('utc'::text, now()),
    
    -- Owner specific fields
    business_name text,
    business_logo_url text,
    primary_color text, 
    plan_tier text not null default 'free' check (plan_tier in ('free', 'pro', 'premium')),
    stripe_account_id text,
    job_id text,
    selected_category text,
    currency text not null default '$',
    branding_override jsonb, 

    -- Business-level feature toggles (owner rows only). Buyer/dev-facing
    -- controls: an Owner's end-client may not want the Partnership system
    -- at all, or wants Partners but not the cross-business Marketplace, or
    -- wants everything. Read off the OWNER's row by every business member
    -- (see businessFeaturesProvider) since it's a business-wide setting,
    -- not a personal one. Defaulting to true preserves today's behaviour
    -- for anyone who never touches this settings screen.
    partners_enabled boolean not null default true,
    marketplace_enabled boolean not null default true,
    agreements_enabled boolean not null default true,
    
    -- Partner specific fields
    category_id text,
    agreement_status text check (agreement_status in ('pending', 'active', 'terminated')),
    commission_rate double precision,
    feature_toggles jsonb default '{}'::jsonb,
    has_upgraded_to_pro boolean not null default false,
    
    -- Staff specific fields
    job_title text,
    permission_toggles jsonb default '{}'::jsonb,
    assigned_activity_count integer not null default 0,
    
    -- Client specific fields
    primary_partner_id uuid, 
    booking_count integer not null default 0,
    total_paid double precision not null default 0.0,
    outstanding_balance double precision not null default 0.0
);

alter table public.profiles enable row level security;

create policy "Allow public read access to active profiles" 
    on public.profiles for select 
    using (is_active = true);

create policy "Allow users to update their own profiles" 
    on public.profiles for update 
    using (auth.uid() = user_id);

-- ── 2. AGREEMENTS TABLE ──────────────────────────────────────────────────────
create table public.agreements (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    owner_user_id uuid references public.profiles(user_id) on delete cascade not null,
    partner_user_id uuid references public.profiles(user_id) on delete cascade not null,
    category_id text not null,
    owner_commission_pct double precision not null,
    partner_commission_pct double precision not null,
    status text not null check (status in ('proposed', 'active', 'declined', 'ended')),
    proposed_at timestamp with time zone not null default timezone('utc'::text, now()),
    responded_at timestamp with time zone,
    ended_at timestamp with time zone,
    notes text
);

alter table public.agreements enable row level security;

create policy "Allow members of the same business to view agreements"
    on public.agreements for select
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = agreements.business_id
        )
    );

-- ── 3. ACTIVATION KEYS TABLE 🎟️ (NEW) ─────────────────────────────────────────
create table public.activation_keys (
    key_code text primary key, -- e.g., 'ZEN-YOGA-777'
    job_id text not null,       -- e.g., 'yoga_studio'
    business_name text not null,
    primary_color text not null default '#2471A3'
);

alter table public.activation_keys enable row level security;

-- Allow public read access so the login screen can validate keys before account creation
create policy "Allow public read access to validation keys"
    on public.activation_keys for select
    using (true);

-- ── 4. TRANSACTIONS TABLE ────────────────────────────────────────────────────
create table public.transactions (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    amount double precision not null,
    currency_symbol text not null default '$',
    type text not null check (type in ('payment', 'commission', 'refund', 'payout')),
    status text not null check (status in ('pending', 'completed', 'cancelled')),
    created_at timestamp with time zone not null default timezone('utc'::text, now()),
    description text not null,
    activity_id uuid,
    commission_id uuid,
    agreement_id uuid references public.agreements(id) on delete set null,
    from_user_id uuid references public.profiles(user_id) on delete set null,
    to_user_id uuid references public.profiles(user_id) on delete set null,
    from_user_name text,
    to_user_name text,
    payment_provider text default 'manual',
    external_ref text,
    notes text
);

alter table public.transactions enable row level security;

create policy "Allow users to view their own transactions"
    on public.transactions for select
    using (
        auth.uid() = from_user_id or auth.uid() = to_user_id or 
        auth.uid() in (
            select user_id from public.profiles where role = 'owner' and business_id = transactions.business_id
        )
    );