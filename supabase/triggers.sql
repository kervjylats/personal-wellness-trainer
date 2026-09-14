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
-- row matching the exact token passed in.
create or replace function public.get_invite_link_by_token(p_token text)
returns setof public.invite_links as $$
begin
    return query
    select * from public.invite_links where token = p_token;
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
