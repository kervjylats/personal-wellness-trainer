# Supabase Backend Review Report

## 1. Summary

**Files reviewed:** 21 Supabase source files (`lib/data/sources/supabase/`), 20 repository interfaces (`lib/data/repositories/`), 28 models (`lib/data/models/`), `supabase/schema.sql` (1,386 lines, 27 tables), `supabase/triggers.sql` (294 lines, now 8 functions).

**Issues found:** 14 total
- **Fixed directly:** 8 (clear mechanical bugs — typos, wrong column names, type mismatches, missing function)
- **Flagged for decision:** 6 (design questions requiring product judgment, not mechanical corrections)

## 2. Critical Findings

### CRITICAL 1 — `mark_challenge_day_complete` function did not exist

**What:** `supabase_challenges_source.dart:81` calls `.rpc('mark_challenge_day_complete')`, but `triggers.sql` had only 7 functions — this 8th function was never written. Every call would throw "function does not exist" at runtime.

**Why it matters:** The challenge completion feature was completely dead. Worse, `schema.sql` deliberately defines no UPDATE policy on `challenge_participants`, trusting this function as the only write path — so there was no working write path at all.

**What I did:** Created the function in `triggers.sql` with:
- `auth.uid() != p_user_id` authorization check
- Single atomic `UPDATE...WHERE` with `last_completed_date is distinct from current_date` idempotence guard
- Postgres `current_date` (never client-supplied)
- Idempotent return (returns existing row if already done today, mirroring mock behavior)

### CRITICAL 2 — `handle_new_user` trusts client-controlled signup metadata

**What:** The `AFTER INSERT ON auth.users` trigger reads `role` and `business_id` from `raw_user_meta_data`, which the client controls. `supabase_auth_source.dart:48-57` passes `'role': role` and optional `business_id` straight into `signUp(data:)`.

**Why it matters:** Anyone calling the Auth API directly can set `role='owner'` + `business_id=<victim UUID>` and the trigger inserts them as Owner of someone else's business. This is a genuine privilege escalation hole.

**What I did:** Flagged, not fixed. The correct fix requires a design decision: either force `role='client'` + fresh `business_id` in the trigger and promote via invite-token validation, or whitelist role values. I did not silently pick one.

### CRITICAL 3 — `profiles` UPDATE policy allows privilege escalation

**What:** The policy `using (auth.uid() = user_id)` had no `WITH CHECK` clause. `USING` constrains which existing rows match; without `WITH CHECK`, a user can rewrite their own row's `role`, `business_id`, `plan_tier`, or `is_active` fields.

**Why it matters:** Any authenticated user could promote themselves to owner or change their business association.

**What I did:** Added `WITH CHECK (auth.uid() = user_id)` to the policy. Also added an owner-scoped team management policy so owners can toggle flags and soft-delete team members (which was previously blocked by RLS).

### CRITICAL 4 — `profiles` has no INSERT policy (license activation broken)

**What:** `schema.sql` enables RLS on `profiles` but defines no INSERT policy. `supabase_auth_source.dart:153` (`activateLicenseKey`) does a direct `.insert()` which always fails with RLS denial.

**Why it matters:** License key activation can never succeed in real mode.

**What I did:** Flagged, not fixed. The correct fix is a `SECURITY DEFINER` RPC that validates the key server-side, not an open insert policy. Needs the key validation logic designed first.

### CRITICAL 5 — `ProgressEntryModel` date/created_at mismatch

**What:** Model's `fromJson` reads `json['date']`, but the table only has `created_at`. Every read crashes with `null as String` TypeError.

**Why it matters:** All progress entry reads fail.

**What I did:** Fixed `fromJson` to fall back to `created_at` (`json['date'] ?? json['created_at']`), and `toJson` to emit `created_at` instead of `date`.

### CRITICAL 6 — `supabase_auth_source` UserProfile crash on first activation

**What:** `activateLicenseKey` inserts a local map then calls `UserProfile.fromJson(newProfile)` on that same map, which lacks `joined_at` (a server default). Non-nullable `DateTime.parse` throws.

**Why it matters:** First-time license activation crashes even though the DB insert succeeds.

**What I did:** Changed to re-fetch the row after insert (`select().eq('user_id', userId).single()`) so server defaults are present.

## 3. Other Fixes Made

1. **`PointTransaction.fromJson` date fallback** (`loyalty_models.dart`): Now accepts `created_at` as fallback for `date`, and uses `(amount as num).toInt()` for PostgREST type safety.

2. **`getPoints` businessId filter** (`supabase_loyalty_source.dart`): Added missing `.eq('business_id', businessId)` to the points query. Also hardened `reason` (`as String? ?? ''`) and `amount`/`total_points` (`as num` casts).

3. **Inventory low-stock logic** (`supabase_inventory_source.dart`): Changed `stockCount <= lowStockThreshold` to `isLowStock` (which accounts for reserved units via `availableCount`).

4. **ConversationModel.toJson warning** (`conversation_model.dart`): Added comment that `unread_count` is client-only with no DB column — never pass to `.insert()`.

