# Static Review — Supabase Backend Implementation

You're reviewing code that has **never been run** — no Flutter/Dart
toolchain was available while it was written, and no real Supabase
project exists yet either. Every file was written and cross-checked
carefully by reading (call sites, models, RLS policies), but "carefully
read" and "compiles and runs correctly" are different things. Your job:
catch what careful reading can't.

This is a review, not a rebuild. Fix what you find directly if it's a
clear bug (typo, wrong column name, mismatched type), but flag anything
that looks like a real design question rather than silently deciding it
yourself.

## Scope

**20 Supabase source files**, all under `lib/data/sources/supabase/`:
`supabase_activity_source.dart`, `supabase_agreements_source.dart`,
`supabase_auth_source.dart`, `supabase_catalog_source.dart`,
`supabase_challenges_source.dart`, `supabase_delivery_fees_source.dart`,
`supabase_finance_source.dart`, `supabase_gps_source.dart`,
`supabase_homework_source.dart`, `supabase_inventory_source.dart`,
`supabase_invite_source.dart`, `supabase_loyalty_source.dart`,
`supabase_marketplace_source.dart`, `supabase_media_source.dart`,
`supabase_messaging_source.dart`, `supabase_notification_source.dart`,
`supabase_progress_source.dart`, `supabase_reservations_source.dart`,
`supabase_reviews_source.dart`, `supabase_scheduling_source.dart`,
`supabase_team_source.dart`.

Plus `supabase/schema.sql` (27 tables + RLS policies) and
`supabase/triggers.sql` (8 Postgres functions).

## Step 1 — Compile-level correctness

For every source file, cross-check against its own abstract repository
interface in `lib/data/repositories/`:
- Does every method the interface declares actually exist in the source
  file, with matching parameter names/types?
- Does every method the source file implements actually correspond to
  something in the interface (no orphaned extra methods)?
- Do `fromJson`/`toJson` calls on each model actually match that model's
  real field names? (Check the model file in `lib/data/models/` — don't
  assume the source file got the snake_case column names right.)
- Any obvious null-safety issues — a field marked non-nullable in Dart
  being read from a column that's nullable in `schema.sql`, or vice versa?

## Step 2 — Schema/RLS cross-check

For every table in `schema.sql`:
- Does every column referenced by its matching source file actually
  exist in the table definition, with a compatible type?
- Read each RLS policy's `using`/`with check` clause and confirm it
  actually matches the comment directly above it (comments were written
  to explain intent — check the SQL really does what the comment claims).
- Any table where a source file's Dart code assumes a write will succeed
  under RLS, but the policy would actually reject it for a legitimate,
  intended caller?

## Step 3 — The 8 Postgres functions (`triggers.sql`) — highest priority

These are `SECURITY DEFINER`, meaning they run with elevated privileges
and bypass RLS entirely — any authorization has to be inside the
function body itself, or it doesn't exist at all. Check each one:
`handle_new_user`, `migrate_partner_clients`, `get_invite_link_by_token`,
`mark_commission_paid`, `adjust_stock`, `add_loyalty_points`,
`redeem_loyalty_points`, `mark_challenge_day_complete`.

For each: does it check that the calling user (`auth.uid()`) is actually
authorized to do what they're asking, matching how the function is
really called from Dart? (`get_invite_link_by_token` is the one
deliberate exception — it's meant to be callable by someone with no
session at all, accepting an invite before they've signed up. That's
correct, not a gap.)

If you find one of these without a real authorization check, that's a
serious finding — flag it prominently, at the top of your report, not
buried in a list.

## Step 4 — Concurrency / atomicity

Three specific things were built as single atomic SQL statements
specifically to avoid race conditions: `adjust_stock` (inventory),
`redeem_loyalty_points` (can't over-redeem via two simultaneous
requests), `mark_challenge_day_complete` (uses Postgres's own
`current_date`, not a client-supplied date). Confirm each one really is
a single atomic statement doing the check-and-write together — not two
separate statements that could still race.

## Step 5 — Anything else that looks wrong

You don't need my permission to flag something outside this list if you
spot it. If a query looks like it'll throw at runtime, a foreign key
looks backwards, or a policy looks like it'd lock out a legitimate user
— write it up.

## Report

Create `SUPABASE_REVIEW_REPORT.md` with:

1. **Summary** — files reviewed, issues found, how many you fixed
   directly vs. flagged for a decision.
2. **Critical findings** — anything in the Step 3 category (missing
   authorization in a SECURITY DEFINER function). One per entry: what's
   wrong, why it matters, what you did about it.
3. **Other fixes made** — plain-language list, not just a diff.
4. **Flagged, not fixed** — anything that's a real design decision, not
   an obvious bug, with your reasoning for why you didn't just pick an
   answer.
5. **Everything checked out** — don't only report problems; say
   explicitly which files/functions you reviewed and found solid, so it's
   clear the coverage was real, not just a search for bugs that stopped
   at the first few files.
