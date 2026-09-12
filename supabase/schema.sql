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
    using (auth.uid() = user_id)
    -- WITH CHECK prevents privilege escalation: without it, a user could
    -- rewrite their own row's role/business_id/plan_tier/is_active.
    with check (auth.uid() = user_id);

-- Owners can manage their business's team members (toggle flags, soft-delete).
-- Same-business scoping prevents cross-business writes. WITH CHECK mirrors
-- the USING scope (an owner can't move a member — or themselves — into a
-- different business via this policy). Column-level grants below ensure
-- owners can only write the management columns, never role/business_id/
-- plan_tier — without them, an Owner could promote Staff to owner or move
-- members between businesses.
create policy "Allow owner to manage their business's members"
    on public.profiles for update
    using (auth.uid() in (
        select user_id from public.profiles
        where role = 'owner' and business_id = profiles.business_id
    ))
    with check (auth.uid() in (
        select user_id from public.profiles
        where role = 'owner' and business_id = profiles.business_id
    ));

-- Column privileges are the enforcement that RLS alone cannot do: RLS
-- policies are row-level, so without this, EITHER update policy above
-- would allow rewriting role/business_id/plan_tier/user_id. The grant
-- list below is the complete inventory of columns the app actually
-- writes via direct table updates (verified against every .update() call
-- on profiles in lib/): onboarding fields (self) + management flags
-- (owner). Everything else — role, business_id, plan_tier, user_id,
-- joined_at, email, financials — is unwritable via the API and must go
-- through a future SECURITY DEFINER function (e.g. invite-accept step 2).
revoke update on public.profiles from authenticated, anon;
grant update (
    business_name, selected_category, primary_color, job_id,
    feature_toggles, is_active,
    partners_enabled, marketplace_enabled, agreements_enabled
) on public.profiles to authenticated;

-- ── 2. AGREEMENTS TABLE ──────────────────────────────────────────────────────
create table public.agreements (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    owner_user_id uuid references public.profiles(user_id) on delete cascade not null,
    partner_user_id uuid references public.profiles(user_id) on delete cascade not null,
    -- The partner's OWN business_id. Equals business_id for a
    -- within-business (directly-invited Partner) agreement; differs for a
    -- marketplace (cross-tenant) agreement — see agreement_model.dart's
    -- own doc comment. A cross-tenant deal creates TWO rows (one per side,
    -- each under its own business_id), so this column never needs
    -- cross-tenant RLS reads — each business only ever reads its own row.
    partner_business_id uuid not null,
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

-- proposeAgreement() is Owner-gated in Dart (agreements_notifier.dart) —
-- mirrored here so the restriction holds even if a client bypassed the
-- app's own UI/logic layer entirely.
create policy "Allow owner to propose new agreements"
    on public.agreements for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where role = 'owner' and business_id = agreements.business_id
        )
    );

-- approve/decline/end have NO role gate in Dart — either side of the deal
-- (Owner or Partner) can respond, so this stays business-membership-scoped
-- rather than owner-only, matching that.
create policy "Allow business members to update their own agreements"
    on public.agreements for update
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

-- Pre-existing gap found while building SupabaseFinanceSource: this table
-- had RLS enabled with only a SELECT policy — meaning every insert
-- (manual entries AND purchaseFromPartner's cross-business purchases,
-- transaction_notifier.dart) was being silently denied by Postgres's
-- RLS default-deny, regardless of role. Same "your own business only"
-- scoping as commissions' insert policy above, for the same reason —
-- purchaseFromPartner is called by any authenticated business member,
-- not owner-only.
create policy "Allow business members to record transactions"
    on public.transactions for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where business_id = transactions.business_id
        )
    );

-- Needed for updateTransactionStatus() (FinanceRepository) and for
-- mark_commission_paid()'s SECURITY DEFINER function to be able to work
-- even for the rare case it's called in a context that still checks
-- table-level RLS.
create policy "Allow business members to update their own business's transactions"
    on public.transactions for update
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = transactions.business_id
        )
    );

-- ── 5. INVITE LINKS TABLE ────────────────────────────────────────────────────
-- Note: creating this link row does NOT create the invitee's account — an
-- invite link only becomes a real profiles row once the invitee actually
-- signs up through Supabase Auth (see accept_invitation_screen.dart /
-- SupabaseTeamSource.inviteMember's header comment for the two-step flow
-- this requires in real mode, unlike MockInviteSource's single-step version).
create table public.invite_links (
    id uuid default uuid_generate_v4() primary key,
    token text not null unique,
    business_id uuid not null,
    invited_by_user_id uuid references public.profiles(user_id) on delete cascade not null,
    invited_by_role text not null,
    target_role text not null check (target_role in ('owner', 'partner', 'staff', 'client')),
    category_id text,
    created_at timestamp with time zone not null default timezone('utc'::text, now()),
    expires_at timestamp with time zone,
    use_count integer not null default 0,
    max_uses integer not null default 0,
    label text
);

alter table public.invite_links enable row level security;

-- Only the business's own Owner/Staff/Partner should manage their invite
-- links — never a stranger enumerating other businesses' links.
create policy "Allow business members to view their own invite links"
    on public.invite_links for select
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = invite_links.business_id
        )
    );

