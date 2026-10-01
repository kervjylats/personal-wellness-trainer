# 🧪 Manual Test Checklist — Personal Wellness Trainer (Web)

**Round 6 — test like production.** The app now has **no dev shortcuts**:
no Quick Sign-In button, no QA console, no `owner@test.com`-style logins.
Everything is tested the way a real user would do it: **sign up fresh**.

**Platform:** `http://localhost:8080` (your own server window; refresh the
page after every rebuild).

---

## 📌 How to use

1. Work top to bottom (or jump around — whatever).
2. Mark each item: `✅` = good, `❌` = broken/weird, `🤷` = not sure.
3. Add a short note after the `—` on the same line (one line is enough).
4. When done: **reply to me "done"** — I'll read this file.

### Ground rules

- **Create every account yourself:** any email works, password **6+ chars**.
  Use different emails for the different journeys (A/B/C/D below).
- **Sign out with the app's own Sign Out button** when switching accounts.
- **Demo backend reality:** your *login* survives a browser refresh, but
  *business data does not* (it resets on refresh). Avoid refreshing
  mid-flow; if something empties after a refresh, note it, don't panic.
- This is the **only** checklist file (the 3 older ones were deleted).

---

## 🛫 Journey A — First run (you are a brand-new visitor)

- [ ] **A1** Fresh open → marketing/landing page (not a blank screen, not
      straight to login) — *notes:*
- [ ] **A2** Landing reads like a real product page (headline, sections;
      no "test"/"demo" gibberish) — *notes:*
- [ ] **A3** "Get Started" → sign-up form (name, email, password, optional
      Code field) — *notes:*
- [ ] **A4** Submit with empty fields / short password → helpful validation,
      no crash — *notes:*
- [ ] **A5** Sign up (NO code) → onboarding asks what you do — *notes:*
- [ ] **A6** Pick **Yoga Studio**, set business name, finish onboarding →
      dashboard loads — *notes:*
- [ ] **A7** Dashboard feels **yours**: yoga-ish branding/content, stats
      make sense, **no fake money** (a new business should show $0/empty —
      old build showed seeded $182) — *notes:*
- [ ] **A8** All 5 tabs work: Content / Revenue / Network / Settings / Home —
      *notes:*
- [ ] **A9** Content list renders — no "null"/"undefined" anywhere — *notes:*
- [ ] **A10** Notification bell opens a notifications view (empty state OK) —
      *notes:*
- [ ] **A11** Revenue tab loads with **$0 / empty state** (correct for a
      brand-new business) — *notes:*
- [ ] **A12** Network tabs (Associates / Staff / Clients) start **empty** —
      no pre-seeded strangers — *notes:*
- [ ] **A13** Sign out → returns to login — *notes:*

---

## 🔐 Journey B — Signing back in + auth edge cases

- [ ] **B1** Sign in with your Journey-A account → dashboard returns —
      *notes:*
- [ ] **B2** Wrong password → clear error message (no crash/blank) —
      *notes:*
- [ ] **B3** An email you never signed up with → "Invalid email or
      password"-style message — *notes:*
- [ ] **B4** Double signup with the same email → sensible error — *notes:*
- [ ] **B5** "Forgot password?" → shows a message/stub (it's demo mode —
      no real email is sent; note if the wording misleads you) — *notes:*
- [ ] **B6** 🔒 **Dev logins are dead:** sign in as `owner@test.com` (any
      password) → must **fail**. Same for `partner@` / `staff@` /
      `client@test.com` — *notes:*
- [ ] **B7** 🔒 **No shortcuts anywhere:** login screen has **no** floating
      Quick Sign-In button, no job chips, no hidden QA panel — *notes:*

---

## 🤝 Journey C — Invite a 2nd account & send a real deal
*(The robot could only log into ONE account — you are the test.)*

**Setup:**
1. Sign in as your Journey-A owner → **Network** → Associates → invite
   button → generate the **code/link**.
