# Repo Audit — Findings

Full pass through the areas touched or adjacent to this session's work
(ownership model, Business Features toggles, agreements gating, and their
knock-on effects through signup/onboarding/dev sign-in). Organized by what
needed fixing vs. what needs a decision from you vs. general notes.

---

## 1. Fixed this session

### 1.1 No business ever had a real "Owner" roster row — a foundational bug

**The bug:** `signUp()`, `completeOnboarding()`, and `devQuickSignIn()` all
only ever touched the *auth profile* (`UserProfile`) for a new Owner. None
of them ever created a matching row in the team roster
(`MockTeamSource`/`TeamMemberModel`). So a brand-new business's `businessId`
never matched anything in the roster store.

**Why that mattered:** `getMembers()` has a "Dynamic Fallback" for exactly
this situation — when it finds zero matches for a `businessId`, it clones
the *entire* seed roster (the one pre-built Owner, Partner, and 2 Clients)
and relabels them with the new business's id, then hands that back as if
it were real data. Concretely, this meant:

- Every brand-new Owner — from real signup, or any of the 15 job-type
  buttons in Dev Quick Sign-In — would immediately see a partner
  ("Jordan Partner") and two clients they never invited, on a business
  that's supposed to be empty.
- The **Business Features toggle screen we just built would silently fail**
  for every one of these Owners: flipping a switch calls
  `updateBusinessFeatures(ownerUserId, ...)`, which looks for a roster row
  matching that `userId` — and finds none, because it was never created.
  The switch would look like it worked for one frame, then revert on the
  next screen rebuild.
- Testing "3 separate owner signups" the way you described would have
  shown all 3 with an *identical* fake team, making it impossible to tell
  the businesses apart or test real invite/partnership behavior between
  genuinely distinct businesses.

**The fix:** added `MockTeamSource.ensureOwnerRow()` — an upsert that
guarantees a real, persisted Owner row exists. Wired it into all three
places an Owner can come into existence: `signUp()`, `completeOnboarding()`
(updates the same row with the business name/category once known), and
`devQuickSignIn()`. The old fallback-clone logic is left in place as a
safety net but should no longer trigger in normal use, since every real
Owner now leaves at least one genuine match (their own row) before
`getMembers()` is ever called.

**Files:** `mock_team_source.dart`, `auth_notifier.dart`.

---

## 2. Flagged — needs a decision from you, not silently fixed

### 2.1 Self-serve "Create Account" lets someone become a Partner or Client with no inviter at all

`SignupScreen` (reachable from the login screen's "Create Account" button)
lets a brand-new visitor sign up directly as either **'client' or
'partner'** — no invite link, no inviting business, nothing. Look at
`_selectedRole = 'client'` (the default) in `signup_screen.dart`.

This conflicts with the entire ownership model we've built this
conversation: *every* client and partner is supposed to have exactly one
direct inviter, resolved through the invite-link chain
(`_resolveClientOwnerId` in `mock_team_source.dart`). Someone who signs up
this way gets:
- A random, brand-new `businessId` (the mock signup path always mints one,
  originally written for Owner signup)
- No `primaryPartnerId` at all
- For a 'client' role specifically: no coach/business relationship
  whatsoever — they're a client of nobody

I didn't touch this, because there are two genuinely different ways to
fix it and only you know which matches your intent:
- **Remove self-serve signup for Partner/Client entirely** — make the
  invite link the *only* way in, and this screen becomes Owner-only (or is
  removed/redirects to "ask your coach for an invite link").
- **Build the missing piece** — after self-serve signup, route them into a
  "find/request to join a business" flow that doesn't currently exist,
  which would then need to assign ownership the same way an invite does.

Given everything else in this app is invite-first, my instinct is the
first option is more consistent with what you've described — but this is
a product call, not a bug I should silently patch.

### 2.2 Two integration tests may be stale, unrelated to this session

While checking whether my changes broke anything, I found
`integration_test/flows/block_08_partner_test.dart` has two tests
(`08_05` — Partner agreements screen, `08_06` — Partner discover/marketplace)
that search for the literal text "Agreements", "Deals", "Discover", or
"Marketplace" somewhere on the **Partner's own dashboard**. I could not
find that text anywhere in the Partner shell or dashboard slots — meaning
these two tests were likely already failing (or passing coincidentally)
*before* this session's changes, not something I broke. Worth confirming
when you run the suite. Separately, test `08_03`'s inline comment ("they
see Owner/Staff/Clients") is now stale — the rebuilt Partner Network
screen shows Owner (as a card) + Clients only, no Staff — but the
assertion itself (no literal "Partners" tab) still holds either way.

---

## 3. Notes — not bugs, just things worth knowing

- **The `getMembers()` fallback-clone is now mostly dead code, not
  removed.** I left it in rather than deleting it, since I couldn't rule
  out some edge case depending on it, and all 3 real call sites
  (`team_notifier`, `propose_agreement_screen`, `create_group_screen`)
  only ever query the *current user's own* `businessId` — which will now
  always have a real match. If you'd rather I remove it outright for
  cleanliness, say so.
- **`ensureOwnerRow` doesn't backfill `categoryId` until onboarding
  completes.** A dev-quick-signed-in Owner gets `categoryId` immediately
  (since `jobId` is known upfront in that flow); a *real* signup only gets
  it once `completeOnboarding()` runs, which matches how the rest of the
  onboarding flow already works (nothing else is known before then either).
