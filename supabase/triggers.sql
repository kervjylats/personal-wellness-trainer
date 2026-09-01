-- supabase/triggers.sql
-- Personal Wellness Trainer Database Automations and Triggers

-- ── 1. AUTOMATIC PROFILE CREATION TRIGGER ────────────────────────────────────
-- Automatically inserts a row into the public profiles table when a user signs up.
create or replace function public.handle_new_user()
returns trigger as $$
declare
    default_role text;
    default_biz_id uuid;
begin
    -- Extract role and businessId from raw_user_meta_data if present, otherwise set defaults
    default_role := coalesce(new.raw_user_meta_data->>'role', 'client');
    default_biz_id := coalesce((new.raw_user_meta_data->>'business_id')::uuid, uuid_generate_v4());

    insert into public.profiles (
        user_id,
        business_id,
        role,
        display_name,
        email,
        plan_tier
    ) values (
        new.id,
        default_biz_id,
        default_role,
        coalesce(new.raw_user_meta_data->>'display_name', 'New Member'),
        new.email,
        'free'
    );
    return new;
end;
$$ language plpgsql security definer;

-- Bind the function as an after-signup trigger
create or replace trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();


-- ── 2. SAAS SPIN-OFF CLIENT MIGRATION FUNCTION ───────────────────────────────
-- Migrates a partner's invited clients over to their new workspace upon upgrading.
create or replace function public.migrate_partner_clients(
    partner_id uuid,
    new_business_id uuid
)
returns void as $$
begin
    -- Update all clients originally referred by the partner
    -- Moves their business_id to the partner's new independent business space
    update public.profiles
    set business_id = new_business_id
    where primary_partner_id = partner_id 
      and role = 'client';

    -- Also transfer any pending transactions linked to those clients
    update public.transactions
    set business_id = new_business_id
    where from_user_id in (
        select user_id from public.profiles where primary_partner_id = partner_id and role = 'client'
    );
end;
$$ language plpgsql security definer;