create policy "Allow business members to create invite links"
    on public.invite_links for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where business_id = invite_links.business_id
        )
    );

-- A not-yet-authenticated visitor needs to look up a link BY TOKEN to see
-- the invite (accept_invitation_screen.dart), before they have any
-- session at all. That CANNOT be a `using (true)` policy on this table —
-- that would let anyone enumerate every business's invite tokens/roles/
-- IDs via a plain SELECT, not just look up the one token they already
-- have. Instead, token lookup goes through a SECURITY DEFINER function
-- (get_invite_link_by_token, below) that only ever returns the single
-- row matching the exact token passed in — the same pattern already used
-- for migrate_partner_clients(). No public SELECT policy exists on this
-- table at all; membership-scoped SELECT above is the only direct-read path.

create policy "Allow business members to update their own invite links"
    on public.invite_links for update
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = invite_links.business_id
        )
    );

create policy "Allow business members to delete their own invite links"
    on public.invite_links for delete
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = invite_links.business_id
        )
    );

-- ── 6. ACTIVITIES TABLE ──────────────────────────────────────────────────────
-- One table across every job type (yoga class, nutrition consult,
-- meditation session, etc) — job-specific fields (service_type,
-- scheduled_at, amount, notes, and anything else a given job's
-- activity_fields config defines) live in the `fields` jsonb column
-- rather than as real columns, matching ActivityModel's own design.
-- Visibility is intentionally business-wide at the RLS layer (any
-- business member can SELECT any activity in their business) — the
-- three-way split between "all activities," "just mine as staff," and
-- "just mine as a client" (see ActivityRepository's 3 getActivities*
-- methods) is application-level filtering on top of this, exactly
-- mirroring MockActivitySource's own getActivities(), which does no
-- per-role filtering itself either.
create table public.activities (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    created_by_user_id uuid references public.profiles(user_id) on delete set null,
    assigned_to_user_id uuid references public.profiles(user_id) on delete set null,
    client_user_id uuid references public.profiles(user_id) on delete set null,
    status text not null default 'pending',
    fields jsonb not null default '{}'::jsonb,
    notes text,
    created_at timestamp with time zone not null default timezone('utc'::text, now()),
    updated_at timestamp with time zone not null default timezone('utc'::text, now())
);

alter table public.activities enable row level security;

create policy "Allow business members to view their business's activities"
    on public.activities for select
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = activities.business_id
        )
    );

create policy "Allow business members to create activities"
    on public.activities for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where business_id = activities.business_id
        )
    );

create policy "Allow business members to update their business's activities"
    on public.activities for update
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = activities.business_id
        )
    );

create policy "Allow business members to delete their business's activities"
    on public.activities for delete
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = activities.business_id
        )
    );


-- ── 7. COMMISSIONS TABLE ─────────────────────────────────────────────────────
-- Read-only from a Partner's own perspective (they see only their own via
-- the SELECT policy below); the Owner sees all. Actually marking one paid
-- goes through the mark_commission_paid() function in triggers.sql, not a
-- direct UPDATE — see that function's comment for why (it also has to
-- create the matching transactions row, atomically).
create table public.commissions (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    agreement_id uuid references public.agreements(id) on delete set null,
    partner_id uuid references public.profiles(user_id) on delete set null not null,
    partner_name text not null,
    amount double precision not null,
    currency_symbol text not null default '$',
    rate double precision not null,
    rate_type text not null check (rate_type in ('percentage', 'fixed')),
    status text not null default 'pending' check (status in ('pending', 'paid', 'cancelled')),
    created_at timestamp with time zone not null default timezone('utc'::text, now()),
    activity_id uuid,
    transaction_id uuid references public.transactions(id) on delete set null,
    description text,
    paid_at timestamp with time zone
);

alter table public.commissions enable row level security;

create policy "Allow owner to view all business commissions"
    on public.commissions for select
    using (
        auth.uid() in (
            select user_id from public.profiles where role = 'owner' and business_id = commissions.business_id
        )
    );

create policy "Allow partner to view their own commissions"
    on public.commissions for select
    using (auth.uid() = partner_id);

-- recordCommission is called by any business-authenticated user completing
-- a cross-business purchase (transaction_notifier.dart's purchaseFromPartner)
-- — NOT owner-only, unlike recordTransaction's typical manual-entry case.
-- Scoped to "you can only insert a commission row for your OWN business",
-- which is what actually matters here — not which role you hold within it.
create policy "Allow business members to record commissions"
    on public.commissions for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where business_id = commissions.business_id
        )
    );

-- No direct UPDATE policy: marking a commission paid always goes through
-- mark_commission_paid() (SECURITY DEFINER, triggers.sql), which is the
-- only path allowed to change status/transaction_id/paid_at together.


