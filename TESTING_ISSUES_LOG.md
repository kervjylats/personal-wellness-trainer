# Testing Issues Log � Personal Wellness Trainer

*Record any deviations from TESTING_CHECKLIST.md expectations here.*

---

## How to Use

For each issue found, add an entry using this format:

`
### Issue #N
**Date:** YYYY-MM-DD
**Role:** [Owner/Associate/Staff/Client]
**Job type:** [e.g. Yoga Studio]
**Screen:** [e.g. Network > Associates tab]
**Checklist item:** [Reference to specific checklist item, e.g. Phase 2.2 Step 5]
**What happened:** [what you saw]
**What you expected:** [what you think should've happened per checklist]
**Severity:** [Blocker / Critical / Major / Minor / Cosmetic]
**Status:** [Open / In Progress / Fixed / Won't Fix / Duplicate]
**Notes:** [any additional context, screenshots, steps to reproduce]
`

---

## Issues Found

<!-- Add issues below this line -->

### Issue #1
**Date:** 2026-09-06
**Role:** [To be filled during testing]
**Job type:** [To be filled during testing]
**Screen:** [To be filled during testing]
**Checklist item:** [To be filled during testing]
**What happened:** [To be filled during testing]
**What you expected:** [To be filled during testing]
**Severity:** [To be filled during testing]
**Status:** Open
**Notes:** [To be filled during testing]

### Issue #9
**Date:** 2026-10-12
**Role:** Owner
**Job type:** All
**Screen:** Activity hub > any module tile (Schedule/Catalog/Media/Reviews/etc.)
**Checklist item:** Phase D module walkthrough
**What happened:** Tapping a module tile opened a screen with no back button and no
bottom nav, and the URL never changed — the user was trapped (browser Back couldn't
help either, since the address bar still said `#/owner`). The eight module screens
set `automaticallyImplyLeading: false` on their AppBars.
**What you expected:** A back affordance returning to the hub.
**Severity:** Major
**Status:** Fixed (2026-10-12, Phase D — `automaticallyImplyLeading` removed from all
eight module screens; back arrow now appears when pushed, and implies nothing when a
screen is used as a shell tab body where `canPop` is false.)

### Issue #10
**Date:** 2026-10-12
**Role:** Owner
**Job type:** All (yoga/pilates/strength)
**Screen:** Module screens' AppBars + empty states
**Checklist item:** Phase D module walkthrough
**What happened:** AppBar titles and empty states rendered raw module ids —
`scheduling`, `reviews`, `No slots in scheduling` — because
`ConfigTerminology.labelFor()` has no case for module ids and `default:` returns the
key itself.
**What you expected:** Job-aware labels (`Schedule`, `Reviews`), matching the hub.
**Severity:** Minor
**Status:** Fixed (2026-10-12, Phase D — added `ConfigTerminology.moduleLabel()` with
an explicit fallback; six call sites updated: scheduling, reviews, reservations,
inventory, gps, delivery_fees. `catalog`/`media` resolve through real terminology
cases and were left alone.)

### Issue #11
**Date:** 2026-10-12
**Role:** Owner
**Job type:** All
**Screen:** Activity hub > Engagement chips (Community/Challenges/Homework/Rewards/Reviews)
**Checklist item:** Phase D module walkthrough
**What happened:** The five Engagement chips are bare `GestureDetector`s, so Flutter
merged their tap action and label into the hub's aggregate semantics node — no
`role=button` was exposed at all. Invisible to assistive tech, and automation's
`el.click()` had nothing bound to fire (coordinate clicks landed on the bottom nav
underneath the chips' rects instead).
**What you expected:** Each chip announced as a tappable button.
**Severity:** Major (a11y)
**Status:** Fixed (2026-10-12, Phase D — `Semantics(button: true, container: true)`
wrap on `_CompactEngagementChip`, the same pattern as the Round 8 dashboard-pill
fix.)

---

## Known Pre-Existing Issues (Not Blockers)

| # | Description | Checklist Reference | Status |
|---|-------------|---------------------|--------|
| 1 | Client picker on Homework screen shows all business-wide clients, not ownership-scoped | Client Checklist > Homework | **Fixed 2026-10-12** (Phase D: picker now scopes to `primaryPartnerId` for Partners, business-wide for Owners, mirroring NetworkScreen) |
| 2 | Create Account allows sign up as Associate/Client directly (not via invite) | Audit Findings �2.1 | Flagged, decision pending |
| 3 | Mock mode: invite links can't be clicked end-to-end on second device | Phase 5, Item 1 | By design (mock mode limitation) |
| 4 | Mock mode: no true real-time cross-account interaction | Phase 5, Item 2 | By design (mock mode limitation) |
| 5 | Mock mode: no real payment processing | Phase 5, Item 3 | By design (mock mode limitation) |
| 6 | Mock mode: data doesn't survive app reinstall/clear | Phase 5, Item 4 | By design (mock mode limitation) |
| 7 | Mock mode: image upload disabled | Phase 5, Item 5 | By design (mock mode limitation) |
| 8 | Mock mode: GPS tracking not enabled for any job type | Phase 5, Item 6 | By design (mock mode limitation) |

---

## Testing Session Log

| Session | Date | Tester | Phases Covered | Issues Found |
|---------|------|--------|----------------|--------------|
| 1 | 2026-09-06 | [Name] | [Phases] | [Count] |
| 2 | | | | |
| 3 | | | | |

---

## Summary Statistics

| Severity | Count |
|----------|-------|
| Blocker | 0 |
| Critical | 0 |
| Major | 0 |
| Minor | 0 |
| Cosmetic | 0 |
| **Total** | **0** |

*Update counts as issues are logged.*
