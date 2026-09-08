# Personal Wellness Trainer — Master Testing Checklist

You're testing in **mock mode** — no Supabase needed, nothing here touches
a real database. Everything resets when you restart the app (except a
signed-up account's *own* profile, which persists locally via
SharedPreferences until you clear app data — see the mock-mode notes
throughout for what does/doesn't survive a restart).

## Two ways to sign in — use the right one for what you're testing

**Real Sign Up (what a real customer does)** — from the login screen, tap
**"Create Account"**. This is the path you want for testing onboarding,
first impressions, and the 3-owner scenario below. Each real signup gets
its own genuinely separate business (own `businessId`, own empty team
roster you build up yourself through invites) — this was a real bug
before this session's fixes; see `AUDIT_FINDINGS.md` §1.1 if curious.

⚠️ Heads up (see `AUDIT_FINDINGS.md` §2.1): "Create Account" currently
also lets you sign up directly as **Partner** or **Client** with no invite
at all — that path is not part of the intended flow (every Partner/Client
is supposed to arrive via an invite link) and is flagged as a decision for
you, not fixed yet. For testing purposes, only use "Create Account" to
create **Owners**.

**Dev Quick Sign-In (fast, for spot-checking)** — the small orange
floating button on the login screen. Tap a job-type chip to sign in
instantly as that job's Owner, or a role chip (Partner/Staff/Client) to
sign in as that role on the one shared seed business. Skips onboarding
entirely — use this when you just want to poke at a specific screen, not
when testing the signup/onboarding experience itself.

Both paths now correctly get a real, working team roster (this was
part of what got fixed this session).

---

## The 3-owner test plan you asked for

This exercises the full real-world path: signup → onboarding → invites →
partnerships (both kinds) → deals → clients. Recommend running it exactly
like this at least once, then improvising further tests from the per-role
checklists below.

### Setup: create 3 separate Owner accounts

1. **Create Account** → sign up as Owner #1 (e.g. "Sunrise Yoga") → go
   through onboarding (pick a job type/category, business name, color,
   bio) → confirm you land on a real Owner dashboard.
2. Sign out. **Create Account** again with a different email → Owner #2
   (e.g. "Riverside Pilates").
3. Sign out. **Create Account** again → Owner #3 (e.g. "Tom's Meditation
   Coaching" — pick something where you plan to test the *direct-invite*
   Partner path specifically, see below).
4. For each: confirm **Network** tabs (Partners/Staff/Clients) all show
   **empty**, not pre-populated with fake names. This is the specific bug
   that was fixed — if you see a "Jordan Partner" or existing clients on a
   business you just created, that's a regression, tell me.

### Direct-invite Partner path (Owner #3)

5. As Owner #3: **Network → Partners tab → invite a Partner** → generate
   the link (in mock mode, you won't actually click a real link — just
   confirm the link/token is generated; see "what won't be effective in
   mock mode" below).
6. Since clicking a real invite link isn't practical solo in mock mode,
   use **Dev Quick Sign-In → Partner** to stand in for "the invited
   partner accepted." Confirm: their **Network** screen shows Owner #3 as
   a small **card at the top** (not a tab) — the "No owner yet." bug is
   what this replaced.
7. As that Partner: **invite a client** → confirm the client ends up
   scoped to the **Partner**, not to Owner #3 — i.e. on the Partner's own
   Clients list, the new client shows up; on Owner #3's own Clients tab,
   it should **not** appear (different ownership, by design — see earlier
   conversation for why).
8. Back as Owner #3: **Network → Partners tab** → confirm you now see a
   **"Propose a deal"** banner (only appears once you have ≥1 partner) →
   tap it → fill in a commission split → confirm it saves.
9. As the Partner: check that the same deal shows up as pending/awaiting
   their response, and that they can **accept or decline** it — but if you
   look for any way for the *Partner* to originate a brand-new deal
   proposal themselves, there shouldn't be one (Owner-only, by design).

### Marketplace / discoverable Partner path (Owner #1 ↔ Owner #2)

10. As Owner #1: **Network → Partners tab → "Discover new partners"**
    banner → browse → send a partnership request to Owner #2's business
    (or use an already-seeded pending request if one shows up).
11. Sign in as Owner #2 (their real account, not dev quick sign-in — you
    want to confirm a *genuinely separate real business* can receive and
    respond) → find the pending request → accept it → set a commission
    split in the dialog.