-- ── 8. MARKETPLACE LISTINGS TABLE ────────────────────────────────────────────
-- ⚠️ OPEN DESIGN QUESTION, not silently resolved: marketplace_listing.dart's
-- own doc comment says platform_id is meant to scope cross-tenant discovery
-- (Blueprint §9/§18) — implying a buyer/dev could resell this SAME database
-- to multiple of their OWN sub-clients under different "platforms", each
-- seeing only their own platform's marketplace. But MockMarketplaceSource's
-- getDiscoverableListings() does NOT actually filter by platform_id at all
-- (checked directly — only checks: not self, different category,
-- discoverable=true, category in desiredCategories). Rather than silently
-- invent an isolation mechanism nobody has specified or tested (would need
-- a platform_id column on profiles too, to know the viewer's own value),
-- this matches the MOCK's actual tested behavior: every business in this
-- one Supabase project can discover every other one, platform_id stored
-- but not yet enforced as a filter. Revisit if true multi-platform
-- reseller isolation is actually wanted.
create table public.marketplace_listings (
    id uuid default uuid_generate_v4() primary key,
    platform_id text not null default 'platform_default',
    owner_user_id uuid references public.profiles(user_id) on delete cascade not null unique,
    business_id uuid not null,
    business_name text not null,
    owner_category_id text not null,
    discoverable boolean not null default false,
    open_categories text[] not null default '{}',
    updated_at timestamp with time zone not null default timezone('utc'::text, now()),
    tagline text,
    average_rating double precision
);

alter table public.marketplace_listings enable row level security;

-- Cross-tenant by design: any authenticated owner needs to browse OTHER
-- businesses' discoverable listings, not just their own. Matches the
-- interface's own header comment ("cross-tenant reads allowed").
--
-- Third OR clause: partner_offers_provider.dart reads a PARTNER's listing
-- (by their user_id, not the caller's own) to show a client "which
-- business is this active partnership with" — discoverable=true isn't
-- guaranteed to still hold at that point (it gates NEW marketplace
-- browsing, not already-established agreements; a business can toggle it
-- off after an agreement is already active). Without this clause, that
-- legitimate read would silently break the moment a partner turned
-- discoverability off post-agreement.
create policy "Allow any authenticated owner to view discoverable listings"
    on public.marketplace_listings for select
    using (
        discoverable = true
        or auth.uid() = owner_user_id
        or exists (
            select 1 from public.agreements
            where agreements.partner_business_id = marketplace_listings.business_id
            and agreements.status = 'active'
            and agreements.business_id in (
                select business_id from public.profiles where user_id = auth.uid()
            )
        )
    );

create policy "Allow owner to manage only their own listing"
    on public.marketplace_listings for insert
    with check (auth.uid() = owner_user_id);

create policy "Allow owner to update only their own listing"
    on public.marketplace_listings for update
    using (auth.uid() = owner_user_id);


-- ── 9. PARTNERSHIP REQUESTS TABLE ────────────────────────────────────────────
create table public.partnership_requests (
    id uuid default uuid_generate_v4() primary key,
    sender_owner_user_id uuid references public.profiles(user_id) on delete cascade not null,
    receiver_owner_user_id uuid references public.profiles(user_id) on delete cascade not null,
    sender_business_id uuid not null,
    sender_business_name text not null,
    sender_category_id text not null,
    receiver_category_id text not null,
    status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
    created_at timestamp with time zone not null default timezone('utc'::text, now()),
    message text,
    responded_at timestamp with time zone
);

alter table public.partnership_requests enable row level security;

create policy "Allow sender or receiver to view their own requests"
    on public.partnership_requests for select
    using (auth.uid() = sender_owner_user_id or auth.uid() = receiver_owner_user_id);

create policy "Allow owner to send a request"
    on public.partnership_requests for insert
    with check (auth.uid() = sender_owner_user_id);

-- Only the RECEIVER responds (accept/decline) — the sender doesn't get to
-- unilaterally flip their own request's status.
create policy "Allow receiver to respond to a request"
    on public.partnership_requests for update
    using (auth.uid() = receiver_owner_user_id);


-- ── 10. NOTIFICATIONS TABLE ──────────────────────────────────────────────────
-- Strictly single-owner (user_id) — never cross-tenant, never shared
-- between two users the way a conversation is. Simplest RLS of any table
-- so far: "it's yours or it isn't."
create table public.notifications (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.profiles(user_id) on delete cascade not null,
    business_id uuid not null,
    title text not null,
    body text not null,
    type text not null default 'system' check (type in ('message', 'agreement', 'team', 'activity', 'system')),
    created_at timestamp with time zone not null default timezone('utc'::text, now()),
    is_read boolean not null default false,
    reference_id uuid,
    reference_type text
);

alter table public.notifications enable row level security;

create policy "Allow users to view their own notifications"
    on public.notifications for select
    using (auth.uid() = user_id);

-- Notifications are created by app/engine events on someone ELSE's
-- behalf (e.g. a new message notifies its recipient, not its sender) —
-- so this can't be "insert only your own user_id" the way most tables
-- are. Scoped to "within your own business" instead, which is what
-- actually matters: nobody should be able to plant a notification on a
-- user in a business they have no relationship to at all.
create policy "Allow business members to create notifications for their business"
    on public.notifications for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where business_id = notifications.business_id
        )
    );

create policy "Allow users to update their own notifications"
    on public.notifications for update
    using (auth.uid() = user_id);

create policy "Allow users to delete their own notifications"
    on public.notifications for delete
    using (auth.uid() = user_id);


