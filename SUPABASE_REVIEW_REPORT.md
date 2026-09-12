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

1. **`handle_new_user` metadata trust** (Critical 2 above): Needs decision on role/business_id validation strategy.

2. **`profiles` INSERT for license activation** (Critical 4 above): Needs `activate_profile()` RPC designed with key validation logic.

3. **`transactions`/`commissions` cross-business writes**: Insert policies require caller in row's `business_id`, but cross-business purchases (buyer in seller's business) contradict this. Need to read `transaction_notifier.dart` to confirm which `business_id` is written, then likely build a `purchase_from_partner()` RPC.

4. **`notifications` cross-business**: Insert policy requires membership in notification's business, but partnership flows need to notify the receiver's business. Needs a narrow `notify_user()` RPC with relationship verification.

5. **`loyalty_points` coach visibility**: SELECT is self-only (`auth.uid() = user_id`). If coaches legitimately view client balances, add owner/staff-of-business clause. Product decision needed.

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
