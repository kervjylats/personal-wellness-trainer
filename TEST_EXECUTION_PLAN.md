# Personal Wellness Trainer — Test Execution Plan

Based on TESTING_CHECKLIST.md and codebase analysis.

---

## Test Environment Setup

**Prerequisites:**
- Flutter SDK installed
- Device/emulator running (Android, iOS, Web, or Desktop)
- DataConfig.useMockData = true (default in lib/engine/config/data_config.dart)
- Clear app data between test runs (SharedPreferences holds mock sessions)

**How to Clear Mock State:**
- Android: Settings > Apps > Personal Wellness Trainer > Storage > Clear Storage
- Web: DevTools > Application > Local Storage > Clear
- Desktop: Delete %APPDATA%\personal_wellness_trainer or equivalent

---

## Phase 1: Cross-Cutting Checks (Apply to Every Role)

### 1.1 App Launch & Basic Navigation
- [ ] App launches without crashing, straight to the login screen
- [ ] Dev Quick Sign-In button appears (orange floating button — confirms mock mode active)
- [ ] Switching job type changes: color scheme, wording, which nav tabs/modules are visible
- [ ] Bottom nav / tabs all switch screens correctly, no blank/frozen tabs
- [ ] Pull-to-refresh works on list screens (dashboard, activity, etc.)
- [ ] Empty states show sensible text (not null or blank) on any list with no data yet
- [ ] Notification bell icon opens notifications, badge count looks right
- [ ] Signing out returns you cleanly to the login screen
- [ ] Rotating/resizing the window (web/desktop) doesn't break layout

---

## Phase 2: The 3-Owner Test Plan (Core Integration Test)

### 2.1 Setup: Create 3 Separate Owner Accounts

**Owner #1: Sunrise Yoga (Yoga Studio job type)**
1. From login screen > Create Account
2. Sign up as Owner with unique email (e.g., owner1@test.com)
3. Complete onboarding: pick Yoga Studio job type, business name Sunrise Yoga, color, bio
4. Confirm landing on real Owner dashboard
5. Verify Network tabs (Partners/Staff/Clients) all show EMPTY — no Jordan Partner or pre-seeded clients
6. Sign out

**Owner #2: Riverside Pilates (Pilates Studio job type)**
1. Create Account with different email (owner2@test.com)
2. Complete onboarding: pick Pilates Studio job type, business name Riverside Pilates
3. Verify empty Network tabs
4. Sign out

**Owner #3: Tom's Meditation Coaching (Meditation Teacher job type)**
1. Create Account with different email (owner3@test.com)
3. Complete onboarding: pick Meditation Teacher job type, business name Tom's Meditation Coaching
4. Verify empty Network tabs
5. This owner will test the direct-invite Partner path specifically

---

### 2.2 Direct-Invite Partner Path (Owner #3)

**Step 5: Owner #3 Invites a Partner**
1. Sign in as Owner #3
2. Network > Partners tab > Invite a Partner > generate link
3. Confirm link/token is generated (mock mode: no real link click, just verify token appears)
4. Use Dev Quick Sign-In > Partner to stand in for invited partner accepted
5. Verify: Partner's Network screen shows Owner #3 as a small card at top (not a tab) — NOT No owner yet.

**Step 7: Partner Invites a Client**
1. As Partner: invite a client (Network > FAB > Invite Client)
2. Use Dev Quick Sign-In > Client as stand-in for client accepted
3. Verify client ownership:
   - On Partner's Clients list: new client shows up
   - On Owner #3's Clients tab: client should NOT appear (different ownership by design)

**Step 8: Owner #3 Proposes a Deal**
1. Back as Owner #3: Network > Partners tab > confirm Propose a deal banner appears (>=1 partner)
2. Tap banner > fill commission split > confirm it saves

**Step 9: Partner Responds to Deal**
1. As Partner: check same deal shows as pending/awaiting response
2. Verify Partner can accept or decline
3. Verify: Partner has NO way to originate a new deal proposal (Owner-only by design)

---

### 2.3 Marketplace / Discoverable Partner Path (Owner #1 <-> Owner #2)

**Step 10: Owner #1 Sends Partnership Request**
1. Sign in as Owner #1 (real account, not Dev Quick Sign-In)
2. Network > Partners tab > Discover new partners banner
3. Browse > send partnership request to Owner #2's business

**Step 11: Owner #2 Accepts**
1. Sign in as Owner #2 (real account)
2. Find pending request > accept > set commission split in dialog

**Step 12: Both Sides Verify Active Partnership**
1. Both: Network > Partners shows partnership as active

**Step 13: Propose Deal Between Independent Owners**
1. As Owner #1 (or #2): Propose a deal works same as direct-invite case
2. Same mechanism, different partnership origin

---

### 2.4 Business Features Toggles