5. **Challenge join business check** (`schema.sql`): Extended `challenge_participants` INSERT policy to require the challenge belongs to the caller's business (prevents joining other businesses' private challenges by ID).

6. **`adjust_stock` oversell prevention** (`triggers.sql`): Replaced `greatest(0, ...)` clamp (which silently absorbed overdraws) with `WHERE stock_count + p_delta >= 0` rejection. Concurrent oversells now fail instead of succeeding silently.

## 4. Flagged, Not Fixed

> **Re-verification note (after full commit):** the first version of this
> report was pushed alongside only 9 files while the other 18 sources and
> 32 notifier/wiring files were on disk but uncommitted. All 51 files are
> now committed together. I re-checked each flagged item against the full
> picture — including whether previously-uncommitted files change the
> analysis. Verdicts below are confirmed accurate, with two refinements:
> (a) `supabase_team_source.dart`'s header (previously uncommitted)
> prescribes the fix direction for item 1 — force defaults in the
> trigger, reassign role/business in the future invite-accept step 2;
> (b) item 4 is downgraded — no send/create method exists in the
> notification source at all, so no current call site is broken; it is
> future work for when a send flow is built.

1. **`handle_new_user` metadata trust** (Critical 2 above): Needs decision on role/business_id validation strategy.

2. **`profiles` INSERT for license activation** (Critical 4 above): Needs `activate_profile()` RPC designed with key validation logic.