12. Both sides: confirm **Network → Partners** now shows the partnership
    as active.
13. As Owner #1 (or #2): confirm **Propose a deal** works between two
    already-independent Owners the same way it did for the direct-invite
    case in step 8 — same mechanism, different partnership origin.

### Business Features toggles

14. As any Owner: **Settings → Business Features** → flip **Partners**
    off → confirm the Partners tab now shows a clear "Partnerships are
    turned off" message (not an empty list), the "invite a partner"
    button disappears, and the Marketplace/Deals switches on this same
    settings screen grey out.
15. Flip **Partners** back on → confirm Marketplace/Deals switches return
    to whatever they were set to before (not reset to a default).
16. With Partners **on** but **Marketplace off**: confirm the "Discover
    new partners" banner is gone but the Propose-a-deal banner (if you
    already have a partner) still works — these are independent switches.
17. With Partners **on** but **Agreements off**: confirm the reverse —
    Discover banner still there, Propose-a-deal banner gone.

### Clients

18. Pick any Owner from above, invite a Client directly (not through a
    Partner) → confirm that client shows up on **that Owner's own**
    Clients tab.
19. As that Client: confirm their own view (contacts/Partners tab,
    payments, community feed, challenges, homework, rewards, profile) —
    see the Client checklist below for the full list.
20. As that Client, invite *another* client → sign in as the new client
    (Dev Quick Sign-In stand-in, or a real signup if you want to test the
    full chain) → confirm the new client's owner resolves to the
    **same Owner** as the inviting client — not to the inviting client
    themselves. This is the Jim/Tom/Sarah referral-chain behavior from
    earlier in our conversation; it's the trickiest bit of the ownership
    logic to get right, worth double-checking specifically.

---

## What won't be effective to test in mock mode — don't file these as bugs

- **Actually clicking a real invite link on a second device/browser.**
  Mock mode has no real backend to route a link to a specific pending
  signup — you generate a link/token, but there's no live "click to
  accept" you can test end-to-end solo. Use Dev Quick Sign-In as a stand-in
  for "someone accepted," as the plan above does.
- **Two Owner accounts interacting in true real-time** (e.g. Owner #2
  receiving a live push notification the instant Owner #1 sends a
  partnership request). Everything's local/in-memory — you'll switch
  between accounts by signing out and back in, not by having two sessions
  open live side by side (except via the QA Console, which does show all
  4 *roles* at once, but that's one shared seed business, not your 3
  independently-created ones).
- **Real payment processing.** Purchases/commissions are fully real in
  terms of the app's own math and records, but run on a "manual" payment
  provider stand-in — no actual card processing (that needs the real
  backend, planned for later).
- **Data surviving an app reinstall/clear.** A real signup's profile
  persists across restarts via local storage, but there's no real
  database backing it — clearing app storage or reinstalling wipes
  everything, including any of the 3 owner accounts you built up.
- **Image upload** — intentionally a disabled placeholder for now.
- **GPS Tracking** — no job type currently has this module turned on.

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
- [ ] **Dashboard client count** reflects only clients this Owner directly
      owns, not clients that actually belong to one of their Partners
- [ ] **Content** (Activity) — list loads, create new one, open detail, edit,
      delete
- [ ] **Content → Tools cards** — Scheduling, Reservations, Catalog,
      Inventory, Media, Delivery Fees, and Reviews each open correctly and
      only show up when the active job type actually uses that module
- [ ] **Revenue** (Finance) — transactions list loads, commission view (if
      applicable) loads, numbers look sane
