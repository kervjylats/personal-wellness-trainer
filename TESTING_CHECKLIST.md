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
      businesses works, sending a partnership request works. See the
      dedicated **Partnership & Commission walkthrough** section below for
      the full accept → agreement → purchase → commission flow.
- [ ] **Network → Staff tab** — list loads, invite works
- [ ] **Network → Clients tab** — list loads, invite works
- [ ] **Chat icon (top bar, next to the bell)** — opens the full
      conversations list; per-row chat icons on member tiles still work too
- [ ] **Notifications** — bell icon list loads, marking as read works
- [ ] **Settings** — Own Business screen, Branding screen (color change
      propagates app-wide — this was a real bug I fixed, worth
      double-checking); Owner should **not** see any "Launch Your Own
      Practice" upgrade banner or a locked Branding tile — that's
      Partner-only

## Partner checklist

- [ ] **Dashboard** loads, shows the upgrade banner at the top of every tab
- [ ] Upgrade banner's button actually navigates somewhere sensible
- [ ] **Activity** — can view but *cannot* create (should be view-only, or
      whatever the intended permission is — flag if it feels wrong)
- [ ] **Finance** — partner-scoped view loads (should only show *their*
      numbers, not the owner's full business)
- [ ] **Network** — 2 tabs now: **Owner** and **Clients** (Staff removed
      — a limited-tier Partner doesn't get that visibility, only the
      owner who invited them + the shared client pool); on the
      **Clients** tab, an invite button should appear (bottom-right) —
      inviting a client here should add them to the same shared client
      pool the owner sees too
- [ ] **Upgrade to Pro** (Settings → Launch Your Own Practice) — see the
      dedicated walkthrough below; briefly, confirm your shell switches
      to the full Owner view immediately, no re-login needed
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
- [ ] **Partners tab** — one tab now covers both partner content and
      contacts (merged from a separate Network tab). See the dedicated
      walkthrough below for the full partner-content flow; on its own,
      confirm it loads without crashing even before any partnership
      exists (should show empty-state messages, not errors), shows your
      contacts (owner, partners, eligible staff) further down, and has a
      working invite button (bottom-right)
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

## Partnership & Commission walkthrough (new — needs Owner + Client)

This is the referral/commission feature — it genuinely needs two roles
in sequence to test properly, so it's split out from the per-role lists
above.

1. As **Owner** (job type A, e.g. Yoga Studio): Network → Partners →
   "Discover new partners" → send a request to one of the seeded
   businesses (e.g. Core Pilates) — or just use the already-seeded
   pending request sitting in your Partners tab
2. Accept that pending request → set a commission split in the dialog
   that appears → confirm
3. Check **Network → Partners** — the partnership should now show active
4. Switch to a **Client** under that same Owner (Dev Quick Sign-In →
   Client) → open the **Partners** tab (new) → you should see the
   partner business's shared-category items listed
5. Tap **Buy** on one of those items → confirm the purchase
6. Switch back to **Owner** → check **Revenue** → a new commission
   should appear, calculated from the actual rate you set in step 2 (not
   a flat 20% — if you ever see exactly 20% on every single purchase
   regardless of what rate you set, that's the old bug and something
   broke)
7. As **Client**, on the **Partners** tab, scroll down to the **Network**
   section → tap the **invite** button (bottom-right) → generate a link
   → this represents inviting another client to join the same coach

## Upgrade to Pro walkthrough (new)

This is the "free Partner becomes their own independent Owner" flow —
confirmed working end to end by reading the actual code, but worth
testing for real too.

1. As **Partner**, invite a client via **Network → Clients → invite
   button** — generate the link and note it (or just trust the seeded
   data already has some clients tied to you)
2. Go to **Settings → Launch Your Own Practice** → confirm the upgrade
3. Your shell should switch to the **full Owner view immediately** — no
   sign-out/sign-in needed
4. Check your new business's **Network → Clients** — any clients you
   personally invited as a Partner should now appear here, under your
   new independent business
5. Note: your **original within-business agreement** (the commission
   deal with the Owner who first invited you) stays exactly where it
   was, under their business — upgrading doesn't erase or move that
   historical relationship, which is intentional, not a bug
6. Minor thing to be aware of, not a bug: because this is mock data, a
   brand-new business with zero real staff/partners yet may show some
   seeded placeholder names in Network — that's a mock-data-only
   convenience, not something that'll happen with a real backend

## Known gaps — don't report these, I already know

- Anything requiring a **real backend connection** — the app is Phase 9 of
  10, everything runs on mock data until the Supabase swap
- **Image upload** — intentionally a disabled placeholder for now
- **GPS Tracking** — no job type has it enabled yet (see note above)
- **Real Stripe/PayPal payments** — the purchase flow is fully real
  (creates real transactions, real commission), but runs on the "manual"
  payment provider since actual card processing needs a real backend
  (Phase 10+)
- The purchase records the sale under the *partner's* business and the
  commission under *your coach's* — this only works because mock mode
  shares one data store; it's flagged in code for when real per-business
  data privacy rules go in later

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
