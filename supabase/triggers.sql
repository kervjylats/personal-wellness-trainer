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

    -- category_id / primary_partner_id are only ever present when this
    -- signup is really an invite acceptance (see SupabaseAuthSource.signUp
    -- and accept_invitation_screen.dart) — a plain Owner self-signup never
    -- sets them, and both stay null in that case, same as before this
    -- trigger knew about them.
    insert into public.profiles (
        user_id,
        business_id,
        role,
        display_name,
        email,
        plan_tier,
        category_id,
        primary_partner_id
    ) values (
        new.id,
        default_biz_id,
        default_role,
        coalesce(new.raw_user_meta_data->>'display_name', 'New Member'),
        new.email,
        'free',
        new.raw_user_meta_data->>'category_id',
        (new.raw_user_meta_data->>'primary_partner_id')::uuid
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