-- ── 11. CONVERSATIONS TABLE ──────────────────────────────────────────────────
-- Deliberately has NO unread_count column, unlike ConversationModel's own
-- field of that name — see supabase_messaging_source.dart's header
-- comment for why: MockMessagingSource stores it as one shared int per
-- conversation, and markConversationRead() resets it to 0 for EVERYONE
-- regardless of which user actually read it (checked directly — the
-- userId param is accepted but unused for that part). That's a real bug,
-- not just a simplification: in real mode, one participant reading a DM
-- would silently mark it "read" for the other person too. Computed live
-- per-viewer in the source file instead, correctly.
create table public.conversations (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    type text not null default 'direct' check (type in ('direct', 'group')),
    participant_ids uuid[] not null,
    participant_names text[] not null,
    created_at timestamp with time zone not null default timezone('utc'::text, now()),
    updated_at timestamp with time zone not null default timezone('utc'::text, now()),
    group_name text,
    last_message_content text,
    last_message_sender_id uuid,
    last_message_at timestamp with time zone
);

alter table public.conversations enable row level security;

-- Only participants can see a conversation exists at all.
create policy "Allow participants to view their own conversations"
    on public.conversations for select
    using (auth.uid() = any(participant_ids));

create policy "Allow business members to create conversations"
    on public.conversations for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where business_id = conversations.business_id
        )
    );

-- Needed for sendMessage()'s last_message_* denormalized-preview update.
create policy "Allow participants to update their own conversations"
    on public.conversations for update
    using (auth.uid() = any(participant_ids));


-- ── 12. MESSAGES TABLE ───────────────────────────────────────────────────────
-- is_read is a single shared boolean per message (matches MessageModel
-- exactly) — correct for a 'direct' (2-person) conversation, where "read"
-- unambiguously means "read by the other person." For a 'group'
-- conversation with 3+ participants, a single boolean CANNOT represent
-- each participant's independent read state — that would need a proper
-- per-participant join table (message_id, user_id, read_at), which the
-- rest of the app's UI doesn't know how to render today (it reads
-- message.isRead as one flat bool everywhere). This is a genuine
-- limitation of the existing model/UI, not something a repository
-- implementation can fix on its own without a larger, separately-scoped
-- change — flagging rather than silently working around it.
create table public.messages (
    id uuid default uuid_generate_v4() primary key,
    conversation_id uuid references public.conversations(id) on delete cascade not null,
    sender_id uuid references public.profiles(user_id) on delete set null,
    sender_name text not null,
    sender_role text not null,
    content text not null,
    created_at timestamp with time zone not null default timezone('utc'::text, now()),
    is_read boolean not null default false,
    attachment_id uuid,
    attachment_type text
);

alter table public.messages enable row level security;

create policy "Allow conversation participants to view messages"
    on public.messages for select
    using (
        conversation_id in (
            select id from public.conversations where auth.uid() = any(participant_ids)
        )
    );

create policy "Allow conversation participants to send messages"
    on public.messages for insert
    with check (
        conversation_id in (
            select id from public.conversations where auth.uid() = any(participant_ids)
        )
    );

create policy "Allow conversation participants to mark messages read"
    on public.messages for update
    using (
        conversation_id in (
            select id from public.conversations where auth.uid() = any(participant_ids)
        )
    );

-- Row policies alone can't restrict WHICH columns an UPDATE touches, only
-- which rows — without this, the update policy above would let any
-- participant rewrite another user's message content, not just toggle
-- is_read (the only thing the app's UI actually exposes, via
-- markConversationRead). Column-level GRANT closes that gap properly.
revoke update on public.messages from authenticated;
grant update (is_read) on public.messages to authenticated;


-- ── 13. SCHEDULE SLOTS TABLE ──────────────────────────────────────────────────
-- Business-membership-scoped, not per-user — matches scheduling_notifier.dart's
-- own createSlot() call site exactly: no role restriction there either, any
-- authenticated business member can create a slot for any staff member
-- (e.g. an Owner scheduling on a staff member's behalf).
create table public.schedule_slots (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    staff_user_id uuid references public.profiles(user_id) on delete cascade not null,
    start_time timestamp with time zone not null,
    end_time timestamp with time zone not null,
    is_available boolean not null default true,
    notes text,
    linked_activity_id uuid references public.activities(id) on delete set null
);

alter table public.schedule_slots enable row level security;

create policy "Allow business members to view their business's slots"
    on public.schedule_slots for select
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = schedule_slots.business_id
        )
    );

create policy "Allow business members to create slots"
    on public.schedule_slots for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where business_id = schedule_slots.business_id
        )
    );

create policy "Allow business members to update their business's slots"
    on public.schedule_slots for update
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = schedule_slots.business_id
        )
    );

create policy "Allow business members to delete their business's slots"
    on public.schedule_slots for delete
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = schedule_slots.business_id
        )
    );