3. **`transactions`/`commissions` cross-business writes** (confirmed, precisely
   scoped): `transaction_notifier.dart:137-138` (`purchaseFromPartner`) books
   the purchase under `agreement.partnerBusinessId` — a business the caller
   is not a member of — so the transactions INSERT policy (caller must be in
   the row's business) rejects it in real mode. The notifier's own comment
   admits this only works in mock mode's shared store. Needs a
   `purchase_from_partner()` RPC. The commission leg (booked under the
   client's own coach business) is fine as a direct insert.

4. **`notifications` cross-business** (downgraded to future work):
   `supabase_notification_source.dart` has no send/create method at all —
   only get/markRead/delete, all self-scoped. No current call site is
   broken. When a send flow is built (e.g. partnership events notifying the
   receiver's business), it will need a narrow `notify_user()` RPC with
   relationship verification, since the INSERT policy requires membership
   in the notification's business.

5. **`loyalty_points` coach visibility** (confirmed, no broken call site):
   SELECT is self-only. The only `getPoints` caller
   (`loyalty_notifier.dart:37`) passes the caller's own IDs, so nothing is
   broken today. If coaches legitimately view client balances, add an
   owner/staff-of-business clause. Product decision needed.

6. **`supabase_team_source.inviteMember` always throws**: Correctly implements the signature but body is `throw UnimplementedError`. Intentional (needs `inviteeUserId` + real Auth signup), but don't route real-mode calls to it until the interface is extended.

## 5. Everything Checked Out

**Source files with no issues** (14 of 21):
- `supabase_activity_source.dart` — all 7 methods match interface
- `supabase_agreements_source.dart` — all 5 methods match
- `supabase_catalog_source.dart` — all 5 methods match
- `supabase_delivery_fees_source.dart` — all 6 methods match
- `supabase_finance_source.dart` — all 9 methods match
- `supabase_gps_source.dart` — all 4 methods match
- `supabase_homework_source.dart` — all 4 methods match
- `supabase_invite_source.dart` — all 5 methods match
- `supabase_marketplace_source.dart` — all 7 methods match
- `supabase_media_source.dart` — all 6 methods match
- `supabase_messaging_source.dart` — all 7 methods match
- `supabase_notification_source.dart` — all 5 methods match
- `supabase_reservations_source.dart` — all 6 methods match
- `supabase_reviews_source.dart` — all 6 methods match
- `supabase_scheduling_source.dart` — all 6 methods match

**SECURITY DEFINER functions with correct authorization** (6 of 8):
- `migrate_partner_clients` — checks `auth.uid() == partner_id`
- `get_invite_link_by_token` — no auth by design (unauthenticated invite accept, exact-token scoped)
- `mark_commission_paid` — requires Owner in commission's business
- `adjust_stock` — requires Owner in item's business
- `add_loyalty_points` — requires Owner in target business
- `redeem_loyalty_points` — checks `auth.uid() == p_user_id`, atomic `WHERE total_points >= p_amount`

**Concurrency verified:**
- `redeem_loyalty_points` — single atomic `UPDATE...WHERE`, race-safe. No fix needed.

**Schema tables with clean RLS** (19 of 27): agreements, activation_keys, invite_links, activities, marketplace_listings, partnership_requests, messages, schedule_slots, reservations, catalog_items, inventory_items, delivery_fees, media_items, reviews, rewards, challenges, homework, gps_points — all policies match their comments.

**Missing files note:** `supabase_scheduling_source.dart` and `supabase_reservations_source.dart` were absent at review start (delivered separately, since applied). Both verified present and correct; notifiers properly use real sources.

---

## Pass 2 — 2026-09-14

Targeted review of commit `eff9cfc` covering: rewritten `handle_new_user()` trigger, activation key single-use enforcement, `signUp()` call sites against new signature, `url_launcher` dependency, and exception message surfacing. Invoked from Claude's request to verify the unified invite/activation-key redemption flow.

### Fixes Made

**1. Activation key race condition in `handle_new_user()` (triggers.sql)**

Same class as the `adjust_stock` and `redeem_loyalty_points` races fixed in pass 1. The SELECT + UPDATE in Case 2 (activation key branch) were two separate statements — under PostgreSQL READ COMMITTED, two concurrent signups with the same key both passed the `redeemed_by_user_id IS NOT NULL` check, then both succeeded the UPDATE (the second overwrote the first's `redeemed_by_user_id`), creating two profiles for one key.

**Fix:** Added `AND redeemed_by_user_id IS NULL` to the UPDATE's WHERE clause + `if not found` check afterward — identical pattern to `adjust_stock` (`WHERE stock_count + p_delta >= 0`) and `redeem_loyalty_points` (`WHERE total_points >= p_amount`). The existing SELECT + null-check above stays as a fast-path for obviously-invalid codes.

### Flagged, Not Fixed

**2. Old `activateLicenseKey` path broken in real mode (auth_screen.dart → supabase_auth_source.dart:100)**

The old `activateLicenseKey` method does a direct INSERT into `profiles` (bypassing the trigger), which is blocked by RLS — the `profiles` table has no INSERT policy (flagged as Critical 4 in pass 1, never resolved). This means `auth_screen.dart`'s license key activation dialog silently fails in real mode. The new redemption flow (via `signUp(redemptionCode:)` + `handle_new_user()`) works correctly and is the intended replacement. Recommendation: deprecate the old path rather than migrating it, since the new marketing-page flow fully replaces what it was for. Needs a product decision.

**3. Exception message surfacing — untested**

The trigger raises `raise exception 'This activation key has already been used'` / `'Invalid redemption code'`. Whether Supabase's `supabase_flutter` wraps this in a generic `AuthException` or surfaces the exact message text through `authState.errorMessage` via `_friendlyError(e)` requires a real Supabase project to verify. Cannot pass/fail without runtime testing. Flag as untested.

### Confirmed Solid

**`handle_new_user()` trigger — all three branches secure:**
- Case 1 (invite token): role, business_id, category_id, primary_partner_id all resolve server-side from the `invite_links` row. Client only injects `display_name` (cosmetic). Referral chain resolution for client-invited-by-client correctly walks up to root owner.
- Case 2 (activation key): role hardcodes `'owner'`, plan_tier hardcodes `'premium'`, business_id is `uuid_generate_v4()`. Client injects nothing.
- Case 3 (fresh signup): role hardcodes `'owner'`, fresh business_id. Client injects nothing.

**`signUp()` call sites (4 total) — all clean:**
- `signup_screen.dart:54` — `redemptionCode: null` (genuine fresh Owner self-signup). Correct.
- `accept_invitation_screen.dart:150` — `redemptionCode: link.token`. Correct.
- `accept_invitation_screen.dart:180` — `redemptionCode: code`. Correct.
- `marketing_landing_screen.dart:74` — `redemptionCode: _codeController.text.trim()`. Correct.
- No old params (businessId, role, categoryId, primaryPartnerId) passed anywhere.
- No role re-assertions after signUp returns — `auth_notifier.dart:121` reads `profile.role` from the server-resolved profile, never overrides it.

**`resolve_redemption_code()` — correct:**
- Read-only preview function, no side effects. SECURITY DEFINER for unauthenticated access (before signup). TOCTOU between preview and signup is a UX concern only — the signup function correctly handles the "already used" case via the atomic fix above.

**`url_launcher` dependency — valid:**
- `pubspec.yaml:19` — `url_launcher: ^6.3.0`
- `pubspec.lock` — all 7 platform variants present
- `marketing_landing_screen.dart:105-106` — `canLaunchUrl(uri)` + `launchUrl(uri, mode: LaunchMode.externalApplication)` — correct API usage

**`invite_links` use_count increment — known accepted edge case:**
- Race could under-count by one in a genuine simultaneous-accept scenario, but doesn't affect correctness of who joined which business under which role. Deliberately not fixed (documented in invite_source.dart:69-75).

**All 8 SECURITY DEFINER functions — authorization checks verified:**
- `handle_new_user` — no auth needed (trigger on auth.users insert), but client can only pass opaque redemption_code
- `migrate_partner_clients` — checks `auth.uid() == partner_id`
- `get_invite_link_by_token` — no auth by design (exact-token scoped)
- `get_activation_key_by_code` — no auth by design (exact-code scoped, read-only)
- `resolve_redemption_code` — no auth by design (read-only preview, no side effects)
- `mark_commission_paid` — requires Owner in commission's business
- `adjust_stock` — requires Owner in item's business
- `add_loyalty_points` — requires Owner in target business
- `redeem_loyalty_points` — checks `auth.uid() == p_user_id`, atomic WHERE
- `mark_challenge_day_complete` — checks `auth.uid() == p_user_id`, atomic WHERE
