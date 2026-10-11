-- supabase/triggers.sql
-- Personal Wellness Trainer Database Automations and Triggers

-- ── 1. AUTOMATIC PROFILE CREATION TRIGGER ────────────────────────────────────
-- Rewritten for the unified invite/activation-key redemption flow.
--
-- SECURITY FIX: this used to trust raw_user_meta_data's role/business_id
-- directly — meaning anyone calling Supabase Auth's signup endpoint
-- directly (bypassing the app's UI entirely) could claim role='owner' and
-- an arbitrary existing business_id, inserting themselves as the Owner of
-- a business they have no relationship to. Now the ONLY thing the client
-- can hand this trigger is a single opaque redemption_code — everything
-- else (role, business_id, category_id, primary_partner_id) is resolved
-- SERVER-SIDE from the actual invite_links/activation_keys row that code
-- points to. A client can no longer just assert who they are.
--
-- Three cases, tried in order:
--   1. redemption_code matches an invite_links token → joining an
--      EXISTING business as Partner/Staff/Client, exactly as that link
--      specifies. Client referral chains (a client invited by another
--      client) resolve to the inviting client's own owner here too —
--      moved from accept_invitation_screen.dart's old _resolveRealOwnerId
--      Dart logic into this single server-side place.
--   2. redemption_code matches an activation_keys code (and isn't
--      already redeemed) → spinning up a BRAND NEW Pro Owner business
--      from that key's pre-configured job/business_name/color. The key
--      is marked redeemed in this SAME transaction — atomic with the
--      profile creation, so a half-redeemed state can never exist.
--   3. No redemption_code at all → genuine fresh Owner self-signup
--      (SignupScreen, Owner-only) — fresh random business_id, role
--      'owner', plan_tier 'free', exactly like today.
create or replace function public.handle_new_user()
returns trigger as $$
declare
    v_code text;
    v_link public.invite_links;
    v_key public.activation_keys;
    v_resolved_role text;
    v_resolved_business_id uuid;
    v_resolved_category_id text;        -- profiles.category_id: Partner/Staff-specific specialty, only set on invite path
    v_resolved_selected_category text;  -- profiles.selected_category: Owner's own job category, only set on activation-key path
    v_resolved_primary_partner_id uuid;
    v_resolved_plan_tier text := 'free';
    v_resolved_business_name text;
    v_resolved_primary_color text;
    v_resolved_job_id text;
    v_inviter public.profiles;
begin
    v_code := new.raw_user_meta_data->>'redemption_code';

    if v_code is not null then
        -- Case 1: try invite_links first.
        select * into v_link from public.invite_links where token = v_code;

        if v_link.id is not null then
            -- M12: enforce expiry/uses SERVER-SIDE, not just in the Dart
            -- accept screen. Raising here aborts the whole signup
            -- transaction (same shape as the activation-key guards
            -- below), so a direct /auth/v1/signup call with a dead token
            -- can't mint a profile either. max_uses = 0 means unlimited,
            -- matching InviteLinkModel.isExhausted.
            if v_link.expires_at is not null and v_link.expires_at < now() then
                raise exception 'This invite link has expired';
            end if;
            if v_link.max_uses > 0 and v_link.use_count >= v_link.max_uses then
                raise exception 'This invite link has already been used';
            end if;

            v_resolved_business_id := v_link.business_id;
            v_resolved_role := v_link.target_role;
            v_resolved_category_id := v_link.category_id;

            if v_link.target_role = 'client' then
                -- Referral chains resolve to the ROOT owner/partner, not
                -- the immediate inviter, if the inviter is themselves a
                -- client — mirrors mock_team_source.dart's
                -- _resolveClientOwnerId exactly, moved here from what was
                -- previously accept_invitation_screen.dart Dart logic.
                select * into v_inviter from public.profiles where user_id = v_link.invited_by_user_id;
                if v_inviter.role = 'client' then
                    v_resolved_primary_partner_id := coalesce(v_inviter.primary_partner_id, v_link.invited_by_user_id);
                else
                    v_resolved_primary_partner_id := v_link.invited_by_user_id;
                end if;

                -- M9: referral bonus — the client dashboard promises
                -- "share this link; when they join they earn you loyalty
                -- points," and no call site anywhere ever awarded them
                -- (addPoints had zero callers in either mode). Awarded
                -- here, in the same transaction as the join, so it can't
                -- fire without the join actually happening (or twice if
                -- the signup is retried — the whole transaction
                -- rolls back together). Same 100 points and reason as
                -- the mock's seeded referral entry.
                if v_inviter.user_id is not null then
                    insert into public.loyalty_point_transactions (user_id, business_id, reason, amount)
                        values (v_inviter.user_id, v_inviter.business_id, 'Referred a friend', 100);
                    insert into public.loyalty_points (user_id, business_id, total_points)
                        values (v_inviter.user_id, v_inviter.business_id, 100)
                        on conflict (user_id) do update
                        set total_points = loyalty_points.total_points + 100;
                end if;
            end if;

            -- Mark the link used, atomically, in the same transaction as
            -- the profile it creates.
            update public.invite_links set use_count = use_count + 1 where id = v_link.id;

        else
            -- Case 2: try activation_keys.
            select * into v_key from public.activation_keys where key_code = v_code;

            if v_key.key_code is null then
                raise exception 'Invalid redemption code';
            end if;
            if v_key.redeemed_by_user_id is not null then
                raise exception 'This activation key has already been used';
            end if;

            v_resolved_business_id := uuid_generate_v4();
            v_resolved_role := 'owner';
            v_resolved_plan_tier := 'premium';
            v_resolved_business_name := v_key.business_name;
            v_resolved_primary_color := v_key.primary_color;
            v_resolved_job_id := v_key.job_id;
            v_resolved_selected_category := v_key.job_id;

            update public.activation_keys
                set redeemed_by_user_id = new.id, redeemed_at = timezone('utc'::text, now())
                where key_code = v_code and redeemed_by_user_id IS NULL;

            if not found then
                raise exception 'This activation key has already been used';
            end if;
        end if;
    else
        -- Case 3: genuine fresh Owner self-signup — unchanged from before.
        v_resolved_business_id := uuid_generate_v4();
        v_resolved_role := 'owner';
    end if;

    insert into public.profiles (
        user_id,
        business_id,
        role,
        display_name,
        email,
        plan_tier,
        category_id,
        primary_partner_id,
        business_name,
        primary_color,
        job_id,
        selected_category
    ) values (
        new.id,
        v_resolved_business_id,
        v_resolved_role,
        coalesce(new.raw_user_meta_data->>'display_name', 'New Member'),
        new.email,
        v_resolved_plan_tier,
        v_resolved_category_id,
        v_resolved_primary_partner_id,
        v_resolved_business_name,
        v_resolved_primary_color,
        v_resolved_job_id,
        v_resolved_selected_category
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
    -- SECURITY DEFINER bypasses RLS entirely — this check is what stands
    -- in for it. Found missing during the Inventory round's audit of
    -- every function in this file: without it, ANY authenticated user
    -- could call this via RPC with an arbitrary partner_id and silently
    -- move a DIFFERENT partner's clients to a business of the caller's
    -- choosing. auth_notifier.dart's one real call site always passes
    -- the caller's own userId as partner_id — this check just enforces
    -- that's the only way it can be called.
    if auth.uid() != partner_id then
        raise exception 'Not authorized to migrate this partner''s clients';
    end if;

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

-- ── 3. INVITE LINK TOKEN LOOKUP FUNCTION ─────────────────────────────────────
-- SECURITY DEFINER so an unauthenticated visitor (accepting an invite,
-- before they have any session) can resolve a token to its link row —
-- WITHOUT a public RLS policy that would let anyone enumerate every
-- business's invite links via a plain table SELECT. Only returns the one
-- row matching the exact token passed in. Expired/exhausted links return
-- NO row (M12): policy is enforced at the read, not just in the app's
-- Dart validation layer.
create or replace function public.get_invite_link_by_token(p_token text)
returns setof public.invite_links as $$
begin
    return query
    select * from public.invite_links
     where token = p_token
       and (expires_at is null or expires_at > now())
       and (max_uses <= 0 or use_count < max_uses);
end;
$$ language plpgsql security definer;


-- ── 3b. ACTIVATION KEY LOOKUP FUNCTION ────────────────────────────────────────
-- Same reasoning as get_invite_link_by_token — no public SELECT policy
-- exists on activation_keys, so this is the only way to look one up
-- before having a session.
create or replace function public.get_activation_key_by_code(p_code text)
returns setof public.activation_keys as $$
begin
    return query
    select * from public.activation_keys where key_code = p_code;
end;
$$ language plpgsql security definer;


-- ── 3c. RESOLVE REDEMPTION CODE (PREVIEW) FUNCTION ───────────────────────────
-- Lets the universal redemption screen show the person what they're about
-- to do — "Join Sunrise Yoga as a Client" / "Create your own Pro business,
-- Sunrise Yoga" / a clear error — BEFORE they've entered email/password
-- and actually triggered handle_new_user(). Read-only preview only; the
-- real resolution (and the one-time-use enforcement) happens inside
-- handle_new_user() itself at actual signup time, not here — this can be
-- called repeatedly with no side effects, unlike redemption itself.
create or replace function public.resolve_redemption_code(p_code text)
returns table (
    kind text,               -- 'invite' | 'activation_key' | 'invalid'
    target_role text,
    business_name text,
    error_message text
) as $$
declare
    v_link public.invite_links;
    v_key public.activation_keys;
    v_owner_business_name text;
begin
    select * into v_link from public.invite_links where token = p_code;
    if v_link.id is not null then
        -- The preview must not vouch for a dead link (M12) — same
        -- predicate the lookup and redemption paths now enforce.
        if v_link.expires_at is not null and v_link.expires_at < now() then
            return query select 'invalid'::text, null::text, null::text, 'This invite link has expired'::text;
            return;
        end if;
        if v_link.max_uses > 0 and v_link.use_count >= v_link.max_uses then
            return query select 'invalid'::text, null::text, null::text, 'This invite link has already been used'::text;
            return;
        end if;
        select p.business_name into v_owner_business_name
            from public.profiles p
            where p.role = 'owner' and p.business_id = v_link.business_id
            limit 1;
        return query select 'invite'::text, v_link.target_role, v_owner_business_name, null::text;
        return;
    end if;

    select * into v_key from public.activation_keys where key_code = p_code;
    if v_key.key_code is not null then
        if v_key.redeemed_by_user_id is not null then
            return query select 'invalid'::text, null::text, null::text, 'This activation key has already been used'::text;
            return;
        end if;
        return query select 'activation_key'::text, 'owner'::text, v_key.business_name, null::text;
        return;
    end if;

    return query select 'invalid'::text, null::text, null::text, 'This code isn''t valid — check it and try again'::text;
end;
$$ language plpgsql security definer;


-- ── 4. MARK COMMISSION PAID FUNCTION ─────────────────────────────────────────
-- Atomically marks a commission paid AND creates its matching transactions
-- row — mirrors MockFinanceSource.markCommissionPaid() doing both in one
-- call. Must be one function, not two separate client-side calls: if the
-- transaction insert ever failed after the commission was already marked
-- paid, you'd have a "paid" commission with no actual money movement on
-- record. SECURITY DEFINER so it can look up the business's real Owner
-- (for the transaction's from_user_id/from_user_name) regardless of who's
-- actually calling this — unlike the mock, which hardcodes
-- 'usr_owner_001' since it only ever has the one seed business.
create or replace function public.mark_commission_paid(p_commission_id uuid)
returns public.commissions as $$
declare
    v_commission public.commissions;
    v_owner_id uuid;
    v_owner_name text;
    v_txn_id uuid;
begin
    select * into v_commission from public.commissions where id = p_commission_id;
    if v_commission is null then
        raise exception 'Commission % not found', p_commission_id;
    end if;

    -- SECURITY DEFINER bypasses RLS entirely — same class of gap as
    -- migrate_partner_clients above, found during the same audit pass.
    -- Without this, any authenticated user could mark ANY business's
    -- commission paid via RPC, fabricating a payout transaction for
    -- parties they have nothing to do with. Marking a commission paid is
    -- an Owner action (paying out a partner) — enforced here since the
    -- Dart layer (commission_notifier.dart) doesn't gate it either.
    if not exists (
        select 1 from public.profiles
        where user_id = auth.uid()
        and role = 'owner'
        and business_id = v_commission.business_id
    ) then
        raise exception 'Not authorized to mark this commission as paid';
    end if;

    select user_id, display_name into v_owner_id, v_owner_name
        from public.profiles
        where role = 'owner' and business_id = v_commission.business_id
        limit 1;

    insert into public.transactions (
        business_id, amount, currency_symbol, type, status, description,
        from_user_id, from_user_name, to_user_id, to_user_name,
        commission_id, agreement_id, payment_provider
    ) values (
        v_commission.business_id, v_commission.amount, v_commission.currency_symbol,
        'commission', 'completed', 'Commission payout to ' || v_commission.partner_name,
        v_owner_id, v_owner_name, v_commission.partner_id, v_commission.partner_name,
        v_commission.id, v_commission.agreement_id, 'manual'
    ) returning id into v_txn_id;

    update public.commissions
        set status = 'paid', transaction_id = v_txn_id, paid_at = timezone('utc'::text, now())
        where id = p_commission_id
        returning * into v_commission;

    return v_commission;
end;
$$ language plpgsql security definer;


-- ── 5. ADJUST STOCK FUNCTION ──────────────────────────────────────────────────
-- Atomic delta-based stock adjustment — see inventory_items table comment
-- (schema.sql) for why this can't be a client-side read-then-write.
-- Clamped to [0, 999999], matching MockInventorySource's own clamp exactly.
create or replace function public.adjust_stock(p_inventory_item_id uuid, p_delta integer)
returns public.inventory_items as $$
declare
    v_item public.inventory_items;
begin
    -- SECURITY DEFINER bypasses RLS entirely — caught during this same
    -- audit pass, applied here from the start rather than found missing
    -- after the fact like the two functions above. Owner-only, matching
    -- this table's RLS policies (schema.sql) — inventory is a genuinely
    -- role-restricted module, confirmed at the route level.
    if not exists (
        select 1 from public.inventory_items ii
        join public.profiles p on p.business_id = ii.business_id
        where ii.id = p_inventory_item_id and p.user_id = auth.uid() and p.role = 'owner'
    ) then
        raise exception 'Not authorized to adjust this inventory item';
    end if;

    update public.inventory_items
        -- Atomic check-and-write: stock_count + delta >= 0 in WHERE rejects
        -- oversells instead of silently clamping to 0. Concurrent updates
        -- serialize on the row lock; the loser re-evaluates against the new
        -- version and fails if insufficient.
        set stock_count = least(999999, stock_count + p_delta),
            updated_at = timezone('utc'::text, now())
        where id = p_inventory_item_id
          and stock_count + p_delta >= 0
        returning * into v_item;

    if v_item is null then
        -- Disambiguate not-found vs insufficient stock (failure path only,
        -- no race — the atomic UPDATE above already decided the outcome).
        if not exists (select 1 from public.inventory_items where id = p_inventory_item_id) then
            raise exception 'InventoryItem % not found', p_inventory_item_id;
        else
            raise exception 'Insufficient stock';
        end if;
    end if;

    return v_item;
end;
$$ language plpgsql security definer;


-- ── 6. ADD LOYALTY POINTS FUNCTION ───────────────────────────────────────────
-- Owner-only — no real call site for addPoints() exists anywhere in the
-- app yet (checked directly; only redeemPoints/createReward/deleteReward
-- are actually called today), so there's no live usage pattern to match.
-- Owner-only is the sensible default for "awarding" points as an
-- administrative action, consistent with Rewards management being
-- Owner-only too. Revisit if a real automated-earning trigger gets built
-- later (e.g. completing homework → auto-award points), which would need
-- a different, more specific authorization story than a human Owner
-- acting directly.
create or replace function public.add_loyalty_points(
    p_user_id uuid,
    p_business_id uuid,
    p_amount integer,
    p_reason text
)
returns public.loyalty_points as $$
declare
    v_points public.loyalty_points;
begin
    if not exists (
        select 1 from public.profiles
        where user_id = auth.uid() and role = 'owner' and business_id = p_business_id
    ) then
        raise exception 'Not authorized to award points for this business';
    end if;

    insert into public.loyalty_point_transactions (user_id, business_id, reason, amount)
        values (p_user_id, p_business_id, p_reason, p_amount);

    insert into public.loyalty_points (user_id, business_id, total_points)
        values (p_user_id, p_business_id, p_amount)
        on conflict (user_id) do update
        set total_points = loyalty_points.total_points + p_amount
        returning * into v_points;

    return v_points;
end;
$$ language plpgsql security definer;


-- ── 7. REDEEM LOYALTY POINTS FUNCTION ────────────────────────────────────────
-- The balance check ("does the user have enough points") happens INSIDE
-- this one atomic statement — not as a separate SELECT before an UPDATE
-- from Dart — so two simultaneous redemptions can't both pass the check
-- against the same stale balance. The UPDATE's WHERE clause itself
-- enforces sufficiency; if it matches zero rows, either the points row
-- doesn't exist or the balance was too low, and either way the
-- transaction never gets inserted.
create or replace function public.redeem_loyalty_points(
    p_user_id uuid,
    p_business_id uuid,
    p_amount integer,
    p_reason text
)
returns public.loyalty_points as $$
declare
    v_points public.loyalty_points;
begin
    -- Always the caller's own points — matches redeemPoints()'s one real
    -- call site (loyalty_notifier.dart), which always passes the
    -- caller's own userId, never someone else's.
    if auth.uid() != p_user_id then
        raise exception 'Not authorized to redeem points for another user';
    end if;

    update public.loyalty_points
        set total_points = total_points - p_amount
        where user_id = p_user_id and total_points >= p_amount
        returning * into v_points;

    if v_points is null then
        raise exception 'Not enough points';
    end if;

    insert into public.loyalty_point_transactions (user_id, business_id, reason, amount)
        values (p_user_id, p_business_id, p_reason, -p_amount);

    return v_points;
end;
$$ language plpgsql security definer;


-- ── 8. MARK CHALLENGE DAY COMPLETE FUNCTION ─────────────────────────────────
-- Single atomic UPDATE with the once-per-day guard inline. Uses Postgres's
-- own current_date (never a client-supplied date, which could be forged).
-- Caller must be the participant themselves. The challenge_participants
-- table has no UPDATE policy (schema.sql), so this function is the ONLY
-- write path for completed_days — RLS cannot be bypassed any other way.
create or replace function public.mark_challenge_day_complete(
    p_challenge_id uuid,
    p_user_id uuid
)
returns public.challenge_participants as $$
declare
    v_row public.challenge_participants;
begin
    -- Caller must be completing their own day, not someone else's.
    if auth.uid() != p_user_id then
        raise exception 'Not authorized to complete challenge day for another user';
    end if;

    -- Atomic increment with idempotence guard: only increments if not
    -- already completed today. Concurrent calls serialize on the row lock;
    -- the second re-evaluates last_completed_date against the new version
    -- and matches zero rows if the first already set it to today.
    update public.challenge_participants
        set completed_days = completed_days + 1,
            last_completed_date = current_date
        where challenge_id = p_challenge_id
          and user_id = p_user_id
          and last_completed_date is distinct from current_date
        returning * into v_row;

    if v_row is null then
        -- Either already completed today, or not a participant.
        -- Return the existing row (idempotent) rather than throwing —
        -- mirrors the mock source's behavior of returning unchanged state
        -- when already done today.
        select * into v_row from public.challenge_participants
            where challenge_id = p_challenge_id and user_id = p_user_id;
        if v_row is null then
            raise exception 'Not a participant in this challenge';
        end if;
    end if;

    return v_row;
end;
$$ language plpgsql security definer;

-- ── 12. LAUNCH OWN BUSINESS (associate → owner spin-out) ─────────────────────
-- Dart-side launchOwnBusiness() used to build a client-mangled id
-- ('biz_spin_<userId>') that is invalid for every uuid column this flow
-- touches (migrate_partner_clients RPC args, upgrade_events.business_id),
-- and profiles.role/business_id are API-unwritable by design (schema.sql
-- column grants) so the "new business" only ever existed in local state.
-- This function is the only sanctioned path: ONE atomic transaction mints
-- a REAL uuid business id, rewrites the caller's profile (partner → owner
-- of the new business), migrates their own clients across, and records
-- the audit event. Returns the new business id. Errors throw.
create or replace function public.launch_business()
returns uuid as $$
declare
    v_profile public.profiles;
    v_new_business_id uuid := uuid_generate_v4();
begin
    select * into v_profile from public.profiles where user_id = auth.uid();
    if v_profile is null then
        raise exception 'Not signed in';
    end if;
    if v_profile.role <> 'partner' then
        raise exception 'Only associates can launch their own business';
    end if;

    update public.profiles
       set role = 'owner',
           business_id = v_new_business_id,
           plan_tier = 'free',
           business_name = coalesce(v_profile.display_name || ' Space', v_profile.business_name),
           -- Category is re-chosen during onboarding (isNewOwner: true).
           selected_category = null,
           category_id = null
     where user_id = auth.uid();

    -- Migrate the associate's OWN clients into the new business — the
    -- same set migratePartnerClients() moves in mock mode.
    update public.profiles
       set business_id = v_new_business_id
     where role = 'client'
       and primary_partner_id = auth.uid()
       and business_id = v_profile.business_id;

    insert into public.upgrade_events
        (user_id, email, from_role, to_role, from_tier, to_tier, business_id)
    values
        (auth.uid(), v_profile.email, 'partner', 'owner',
         coalesce(v_profile.plan_tier, 'free'), 'free', v_new_business_id);

    return v_new_business_id;
end;
$$ language plpgsql security definer set search_path = public;

-- ── 13. MARKETPLACE COLLAB — ATOMIC TWO-SIDE AGREEMENT PAIR ──────────────────
-- Accepting a marketplace collab used to be three client-side writes: the
-- accepter's own row (proposed → active) plus a row inserted directly into
-- the SENDER's business — which RLS rightly blocks (agreements INSERT
-- policy requires ownership of the row's business). On failure the request
-- was already marked accepted with a one-sided agreement, and every retry
-- duplicated the accepter's row. This SECURITY DEFINER function writes
-- both sides in ONE transaction: the accepter's copy is created AND
-- immediately active (their business, their decision), the sender's copy
-- stays 'proposed' for their own review — mirroring
-- createMutualAgreementFromRequest in agreements_notifier.dart exactly,
-- including the swapped commission split on the sender's side.
-- Returns the accepter's (receiver-side) agreement id.
create or replace function public.create_agreement_pair(
    p_receiver_user_id uuid,     -- the owner accepting the request
    p_receiver_business_id uuid,
    p_sender_user_id uuid,       -- the owner who sent the request
    p_sender_business_id uuid,
    p_receiver_side_category_id text,
    p_sender_side_category_id text,
    p_receiver_owner_pct double precision,
    p_receiver_partner_pct double precision,
    p_notes text
) returns uuid as $$
declare
    v_receiver_side_id uuid;
begin
    if auth.uid() is distinct from p_receiver_user_id then
        raise exception 'Not authorized to accept this request';
    end if;

    -- The accepter's own copy: created AND immediately active.
    insert into public.agreements (
        business_id, owner_user_id, partner_user_id, partner_business_id,
        category_id, owner_commission_pct, partner_commission_pct,
        status, responded_at, notes
    ) values (
        p_receiver_business_id, p_receiver_user_id, p_sender_user_id,
        p_sender_business_id, p_receiver_side_category_id,
        p_receiver_owner_pct, p_receiver_partner_pct,
        'active', timezone('utc', now()), p_notes
    ) returning id into v_receiver_side_id;

    -- The sender's copy: proposed, waiting on their own review.
    -- Cross-tenant by nature — only a SECURITY DEFINER function may write it.
    insert into public.agreements (
        business_id, owner_user_id, partner_user_id, partner_business_id,
        category_id, owner_commission_pct, partner_commission_pct,
        status, notes
    ) values (
        p_sender_business_id, p_sender_user_id, p_receiver_user_id,
        p_receiver_business_id, p_sender_side_category_id,
        p_receiver_partner_pct, p_receiver_owner_pct,  -- split swapped, as mock
        'proposed', p_notes
    );

    return v_receiver_side_id;
end;
$$ language plpgsql security definer set search_path = public;

-- ── 14. CROSS-TENANT PURCHASE (client buys from a partner business) ──────────
-- transaction_notifier.purchaseFromPartner books the sale under the
-- SELLER's business (their revenue) and the referral commission under the
-- buyer's coach's business — the sale insert is cross-tenant and RLS
-- blocks it (transactions INSERT policy requires membership in the row's
-- business). This SECURITY DEFINER function validates the active
-- agreement, writes the sale on the seller's ledger and the commission on
-- the coach's, in ONE transaction. Returns the sale's transaction id.
create or replace function public.purchase_from_partner(
    p_buyer_user_id uuid,
    p_agreement_id uuid,
    p_item_title text,
    p_amount double precision,
    p_currency text,
    p_partner_name text
) returns uuid as $$
declare
    v_agreement public.agreements;
    v_buyer public.profiles;
    v_commission double precision;
    v_sale_id uuid;
    v_points integer;
begin
    if auth.uid() is distinct from p_buyer_user_id then
        raise exception 'Not authorized to purchase for another user';
    end if;

    select * into v_agreement from public.agreements
     where id = p_agreement_id and status = 'active';
    if v_agreement is null then
        raise exception 'No active agreement for this purchase';
    end if;

    select * into v_buyer from public.profiles where user_id = p_buyer_user_id;

    -- The sale lands on the SELLER's ledger — cross-tenant under definer
    -- privileges, mirroring the mock's single shared store.
    insert into public.transactions (
        business_id, amount, currency_symbol, type, status, description,
        agreement_id, from_user_id, from_user_name, to_user_id, payment_provider
    ) values (
        v_agreement.partner_business_id, p_amount, p_currency, 'payment',
        'completed', 'Sold "' || p_item_title || '" via associate referral',
        v_agreement.id, p_buyer_user_id,
        coalesce(v_buyer.display_name, 'Buyer'), v_agreement.partner_user_id, 'manual'
    ) returning id into v_sale_id;

    -- The referral commission on the coach's ledger (this agreement IS the
    -- coach's own copy, so v_agreement.business_id is their business).
    v_commission := p_amount * v_agreement.owner_commission_pct / 100.0;
    if v_commission > 0 then
        insert into public.commissions (
            business_id, agreement_id, partner_id, partner_name, amount,
            currency_symbol, rate, rate_type, status, description
        ) values (
            v_agreement.business_id, v_agreement.id, v_agreement.partner_user_id,
            p_partner_name, v_commission, p_currency,
            v_agreement.owner_commission_pct, 'percentage', 'pending',
            'Referral commission on "' || p_item_title || '"'
        );
    end if;

    -- M9: the buyer earns loyalty points on their purchase — 1 point per
    -- currency unit, same shape as the mock's seeded earn reasons.
    -- Awarded INSIDE this definer transaction because the obvious
    -- alternative, calling add_loyalty_points() from Dart, is owner-only
    -- and would reject the client-buyer awarding points to themselves.
    -- The balance row is stamped with the BUYER's own business — that is
    -- the key their loyalty screen reads (profile.businessId), not the
    -- seller's ledger.
    v_points := floor(p_amount)::integer;
    if v_points > 0 and v_buyer.user_id is not null then
        insert into public.loyalty_point_transactions (user_id, business_id, reason, amount)
            values (p_buyer_user_id, v_buyer.business_id,
                    'Purchase reward: "' || p_item_title || '"', v_points);
        insert into public.loyalty_points (user_id, business_id, total_points)
            values (p_buyer_user_id, v_buyer.business_id, v_points)
            on conflict (user_id) do update
            set total_points = loyalty_points.total_points + v_points;
    end if;

    return v_sale_id;
end;
$$ language plpgsql security definer set search_path = public;

-- ── 15. MEMBER DEACTIVATION RECOVERY (M10) ──────────────────────────────────
-- removeMember() sets profiles.is_active = false, but the profiles SELECT
-- policy (`is_active = true`) hides that row from EVERYONE — including the
-- owner who deactivated it. Without these two functions there is no way to
-- see or undo a removal anywhere in the app: a soft delete dressed up as a
-- permanent lockout (the removed user's sign-in also lost their own row;
-- the self-read exception in schema.sql handles that half).
-- Both functions are owner-gated: only the business owner may list or
-- toggle members, mirroring the profiles UPDATE policy for removal.

create or replace function public.get_deactivated_members(p_business_id uuid)
returns setof public.profiles as $$
begin
    if not exists (
        select 1 from public.profiles
         where user_id = auth.uid()
           and business_id = p_business_id
           and role = 'owner'
           and is_active = true
    ) then
        raise exception 'Only the business owner can list deactivated members';
    end if;

    return query
    select * from public.profiles
     where business_id = p_business_id
       and is_active = false;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.set_member_active(
    p_user_id uuid,
    p_business_id uuid,
    p_active boolean
) returns boolean as $$
declare
    v_owner public.profiles;
begin
    if not exists (
        select 1 from public.profiles
         where user_id = auth.uid()
           and business_id = p_business_id
           and role = 'owner'
           and is_active = true
    ) then
        raise exception 'Only the business owner can restore members';
    end if;

    -- WITH-CHECK-style guard: the target must belong to the owner's
    -- business, so this can never reactivate someone else's row.
    update public.profiles
       set is_active = p_active
     where user_id = p_user_id
       and business_id = p_business_id;

    return found;
end;
$$ language plpgsql security definer set search_path = public;

-- ── 16. NOTIFY USER (M5) ─────────────────────────────────────────────────────
-- Notifications were never created anywhere in real mode: the repository
-- had no write method at all (the bell only ever showed seeds in mock and
-- stayed empty in real). Engine events notify someone ELSE, and some of
-- those relationships are cross-business (marketplace collab accepted,
-- referral sale), where the direct insert policy ('member of the
-- notification's business') rejects the caller. This SECURITY DEFINER
-- function derives and validates the relationship server-side:
--   · same business → always allowed;
--   · different businesses → only if their two businesses share an
--     agreement row (the same relationship the cross-tenant finance and
--     agreement flows rely on).
-- The business stamp is always the RECIPIENT's own business — that is the
-- read key their getNotifications() query filters on, and a caller can't
-- plant notifications under an arbitrary business.
create or replace function public.notify_user(
    p_user_id uuid,
    p_business_id uuid,
    p_type text,
    p_title text,
    p_body text,
    p_reference_id uuid default null,
    p_reference_type text default null
) returns uuid as $$
declare
    v_caller_business uuid;
    v_target_business uuid;
    v_id uuid;
begin
    if auth.uid() is null then
        raise exception 'Not authenticated';
    end if;

    select business_id into v_caller_business
      from public.profiles where user_id = auth.uid();
    select business_id into v_target_business
      from public.profiles where user_id = p_user_id;

    if v_target_business is null then
        raise exception 'Unknown recipient';
    end if;
    if p_business_id is distinct from v_target_business then
        raise exception 'Notification business must match the recipient''s business';
    end if;

    if v_caller_business is distinct from v_target_business then
        if not exists (
            select 1 from public.agreements
             where (business_id = v_caller_business and partner_business_id = v_target_business)
                or (business_id = v_target_business and partner_business_id = v_caller_business)
        ) then
            raise exception 'No relationship with this user';
        end if;
    end if;

    insert into public.notifications (
        user_id, business_id, title, body, type, reference_id, reference_type
    ) values (
        p_user_id, v_target_business, p_title, p_body, p_type,
        p_reference_id, p_reference_type
    )
    returning id into v_id;

    return v_id;
end;
$$ language plpgsql security definer set search_path = public;