-- ── 14. RESERVATIONS TABLE ────────────────────────────────────────────────────
-- Same business-membership-scoped pattern — reservations_notifier.dart's
-- updateStatus() has NO ownership check either (not "only the client who
-- holds it or assigned staff"), so RLS matches that same permission model
-- rather than inventing a stricter one the app's own Dart layer doesn't
-- linked_catalog_item_id's FK to catalog_items is added via ALTER TABLE
-- further down, once that table exists — see the comment there for why
-- it couldn't be inline here.
create table public.reservations (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    client_user_id uuid references public.profiles(user_id) on delete cascade not null,
    staff_user_id uuid references public.profiles(user_id) on delete set null,
    start_time timestamp with time zone not null,
    end_time timestamp with time zone not null,
    status text not null default 'pending' check (status in ('pending', 'confirmed', 'cancelled', 'completed', 'no_show')),
    notes text,
    linked_catalog_item_id uuid,
    linked_activity_id uuid references public.activities(id) on delete set null,
    created_at timestamp with time zone not null default timezone('utc'::text, now())
);

alter table public.reservations enable row level security;

create policy "Allow business members to view their business's reservations"
    on public.reservations for select
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = reservations.business_id
        )
    );

create policy "Allow business members to create reservations"
    on public.reservations for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where business_id = reservations.business_id
        )
    );

create policy "Allow business members to update their business's reservations"
    on public.reservations for update
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = reservations.business_id
        )
    );

create policy "Allow business members to delete their business's reservations"
    on public.reservations for delete
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = reservations.business_id
        )
    );


-- ── 15. CATALOG ITEMS TABLE ──────────────────────────────────────────────────
-- Business-membership-scoped for your OWN catalog, PLUS a read-only
-- cross-tenant clause for active catalog items — partner_offers_provider.dart
-- reads a PARTNER's active items (getActiveCatalogItems(partnerBusinessId))
-- to show a client "what can I buy from my coach's active partner", exactly
-- the same access pattern as marketplace_listings' cross-tenant SELECT
-- clause a few tables up. Never writable cross-tenant — only your own
-- business can insert/update/delete its own items.
create table public.catalog_items (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    title text not null,
    description text,
    price double precision not null,
    currency text not null default '$',
    category_tag text,
    image_url text,
    unit text,
    is_active boolean not null default true,
    created_at timestamp with time zone not null default timezone('utc'::text, now())
);

alter table public.catalog_items enable row level security;

create policy "Allow business members to view their own catalog"
    on public.catalog_items for select
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = catalog_items.business_id
        )
    );

create policy "Allow reading active catalog items of an active partner business"
    on public.catalog_items for select
    using (
        is_active = true
        and exists (
            select 1 from public.agreements
            where agreements.partner_business_id = catalog_items.business_id
            and agreements.status = 'active'
            and agreements.business_id in (
                select business_id from public.profiles where user_id = auth.uid()
            )
        )
    );

create policy "Allow business members to create catalog items"
    on public.catalog_items for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where business_id = catalog_items.business_id
        )
    );

create policy "Allow business members to update their own catalog items"
    on public.catalog_items for update
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = catalog_items.business_id
        )
    );

create policy "Allow business members to delete their own catalog items"
    on public.catalog_items for delete
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = catalog_items.business_id
        )
    );


-- ── Deferred FK: reservations → catalog_items ────────────────────────────────
-- catalog_items didn't exist yet when the reservations table was created
-- above — added now that it does, rather than reordering the whole file.
alter table public.reservations
    add constraint reservations_linked_catalog_item_id_fkey
    foreign key (linked_catalog_item_id)
    references public.catalog_items(id)
    on delete set null;


-- ── 16. INVENTORY ITEMS TABLE ─────────────────────────────────────────────────
-- adjustStock()'s delta-based update is NOT done as a client-side
-- read-then-write — see the adjust_stock() function (triggers.sql) for
-- why: two concurrent purchases decrementing the same item could both
-- read the same starting count and neither would see the other's
-- change, silently overselling stock. The function does the arithmetic
-- as one atomic UPDATE ... SET stock_count = stock_count + delta,
-- clamped, in a single statement — Postgres guarantees that's race-free
-- at the row level.
create table public.inventory_items (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    catalog_item_id uuid references public.catalog_items(id) on delete cascade not null,
    catalog_item_title text,
    stock_count integer not null default 0 check (stock_count >= 0),
    reserved_count integer not null default 0,
    low_stock_threshold integer not null default 5,
    updated_at timestamp with time zone not null default timezone('utc'::text, now())
);

alter table public.inventory_items enable row level security;

-- Owner-only module (see inventory_notifier.dart's own header comment,
-- and confirmed at the route level — inventoryListPath is only
-- registered inside ownerRoutes(), never partner/staff/clientRoutes()).
-- Unlike most tables so far, this is genuinely role-restricted, not just
-- business-membership-scoped — RLS matches that rather than the broader
-- default.
create policy "Allow owner to view their business's inventory"
    on public.inventory_items for select
    using (
        auth.uid() in (
            select user_id from public.profiles where role = 'owner' and business_id = inventory_items.business_id
        )
    );

create policy "Allow owner to create inventory records"
    on public.inventory_items for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where role = 'owner' and business_id = inventory_items.business_id
        )
    );

-- setReserved()/setLowStockThreshold() go through this normal UPDATE
-- policy directly (no race concern — they're absolute sets, not
-- deltas); only adjustStock()'s delta arithmetic goes through the
-- adjust_stock() function instead, for the atomicity reason above.
create policy "Allow owner to update their business's inventory"
    on public.inventory_items for update
    using (
        auth.uid() in (
            select user_id from public.profiles where role = 'owner' and business_id = inventory_items.business_id
        )
    );

