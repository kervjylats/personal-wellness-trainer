# Personal Wellness Trainer — Master Testing Checklist

You're testing in **mock mode** — no Supabase needed, nothing here touches
a real database. Everything resets when you restart the app.

## How to start testing

1. `flutter run` (pick a device/emulator/Chrome — whatever you normally use)
2. On the login screen, look for a small **orange floating button**
   (bottom-right, dev-mode only) — tap it to open **Dev Quick Sign-In**
3. From there you can either:
   - Tap a **job type chip** (e.g. "Yoga Studio") → signs you in instantly
     as that job's **Owner**
   - Tap a **role chip** (Partner / Staff / Client) → signs you in as that
     role on whatever job you signed in as most recently
   - Tap **"Open QA Console (all 4 roles, live)"** → a special screen
     showing all 4 roles side-by-side at once, which is the fastest way to
     compare what each role can/can't see

**Test with more than one job type.** The app changes what's visible
based on which job type is active — different terminology, different
modules turned on/off. Suggested pair to cover the most ground:

- **Yoga Studio** — the "everything on" case (scheduling, reservations,
  catalog, reviews, agreements, media, all there)
- **Herbalist** — the only job types with **Delivery Fees** and
  **Inventory** turned on (everything else has them off)

⚠️ **Heads up:** none of the 15 configured job types currently have the
**GPS Tracking** module turned on. If you want to test that screen, you'd
need to edit `assets/config/job_types.json` and flip `"gps": true` on one
job entry — or just skip it for now and mention it to me, and I can help
you decide whether it needs a job type or should stay reserved for later.

## How to use this checklist

Check things off as you go. Where something's broken or off, jot a quick
note next to it — you don't need perfect bug reports, just enough that I
can find and reproduce it. There's a template at the bottom for sending
things back to me.

---

## Cross-cutting checks (apply to every role)

- [ ] App launches without crashing, straight to the login screen
- [ ] Dev Quick Sign-In button appears (confirms mock mode is active)
- [ ] Switching job type changes: the color scheme, wording (e.g. "Class"
      vs "Session"), and which nav tabs/modules are visible
- [ ] Bottom nav / tabs all switch screens correctly, no blank/frozen tabs
- [ ] Pull-to-refresh works on list screens (dashboard, activity, etc.)
- [ ] Empty states show sensible text (not "null" or a blank screen) on
      any list with no data yet
- [ ] Notification bell icon opens notifications, badge count looks right
- [ ] Signing out returns you cleanly to the login screen
- [ ] Rotating/resizing the window (if testing on web/desktop) doesn't
      break the layout

---

## Owner checklist

- [ ] **Dashboard** loads with sensible summary cards/stats
- [ ] **Content** (Activity) — list loads, create new one, open detail, edit,
      delete
- [ ] **Content → Tools cards** — Scheduling, Reservations, Catalog,
      Inventory, Media, Delivery Fees, and **Reviews** (new) each open
      correctly and only show up when the active job type actually uses
      that module
- [ ] **Revenue** (Finance) — transactions list loads, commission view (if
      applicable) loads, numbers look sane
- [ ] **Network → Partners tab** — list loads, **"Discover new partners"
      banner** at the top opens the Marketplace screen, browsing other
      businesses works, sending a partnership request works, and
      accepting/declining a request on the receiving end works (accepting
      currently just shows a confirmation — see note below)
- [ ] **Network → Staff tab** — list loads, invite works
- [ ] **Network → Clients tab** — list loads, invite works
- [ ] **Chat icon (top bar, next to the bell)** — opens the full
      conversations list; per-row chat icons on member tiles still work too
- [ ] **Notifications** — bell icon list loads, marking as read works
- [ ] **Settings** — Own Business screen, Branding screen (color change
      propagates app-wide — this was a real bug I fixed, worth
      double-checking)

## Partner checklist

- [ ] **Dashboard** loads, shows the upgrade banner at the top of every tab
- [ ] Upgrade banner's button actually navigates somewhere sensible
- [ ] **Activity** — can view but *cannot* create (should be view-only, or
      whatever the intended permission is — flag if it feels wrong)
- [ ] **Finance** — partner-scoped view loads (should only show *their*
      numbers, not the owner's full business)
- [ ] **Network** — can see the owner + staff, but should **not** see
      other partners (this was specifically called out in the code as
      intentional — worth confirming it's actually true)
- [ ] AppBar title shows the partner's own business name, not just "Partner"

## Staff checklist

- [ ] **Dashboard** loads
- [ ] **Activity** — can view, and create if that's an enabled permission
      for staff in this job type
- [ ] Access is appropriately limited compared to Owner (no Settings/
      Finance-admin access, etc. — flag anything that feels like staff can
      see more than they should)

## Client checklist

- [ ] **Dashboard** loads
- [ ] **Activity Hub** — browse available classes/sessions
- [ ] **Payments** — client-facing payment history loads
- [ ] **Community Feed** — loads, can post/interact if that's supported
- [ ] **Challenges** — list loads, can join one
- [ ] **Homework** — list loads (if this job type uses it)
- [ ] **Rewards/Loyalty** — points/rewards screen loads
- [ ] **Profile** — client can view/edit their own profile
- [ ] Client should **not** be able to reach Settings, Finance-admin, Team
      management, or other owner/staff-only areas — try the QA Console
      side-by-side to sanity check this quickly

---

## Known gaps — don't report these, I already know

- Anything requiring a **real backend connection** — the app is Phase 9 of
  10, everything runs on mock data until the Supabase swap
- **Image upload** — intentionally a disabled placeholder for now
- **GPS Tracking** — no job type has it enabled yet (see note above)
- **Accepting a partnership request** (Network → Partners → Discover →
  accept a request) currently just confirms acceptance — it doesn't yet
  walk you into configuring the new partnership's terms. That's a real
  screen that needs building, not something broken by this round's
  changes.
- A second, unrelated "Discover" screen exists for the Client role (a
  client-facing feed of what's available from their coach) — also not
  wired up yet, separate from the Partners-tab Discover feature above.
  We'll look at it when you get to testing Client.

## Sending results back to me

Doesn't need to be fancy — paste something like this per issue:

```
Role: [Owner/Partner/Staff/Client]
Job type: [e.g. Yoga Studio]
Screen: [e.g. Reservations list]
What happened: [what you saw]
What you expected: [what you think should've happened]
```

And for ideas/suggestions, just describe them in plain language — "what if
X worked like Y instead" is totally fine, doesn't need to fit a template.