**Step 14: Turn Partners OFF**
1. As any Owner: Settings > Business Features > flip Partners off
2. Verify: Partners tab shows Partnerships are turned off message (not empty list)
3. Verify: Invite a partner button disappears
4. Verify: Marketplace/Deals switches grey out

**Step 15: Turn Partners ON**
1. Flip Partners back on
2. Verify: Marketplace/Deals switches return to previous state (not reset to default)

**Step 16: Partners ON, Marketplace OFF**
1. Partners on, Marketplace off
2. Verify: Discover new partners banner gone
3. Verify: Propose a deal banner still works (if partner exists) — independent switches

**Step 17: Partners ON, Agreements OFF**
1. Partners on, Agreements off
2. Verify: Discover banner still there
3. Verify: Propose a deal banner gone

---

### 2.5 Clients

**Step 18: Owner Direct-Invites Client**
1. Pick any Owner > invite Client directly (not through Partner)
2. Verify: Client shows up on that Owner's own Clients tab

**Step 19: Client View Verification**
1. As that Client: verify their view loads: Contacts/Partners tab, Payments, Community feed, Challenges, Homework, Rewards, Profile

**Step 20: Client-Invites-Client Chain (Jim/Tom/Sarah Referral)**
1. As Client from step 18: invite another client
2. Sign in as new client (Dev Quick Sign-In or real signup)
3. Critical: New client's owner resolves to the SAME Owner as inviting client — NOT to the inviting client themselves
4. This tests _resolveClientOwnerId logic in mock_team_source.dart:166-175

---

## Phase 3: Per-Role Detailed Checklists