- [ ] **Network → Partners tab** — list loads, scoped correctly (see the
      3-owner plan above for the full walkthrough); "Discover new
      partners" and "Propose a deal" banners only appear when their
      respective Business Features switches are on
- [ ] **Network → Staff tab** — list loads, invite works
- [ ] **Network → Clients tab** — list loads, invite works, **only shows
      clients this Owner directly owns** (not a Partner's clients — this
      was a fixed bug, worth double-checking)
- [ ] **Settings → Business Features** — all 3 switches work as described
      in the toggle test plan above
- [ ] **Chat icon (top bar, next to the bell)** — opens the full
      conversations list; per-row chat icons on member tiles still work too
- [ ] **Notifications** — bell icon list loads, marking as read works
- [ ] **Settings** — Own Business screen, Branding screen (color change
      propagates app-wide); Owner should **not** see any "Launch Your Own
      Practice" upgrade banner or a locked Branding tile — that's
      Partner-only

## Partner checklist

- [ ] **Dashboard** loads, shows the upgrade banner at the top of every tab
- [ ] Upgrade banner's button actually navigates somewhere sensible
- [ ] **Activity** — can view but *cannot* create (should be view-only, or
      whatever the intended permission is — flag if it feels wrong)
- [ ] **Finance** — partner-scoped view loads (should only show *their*
      numbers, not the owner's full business)
- [ ] **Network** — Owner shown as a **card at top** (not a tab); single
      **Clients** list below it, scoped to **only clients this Partner
      personally invited** (not a shared pool with the Owner — this
      changed from earlier behavior, see our conversation history);
      invite button (bottom-right) adds a new client to this Partner's
      own list
- [ ] Partner can **respond** to (accept/decline) a deal proposed by their
      Owner, but has **no way to originate** a new deal proposal
      themselves
- [ ] **Upgrade to Pro** (Settings → Launch Your Own Practice) — see the
      dedicated walkthrough below; confirm your shell switches to the
      full Owner view immediately, no re-login needed
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
- [ ] **Partners tab** — one tab covers both partner content and contacts.
      Confirm it loads without crashing even before any partnership
      exists (should show empty-state messages, not errors), shows your
      contacts (owner, partners, eligible staff) further down, and has a
      working invite button (bottom-right)
- [ ] Inviting another client via that button correctly assigns the new
      client to **your own owner**, not to you (see step 20 in the
      3-owner plan)
- [ ] **Payments** — client-facing payment history loads
- [ ] **Community Feed** — loads, can post/interact if that's supported
- [ ] **Challenges** — list loads, can join one
- [ ] **Homework** — list loads (if this job type uses it) — note: the
      client picker on this screen is not yet ownership-scoped (shows all
      clients business-wide); flagged, not yet fixed
- [ ] **Rewards/Loyalty** — points/rewards screen loads
- [ ] **Profile** — client can view/edit their own profile
- [ ] Client should **not** be able to reach Settings, Finance-admin, Team
      management, or other owner/staff-only areas — try the QA Console
      side-by-side to sanity check this quickly

---

## Upgrade to Pro walkthrough

This is the "free Partner becomes their own independent Owner" flow.

1. As **Partner**, invite a client via **Network → invite button** —
   confirm the client is scoped to you as described above.
2. Go to **Settings → Launch Your Own Practice** → confirm the upgrade.
3. Your shell should switch to the **full Owner view immediately** — no
   sign-out/sign-in needed.
4. Check your new business's **Network → Clients** — any clients you
   personally invited as a Partner should now appear here, under your new
   independent business.
5. Your **original within-business agreement** (the commission deal with
   the Owner who first invited you, if you had set one up) stays exactly
   where it was, under their business — upgrading doesn't erase or move
   that historical relationship, which is intentional, not a bug.
6. Your new business's **Business Features** switches should default to
   all-on, independent of whatever the original Owner had set for
   themselves — each business's toggles are its own.

---

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