create policy "Allow owner to delete their business's inventory"
    on public.inventory_items for delete
    using (
        auth.uid() in (
            select user_id from public.profiles where role = 'owner' and business_id = inventory_items.business_id
        )
    );


-- ── 17. DELIVERY FEES TABLE ───────────────────────────────────────────────────
-- Owner+Staff only — deliveryFeesPath is only registered inside
-- ownerRoutes() and staffRoutes() (role_routes.dart), never partner or
-- client routes, and no other file in the codebase reads this repository
-- at all (checked directly — no client-facing checkout flow consumes it
-- yet). RLS matches that actual reachable surface rather than defaulting
-- to the broader business-membership pattern most tables use.
create table public.delivery_fees (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    zone_label text not null,
    min_distance_km double precision not null,
    max_distance_km double precision not null,
    fee double precision not null,
    currency text not null default '$',
    is_active boolean not null default true
);

alter table public.delivery_fees enable row level security;

create policy "Allow owner and staff to view their business's delivery fees"
    on public.delivery_fees for select
    using (
        auth.uid() in (
            select user_id from public.profiles
            where business_id = delivery_fees.business_id and role in ('owner', 'staff')
        )
    );

create policy "Allow owner and staff to create delivery fee zones"
    on public.delivery_fees for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles
            where business_id = delivery_fees.business_id and role in ('owner', 'staff')
        )
    );

create policy "Allow owner and staff to update their delivery fee zones"
    on public.delivery_fees for update
    using (
        auth.uid() in (
            select user_id from public.profiles
            where business_id = delivery_fees.business_id and role in ('owner', 'staff')
        )
    );

create policy "Allow owner and staff to delete their delivery fee zones"
    on public.delivery_fees for delete
    using (
        auth.uid() in (
            select user_id from public.profiles
            where business_id = delivery_fees.business_id and role in ('owner', 'staff')
        )
    );


-- ── 18. MEDIA ITEMS TABLE ─────────────────────────────────────────────────────
-- Business-membership-scoped SELECT (any member can read) — the
-- Owner-sees-all vs Client-sees-public-only split is application-level
-- filtering on top (media_notifier.dart's role.isClient branch), same
-- pattern as Activity's 3-way split. No write restriction beyond business
-- membership either — createMediaItem() has no role gate at the Dart
-- layer.
create table public.media_items (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    uploaded_by_user_id uuid references public.profiles(user_id) on delete set null,
    title text not null,
    description text,
    media_type text not null check (media_type in ('video', 'audio', 'pdf', 'image')),
    url text not null,
    thumbnail_url text,
    is_public boolean not null default true,
    file_size_bytes bigint,
    created_at timestamp with time zone not null default timezone('utc'::text, now())
);

alter table public.media_items enable row level security;

create policy "Allow business members to view their business's media"
    on public.media_items for select
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = media_items.business_id
        )
    );

create policy "Allow business members to create media items"
    on public.media_items for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where business_id = media_items.business_id
        )
    );

create policy "Allow business members to update their business's media"
    on public.media_items for update
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = media_items.business_id
        )
    );

create policy "Allow business members to delete their business's media"
    on public.media_items for delete
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = media_items.business_id
        )
    );


-- ── 19. REVIEWS TABLE ─────────────────────────────────────────────────────────
-- Two restrictions stated directly in ReviewsRepository's own interface
-- doc comments, not just inferred from routing: setVerified is "Owner
-- only", deleteReview is "Owner or author only". Enforced here even
-- though the current Dart layer (reviews_notifier.dart) doesn't gate
-- either one itself — RLS being stricter than an unenforced Dart layer
-- is safe (review verification/moderation integrity matters regardless
-- of whether the UI has caught up to the documented contract yet).
create table public.reviews (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    author_user_id uuid references public.profiles(user_id) on delete cascade not null,
    target_user_id uuid references public.profiles(user_id) on delete cascade not null,
    rating integer not null check (rating >= 1 and rating <= 5),
    comment text,
    is_verified boolean not null default false,
    created_at timestamp with time zone not null default timezone('utc'::text, now())
);

alter table public.reviews enable row level security;

create policy "Allow business members to view their business's reviews"
    on public.reviews for select
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = reviews.business_id
        )
    );

-- Matches createReview()'s real call site exactly: authorUserId is
-- always the caller's own profile.userId — this just makes that
-- unforgeable at the data layer too, not just by Dart-layer convention.
create policy "Allow business members to create their own reviews"
    on public.reviews for insert
    with check (
        auth.uid() = author_user_id
        and auth.uid() in (
            select user_id from public.profiles where business_id = reviews.business_id
        )
    );

create policy "Allow owner to verify reviews"
    on public.reviews for update
    using (
        auth.uid() in (
            select user_id from public.profiles where role = 'owner' and business_id = reviews.business_id
        )
    );

-- Same reasoning as messages.is_read: row policies alone can't restrict
-- WHICH columns an UPDATE touches. ReviewsRepository doesn't even expose
-- a generic "edit review content" method — only setVerified() — so
-- rating/comment/author should never be editable via UPDATE at all, not
-- just restricted to the owner. Column-level GRANT closes that gap.
revoke update on public.reviews from authenticated;
grant update (is_verified) on public.reviews to authenticated;