### 3.1 Owner Checklist
- [ ] Dashboard loads with sensible summary cards/stats
- [ ] Dashboard client count reflects only directly-owned clients (not Partner's clients)
- [ ] Content (Activity) — list loads, create new, open detail, edit, delete
- [ ] Content > Tools cards — Scheduling, Reservations, Catalog, Inventory, Media, Delivery Fees, Reviews each open correctly and only show when job type uses that module
- [ ] Revenue (Finance) — transactions list loads, commission view loads, numbers look sane
- [ ] Network > Partners tab — list loads, scoped correctly; Discover and Propose deal banners only appear when Business Features switches are on
- [ ] Network > Staff tab — list loads, invite works
- [ ] Network > Clients tab — list loads, invite works, only shows directly-owned clients (not Partner's clients)
- [ ] Settings > Business Features — all 3 switches work as per toggle test plan
- [ ] Chat icon (top bar) — opens conversations list; per-row chat icons on member tiles work
- [ ] Notifications — bell icon list loads, marking as read works
- [ ] Settings — Own Business screen, Branding screen (color change propagates app-wide); Owner should NOT see Launch Your Own Practice upgrade banner or locked Branding tile (Partner-only)

---

### 3.2 Partner Checklist
- [ ] Dashboard loads, shows upgrade banner at top of every tab
- [ ] Upgrade banner's button navigates somewhere sensible
- [ ] Activity — can view but cannot create (view-only or per-permission)
- [ ] Finance — partner-scoped view loads (only their numbers, not Owner's full business)
- [ ] Network — Owner shown as card at top (not tab); single Clients list below, scoped to only clients this Partner personally invited (not shared pool); FAB invite adds client to Partner's own list
- [ ] Partner can respond (accept/decline) to deal proposed by Owner, but has NO way to originate new deal proposal
- [ ] Upgrade to Pro (Settings > Launch Your Own Practice) — confirm shell switches to full Owner view immediately, no re-login
- [ ] AppBar title shows Partner's own business name, not just Partner

---

### 3.3 Staff Checklist
- [ ] Dashboard loads
- [ ] Activity — can view, and create if enabled for this job type
- [ ] Access appropriately limited vs Owner (no Settings/Finance-admin/Team management)
- [ ] Flag anything Staff can see that feels excessive

---

### 3.4 Client Checklist
- [ ] Dashboard loads
- [ ] Activity Hub — browse available classes/sessions
- [ ] Partners tab — one tab covers both partner content and contacts: loads without crashing before any partnership exists (empty-state messages, not errors), shows contacts (owner, partners, eligible staff) further down, working invite button (bottom-right)
- [ ] Inviting another client via that button correctly assigns new client to your own owner, not to you (step 20 referral-chain behavior)
- [ ] Payments — client-facing payment history loads
- [ ] Community Feed — loads, can post/interact if supported
- [ ] Challenges — list loads, can join one
- [ ] Homework — list loads (if job type uses it); Note: client picker not yet ownership-scoped (shows all business-wide clients) — flagged, not yet fixed
- [ ] Rewards/Loyalty — points/rewards screen loads
- [ ] Profile — client can view/edit own profile
- [ ] Client cannot reach Settings, Finance-admin, Team management, or other owner/staff-only areas (sanity check via QA Console side-by-side)

---

## Phase 4: Upgrade to Pro Walkthrough

1. As Partner, invite a client via Network > invite button > confirm client scoped to Partner
2. Go to Settings > Launch Your Own Practice > confirm upgrade
3. Shell switches to full Owner view immediately — no sign-out/sign-in needed
4. Check new business's Network > Clients — clients invited as Partner now appear under new independent business
5. Original within-business agreement (commission deal with Owner who invited Partner) stays under original business — upgrading doesn't erase/move historical relationship (intentional)
6. New business's Business Features switches default to all-on, independent of original Owner's settings

---

## Phase 5: What Won't Be Effective in Mock Mode (Don't File as Bugs)

- Actually clicking real invite link on second device/browser — no real backend to route link
- Two Owner accounts interacting in true real-time — local/in-memory only, switch by sign out/in
- Real payment processing — manual payment provider stand-in, no actual card processing
- Data surviving app reinstall/clear — local storage only, no real database
- Image upload — intentionally disabled placeholder
- GPS Tracking — no job type currently has this module turned on

---

## Test Execution Order (Recommended)

| Order | Phase | Description | Estimated Time |
|-------|-------|-------------|----------------|
| 1 | Phase 1 | Cross-cutting checks (all roles) | 30 min |
| 2 | Phase 2.1 | Create 3 Owner accounts | 20 min |
| 3 | Phase 2.2 | Direct-invite Partner path (Owner #3) | 20 min |
| 4 | Phase 2.3 | Marketplace path (Owner #1 <-> Owner #2) | 15 min |
| 5 | Phase 2.4 | Business Features toggles | 15 min |
| 6 | Phase 2.5 | Client flows & referral chain | 15 min |
| 7 | Phase 3.1 | Owner detailed checklist | 20 min |
| 8 | Phase 3.2 | Partner detailed checklist | 15 min |
| 9 | Phase 3.3 | Staff detailed checklist | 10 min |
| 10 | Phase 3.4 | Client detailed checklist | 15 min |
| 11 | Phase 4 | Upgrade to Pro walkthrough | 10 min |

Total: ~3 hours

---

## Reporting Format

For each issue found, paste:

Role: [Owner/Partner/Staff/Client]
Job type: [e.g. Yoga Studio]
Screen: [e.g. Reservations list]
What happened: [what you saw]
What you expected: [what you think should've happened]

For suggestions/ideas: plain language — what if X worked like Y instead

---

## Key Code Locations for Debugging

| Feature | File |
|---------|------|
| Auth & onboarding | lib/engine/auth/auth_notifier.dart |
| Mock team roster | lib/data/sources/mock/mock_team_source.dart |
| Client ownership resolution | lib/data/sources/mock/mock_team_source.dart:166-175 (_resolveClientOwnerId) |
| Business features toggles | lib/modules/team/providers/business_features_provider.dart |
| Owner Network screen | lib/modules/team/screens/network_screen.dart |
| Partner Network screen | lib/modules/team/screens/partner_network_screen.dart |
| Client Network screen | lib/modules/team/screens/client_network_screen.dart |
| Invite flow | lib/modules/team/widgets/invite_dialog.dart |
| Invite link generation | lib/engine/invites/invite_link_notifier.dart |
| Marketplace | lib/modules/agreements/screens/marketplace_screen.dart |
| Accept invitation | lib/engine/auth/accept_invitation_screen.dart |
| Role shells | lib/engine/shell/*_shell.dart |
| Permissions | lib/engine/permissions/permissions_engine.dart |
| Job type config | assets/config/job_types.json |

---

## Known Issues to Watch For (Pre-existing, Not Yet Fixed)

1. Client picker on Homework screen — not ownership-scoped (shows all clients business-wide)
2. Sign up as Partner/Client directly — Create Account allows this but it's not intended flow (flagged in AUDIT_FINDINGS.md §2.1)
3. Mock mode limitations — see Phase 5 above

---

## Automated Test Suite

Run integration tests:
flutter test integration_test/app_test.dart

Test blocks:
- Block 01: Auth & Onboarding
- Block 02: Owner Shell
- Block 03: Activity & Scheduling
- Block 04: Team Management
- Block 05: Finance
- Block 06: Marketplace & Agreements
- Block 07: Features
- Block 08: Partner Shell
- Block 09: Client Shell
- Block 10: Staff Shell
- Block 11: Messaging
- Block 12: Navigation & Edge Cases

---

## QA Console for Side-by-Side Testing

Access QA Console from Dev Quick Sign-In or directly to see all 4 roles simultaneously:
- Each panel has isolated auth state (fresh sign-in)
- All panels share same mock data store
- Useful for verifying role-based visibility differences