2. Sign out → sign up a **NEW email** using that code (sign-up form's
   Code field, or login screen's "Have an invite code? Join here").

- [ ] **C1** Owner invite flow (generate code/link) is smooth — *notes:*
- [ ] **C2** The new account **joins your business as an Associate** (not
      standalone) — *notes:*
- [ ] **C3** Associate side: Network shows the **Owner card** (not
      "No owner yet") — *notes:*
- [ ] **C4** That Associate can **invite a client** — *notes:*
- [ ] **C5** Owner: Network → "Propose a deal" banner → pick the associate →
      **Send** — *notes:*
- [ ] **C6** 🚧 **Robot BLOCKED (Step 9):** sign out → sign in as the
      Associate → the proposed deal **appears** → **Accept / Decline** both
      work. What does the accept screen look like? — *notes:*

---

## 🗝️ Journey D — Activation key + 2nd independent business
*(Also robot-BLOCKED — the hardest flows.)*

- [ ] **D1** Sign up a **third email** on the landing page with
      **Code = `SOPHIA-SOUND-999`** → becomes a **PRO owner** — *notes:*
- [ ] **D2** Compare vs the free account: what looks different (e.g., no
      "upgrade" prompts)? If nothing visible, say so — *notes:*
- [ ] **D3** 🚧 **Robot BLOCKED (Step 13) — two independent owners link
      through the Marketplace:**
  1. Account 3: open a category slot (e.g. Pilates), turn
     **Discoverable** ON.
  2. Your Journey-A owner: **Marketplace → Discover Associates** → Account 3's
     tile shows up → tap it → **Send Associate Request**.
  3. Account 3: **Received Requests → Accept** → "Set your commission
     split" dialog → **Confirm Collab** → pending list clears.
  - What does each side see after linking? — *notes:*
- [ ] **D4** Marketplace with nobody discoverable → sensible empty state —
      *notes:*
- [ ] **D5** Turn **Discoverable** ON → subtitle confirms others can find
      you — *notes:*

---

## ✅ Journey E — Robot PASSED these. Eyeball them.

> Robot only checks "text appears". You check it **looks and feels right**.

- [ ] **E1** Bottom nav switches all 5 tabs — *notes:*
- [ ] **E2** Settings → **Business Features toggles**:
      Collabs OFF → Associates tab explains "turned off" (not broken) →
      back ON restores; Marketplace OFF → discover banner disappears →
      ON returns; Agreements OFF → propose flow gone → ON returns —
      *notes:*
- [ ] **E3** Settings loads; **Chat icon** opens conversations — *notes:*
- [ ] **E4** Content → Tools cards accessible — *notes:*
- [ ] **E5** Owner screens all load: Dashboard / Content / Finance /
      Network / Settings — *notes:*
- [ ] **E6** Associate screens (your C-account): dashboard has an
      upgrade/launch banner, Finance is **associate-scoped**, owner shown as
      a card — *notes:*
- [ ] **E7** *(optional, only if you invited one)* Staff/Client accounts:
      their dashboards load — *notes:*

---

## 🎨 Journey F — Robot is BLIND here (words, looks, feel)

**Errors & validation**
- [ ] **F1** Empty/short-password signup → helpful validation — *notes:*
- [ ] **F2** Dialogs (commission split, invite, confirm) readable, centered —
      *notes:*
- [ ] **F3** Toasts/feedback after actions (invite sent, deal sent) —
      *notes:*

**Look & feel**
- [ ] **F4** Fonts/colors/spacing consistent across screens — *notes:*
- [ ] **F5** Buttons/switches look tappable; nothing clipped/overflowing —
      *notes:*
- [ ] **F6** No text cut off (long names/business names) — *notes:*
- [ ] **F7** Empty states read nicely (no "null", no raw JSON) — *notes:*

**Navigation & robustness**
- [ ] **F8** Back buttons/arrows always work, never trap you — *notes:*
- [ ] **F9** Tab key moves through the login form; Enter submits — *notes:*
- [ ] **F10** Browser refresh mid-session: does the app recover gracefully
      or show a broken state? (Demo data resets — judge the *recovery*) —
      *notes:*
- [ ] **F11** Window resize (half-screen): nothing breaks/overlaps —
      *notes:*
- [ ] **F12** Payments/anything suggesting REAL money → flag it (payments
      are fake on purpose) — *notes:*

---

## 💬 Your verdict

- **Overall vibe (would you actually use this?):** ___
- **Most confusing moment:** ___
- **Top 3 things you'd change:** 1. ___ 2. ___ 3. ___
- **Blocking bugs (breaks a flow):** ___
- **Anything else:** ___

---

### Reply template (when you're done)

```
Done — MANUAL_TEST_CHECKLIST.md
❌ items: [A7, C6, ...]
Notes I care about: ...
```