create policy "Allow owner or the review's author to delete it"
    on public.reviews for delete
    using (
        auth.uid() = author_user_id
        or auth.uid() in (
            select user_id from public.profiles where role = 'owner' and business_id = reviews.business_id
        )
    );


-- ── 20. LOYALTY POINTS TABLES ─────────────────────────────────────────────────
-- Split into two tables where LoyaltyPoints (the model) has ONE nested
-- shape: loyalty_points holds the running total_points per user;
-- loyalty_point_transactions holds the earn/redeem history. The Supabase
-- source composes them back into one LoyaltyPoints per getPoints() call —
-- same "normalize in SQL, reconstruct the nested model in the source
-- file" approach as unreadCount in messaging.
--
-- addPoints()/redeemPoints() are NOT client-side read-then-write — see
-- add_loyalty_points()/redeem_loyalty_points() (triggers.sql). This
-- matters even more here than adjust_stock did: redeemPoints() has to
-- check "does the user have enough points" atomically, or two
-- simultaneous redemptions could both pass that check against the same
-- stale balance and both succeed — an actual free-reward exploit, not
-- just a display glitch.
create table public.loyalty_points (
    user_id uuid references public.profiles(user_id) on delete cascade primary key,
    business_id uuid not null,
    total_points integer not null default 0 check (total_points >= 0)
);

alter table public.loyalty_points enable row level security;

create policy "Allow users to view their own points balance"
    on public.loyalty_points for select
    using (auth.uid() = user_id);

-- No direct INSERT/UPDATE policy — rows are created/updated exclusively
-- via add_loyalty_points()/redeem_loyalty_points() (SECURITY DEFINER),
-- never a raw client insert/update, so the balance can never go negative
-- or be forged outside those two atomic paths.

create table public.loyalty_point_transactions (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references public.profiles(user_id) on delete cascade not null,
    business_id uuid not null,
    reason text not null,
    amount integer not null,
    created_at timestamp with time zone not null default timezone('utc'::text, now())
);

alter table public.loyalty_point_transactions enable row level security;

create policy "Allow users to view their own points history"
    on public.loyalty_point_transactions for select
    using (auth.uid() = user_id);

-- Same as loyalty_points — no direct INSERT policy; rows are only ever
-- created by the two SECURITY DEFINER functions.


-- ── 21. REWARDS TABLE ─────────────────────────────────────────────────────────
-- Owner-only management, matching the interface's own section comment
-- ("Rewards (Owner)") and confirmed at the route level (owner-rewards is
-- only registered inside ownerRoutes()). Reading the list is
-- business-wide though — every client needs to see what's redeemable.
create table public.rewards (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    title text not null,
    description text not null default '',
    points_cost integer not null,
    is_active boolean not null default true
);

alter table public.rewards enable row level security;

create policy "Allow business members to view their business's rewards"
    on public.rewards for select
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = rewards.business_id
        )
    );

create policy "Allow owner to create rewards"
    on public.rewards for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where role = 'owner' and business_id = rewards.business_id
        )
    );

create policy "Allow owner to delete their business's rewards"
    on public.rewards for delete
    using (
        auth.uid() in (
            select user_id from public.profiles where role = 'owner' and business_id = rewards.business_id
        )
    );


-- ── 22. CHALLENGES TABLES ─────────────────────────────────────────────────────
-- Business-membership-scoped throughout — createChallenge() has no role
-- gate at the Dart layer, matching Activity/Reservations/etc.
create table public.challenges (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    created_by_user_id uuid references public.profiles(user_id) on delete set null,
    title text not null,
    description text not null default '',
    duration_days integer not null,
    created_at timestamp with time zone not null default timezone('utc'::text, now()),
    is_active boolean not null default true
);

alter table public.challenges enable row level security;

create policy "Allow business members to view their business's challenges"
    on public.challenges for select
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = challenges.business_id
        )
    );

create policy "Allow business members to create challenges"
    on public.challenges for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where business_id = challenges.business_id
        )
    );

-- ── Challenge participants ───────────────────────────────────────────────────
-- markDayComplete()'s "once per day" rule and completedDays increment are
-- NOT a client-side check-then-write — see mark_challenge_day_complete()
-- (triggers.sql). Lower stakes than loyalty points (no money/stock
-- involved — worst case of a race here is a minor gamification counting
-- quirk, not an exploit), but made atomic anyway for consistency, and
-- because using Postgres's own current_date rather than the client's
-- clock avoids a client-side timezone/clock-skew bug independent of any
-- race concern.
create table public.challenge_participants (
    id uuid default uuid_generate_v4() primary key,
    challenge_id uuid references public.challenges(id) on delete cascade not null,
    user_id uuid references public.profiles(user_id) on delete cascade not null,
    user_name text not null,
    completed_days integer not null default 0,
    last_completed_date date,
    unique (challenge_id, user_id)
);

alter table public.challenge_participants enable row level security;

-- Business-wide visible (a leaderboard/participant list is normally
-- shown to everyone in the challenge's business, not just the
-- participant themselves) — scoped via the parent challenge's business_id.
create policy "Allow business members to view challenge participants"
    on public.challenge_participants for select
    using (
        challenge_id in (
            select id from public.challenges
            where business_id in (
                select business_id from public.profiles where user_id = auth.uid()
            )
        )
    );

