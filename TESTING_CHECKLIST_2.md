# Personal Wellness Trainer — Testing Checklist 2

This is a **delta checklist**, not a replacement — `TESTING_CHECKLIST.md`
still applies for everything it already covers. This one focuses only on
what changed since that round: a fix that was found to be missing (had to
be reapplied), two corrected integration tests, and the self-serve signup
change.

If you're pointing an AI agent at this, give it both files, but have it
run this one first — several of its checks confirm foundations the first
checklist assumes are already working.

---

## 1. Re-verify the roster-row fix — this is the most important item here

**Context:** an earlier round found and fixed a bug where no signup path
ever created a real team-roster entry for a new Owner — meaning every
new business would show a fake pre-populated partner and clients that
were never actually invited. That fix somehow didn't make it into the
version of the code most recently tested (it's possible only some files
from that round got applied) — it's been reapplied now, but given it
silently went missing once already, it's worth confirming directly
rather than assuming it's holding this time.

1. **Create Account** → sign up as a new Owner → complete onboarding.
2. Go to **Network** → confirm **all 3 tabs (Partners/Staff/Clients) are
   completely empty** — no "Jordan Partner," no "Sam"/"Riley" clients, no
   pre-existing data of any kind.
3. **Settings → Business Features** → flip any switch off, then back on
   → confirm it actually sticks (reload the screen / navigate away and
   back) rather than silently reverting. This was the other symptom of
   the same underlying bug — if the switch doesn't hold, the roster row
   still isn't being created correctly.
4. Repeat steps 1–3 with **Dev Quick Sign-In** (pick any job-type chip)
   instead of a real signup — same expectations apply there too.

If any of this fails, it's a regression of a previously-fixed bug, not a
new issue — flag it as such.

## 2. Self-serve signup is now Owner-only

**Context:** "Create Account" used to let someone sign up directly as a
Client or Partner with no invite at all, which had no real owner/business
behind it. Removed — every Client/Partner now has to arrive through a
real invite link, same as intended everywhere else in the app.

5. From the login screen, tap **Create Account** → confirm there is
   **no Client/Partner toggle anymore** — the form goes straight to
   name/email/password, and successfully creates an **Owner** account.
6. Confirm a small note is visible on this screen along the lines of
   *"Joining as a Partner or Client? You'll need an invite link..."* —
   this replaces the old toggle, so people looking for that path aren't
   left with no explanation.

## 3. Two integration-test corrections (informational — these are in
   `integration_test/flows/block_08_partner_test.dart`, not something you
   need to click through by hand, but worth knowing what changed and why)

- **`08_05` (Partner agreements screen)** — turned out to already be
  correct; an earlier audit flagged this incorrectly (searched the wrong
  folder and missed `PartnerDealsSlot`, which does show an "Agreements"
  label on a Partner's own dashboard). No code change needed here — if
  you want to spot-check it anyway: **Dev Quick Sign-In → Partner** →
  confirm a "My Deal" card is visible on the dashboard with the literal
  word **"Agreements"** as a small label above it.
- **`08_06` (Partner marketplace access)** — this one was a genuinely
  wrong test, not a missing feature. It asserted a Partner *should* have
  Discover/Marketplace access, which contradicts the intended design:
  Marketplace is for two already-Pro **Owners** discovering each other —
  a non-Pro Partner isn't an independent business yet, so there's nothing
  for them to offer there until they upgrade. The test now asserts the
  correct thing (Partner should **not** see this). Spot-check: **Dev
  Quick Sign-In → Partner** → dashboard should have **no** "Discover" or
  "Marketplace" text anywhere on it.

---

## 4. Mobile/Desktop testing is now available

The AI test harness (separate repo) had Android and Windows adapters that
were only ever scaffolded. If you've since had an agent work through
`PHASE_2_MOBILE_DESKTOP.md` in that repo, both platforms should now be
testable the same way Web already was — worth running this checklist
(and the original `TESTING_CHECKLIST.md`) again on whichever of those
actually got finished, since nothing in either checklist has been
verified on anything but Web so far.

---

## Sending results back

Same format as before:

```
Role: [Owner/Partner/Staff/Client]
Platform: [Web/Android/Windows]
Screen: [e.g. Network tab]
What happened: [what you saw]
What you expected: [what you think should've happened]
```