-- Matches joinChallenge()'s real call site: userId is always the
-- caller's own auth.profile.userId, never someone joining on another's
-- behalf. Also requires the challenge belongs to the caller's business
-- (prevents joining another business's private challenges by ID).
create policy "Allow users to join a challenge as themselves"
    on public.challenge_participants for insert
    with check (
        auth.uid() = user_id
        and challenge_id in (
            select id from public.challenges
            where business_id in (
                select business_id from public.profiles
                where user_id = auth.uid()
            )
        )
    );

create policy "Allow users to leave a challenge they joined"
    on public.challenge_participants for delete
    using (auth.uid() = user_id);

-- No direct UPDATE policy — completedDays/lastCompletedDate only ever
-- change via mark_challenge_day_complete() (SECURITY DEFINER), never a
-- raw client update, so the "once per day" rule can't be bypassed by
-- calling the table directly instead of the function.


-- ── 23. HOMEWORK TABLE ────────────────────────────────────────────────────────
-- Business-membership-scoped throughout — assignHomework() has no role
-- gate at the Dart layer, matching Activity/Challenges/Reservations.
create table public.homework (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    assigned_by_user_id uuid references public.profiles(user_id) on delete set null,
    assigned_to_user_id uuid references public.profiles(user_id) on delete cascade not null,
    assigned_to_user_name text not null,
    title text not null,
    description text not null default '',
    is_completed boolean not null default false,
    created_at timestamp with time zone not null default timezone('utc'::text, now()),
    completed_at timestamp with time zone
);

alter table public.homework enable row level security;

create policy "Allow business members to view their business's homework"
    on public.homework for select
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = homework.business_id
        )
    );

create policy "Allow business members to assign homework"
    on public.homework for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where business_id = homework.business_id
        )
    );

create policy "Allow business members to update their business's homework"
    on public.homework for update
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = homework.business_id
        )
    );

create policy "Allow business members to delete their business's homework"
    on public.homework for delete
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = homework.business_id
        )
    );


-- ── 24. PROGRESS ENTRIES TABLE ────────────────────────────────────────────────
create table public.progress_entries (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    client_user_id uuid references public.profiles(user_id) on delete cascade not null,
    photo_urls text[] not null default '{}',
    metrics jsonb not null default '{}'::jsonb,
    notes text,
    created_at timestamp with time zone not null default timezone('utc'::text, now())
);

alter table public.progress_entries enable row level security;

-- Business-membership-scoped, not client-only — a coach (Owner/Staff)
-- legitimately needs to view AND add a client's progress entries (body
-- metrics, photos), not just the client themselves.
create policy "Allow business members to view their business's progress entries"
    on public.progress_entries for select
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = progress_entries.business_id
        )
    );

create policy "Allow business members to add progress entries"
    on public.progress_entries for insert
    with check (
        auth.uid() in (
            select user_id from public.profiles where business_id = progress_entries.business_id
        )
    );

create policy "Allow business members to delete their business's progress entries"
    on public.progress_entries for delete
    using (
        auth.uid() in (
            select user_id from public.profiles where business_id = progress_entries.business_id
        )
    );


-- ── 25. GPS POINTS TABLE ──────────────────────────────────────────────────────
-- Genuinely sensitive data (physical location), handled more
-- conservatively than most tables here. gps_notifier.dart's own Dart-layer
-- condition (!role.isStaff) is actually looser than what's really
-- reachable — the GPS tracking screen (gpsTrackingPath) is ONLY
-- registered inside ownerRoutes() (checked directly), so "see everyone's
-- latest location" is genuinely Owner-only in practice today. RLS matches
-- that real, more protective boundary rather than the looser Dart
-- condition — appropriate given how sensitive this data category is,
-- not just a style preference.
create table public.gps_points (
    id uuid default uuid_generate_v4() primary key,
    business_id uuid not null,
    user_id uuid references public.profiles(user_id) on delete cascade not null,
    latitude double precision not null,
    longitude double precision not null,
    label text,
    accuracy_metres double precision,
    linked_activity_id uuid references public.activities(id) on delete set null,
    recorded_at timestamp with time zone not null default timezone('utc'::text, now())
);

alter table public.gps_points enable row level security;

create policy "Allow users to view their own location history"
    on public.gps_points for select
    using (auth.uid() = user_id);

create policy "Allow owner to view all tracked users' locations"
    on public.gps_points for select
    using (
        auth.uid() in (
            select user_id from public.profiles where role = 'owner' and business_id = gps_points.business_id
        )
    );

-- Matches recordPoint()'s real call site exactly: always the caller's
-- own userId, recording their own current location, never on another
-- user's behalf.
create policy "Allow users to record their own location"
    on public.gps_points for insert
    with check (auth.uid() = user_id);

-- Matches clearMyPoints()'s real call site: always the caller clearing
-- their OWN history (GDPR/privacy use case) — not built as an
-- Owner-clears-someone-else's-data admin action anywhere in the app
-- today, so not opened up beyond that here either.
create policy "Allow users to clear their own location history"
    on public.gps_points for delete
    using (auth.uid() = user_id);
