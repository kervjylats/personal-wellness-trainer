// integration_test/helpers/robot.dart
// Robot pattern — all UI interactions go through here.
// Tests stay readable: robot.tapButton('Sign In') instead of raw finder chains.
// Never throws — all methods return bool (found/done) or null-safe.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

class AppRobot {
  AppRobot(this.tester);
  final WidgetTester tester;

  // ── Wait helpers ───────────────────────────────────────────────────────────

  Future<void> settle([Duration d = const Duration(seconds: 3)]) async {
    await tester.pumpAndSettle(d);
  }

  Future<void> wait([Duration d = const Duration(milliseconds: 600)]) async {
    await tester.pump(d);
    await tester.pumpAndSettle();
  }

  // ── Finders ────────────────────────────────────────────────────────────────

  // Substring match, not exact. Screens often render richer text than the
  // Substring match. Real screens render richer text than tests search for
  // — e.g. an AppBar reads 'New Session' when a test checks for 'Session',
  // or a finance card reads 'Active Partnerships' when a test checks for
  // 'Deals'. find.text() requires an exact match and misses these.
  Finder byText(String text)   => find.textContaining(text);
  Finder byKey(String key)     => find.byKey(Key(key));
  Finder byType<T extends Widget>() => find.byType(T);
  Finder byIcon(IconData icon) => find.byIcon(icon);

  bool exists(Finder f)        => f.evaluate().isNotEmpty;

  // Plain tree-presence check (NOT hitTestable). Material's
  // InputDecoration label/hint text is deliberately wrapped in
  // IgnorePointer — fully visible to a human, but never hit-testable —
  // so filtering on hitTestable() here would hide real, visible form
  // field labels (e.g. 'Class Name', 'Description' on the create-
  // activity form). The one false-positive case this used to guard
  // against (an inactive IndexedStack sibling tab containing matching
  // text, e.g. the old partner 'Partners' nav-label bug) is now fixed
  // at its actual source in partner_shell.dart instead.
  bool existsText(String text) => exists(byText(text));
  bool existsKey(String key)   => exists(byKey(key));

  // ── Tap ────────────────────────────────────────────────────────────────────

  Future<bool> tap(Finder f) async {
    try {
      final count = f.evaluate().length;
      if (count == 0) return false;

      // tester.tap() requires exactly one match. With an IndexedStack
      // (all tabs built simultaneously), the same text/icon can appear
      // more than once — e.g. a NavigationBar tab label AND a screen
      // title inside an offstage page. Rather than throw "too many
      // elements" and silently fail, prefer the hit-testable (visible)
      // match; if multiple are still hit-testable, tap the first one.
      Finder target = f;
      if (count > 1) {
        final visible = f.hitTestable();
        target = visible.evaluate().isNotEmpty ? visible.first : f.first;
      }

      // The target may exist in the tree but be scrolled out of view
      // (e.g. the dev-launch sheet has 23 job chips before the 3 role
      // chips, pushing the role chips below the fold inside a
      // SingleChildScrollView at initialChildSize: 0.65). tester.tap()
      // on an off-screen widget with warnIfMissed:false silently no-ops
      // — no exception, but onPressed never fires. Scroll it into view
      // first with ensureVisible.
      if (target.evaluate().isNotEmpty &&
          target.hitTestable().evaluate().isEmpty) {
        try {
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
        } catch (_) {}
      }

      await tester.tap(target, warnIfMissed: false);
      await tester.pumpAndSettle();
      return true;
    } catch (_) { return false; }
  }

  /// Taps text on the current screen.
  /// If the text is not immediately found, navigates to the Sessions/Activities
  /// tab (where most feature labels live) and tries again, then Settings.
  /// This handles texts like 'Schedule', 'Challenges', 'Reviews', 'Profile' etc.
  /// that live inside tabs other than the default Dashboard.
  Future<bool> tapText(String text) async {
    // Direct attempt first (covers anything already on-screen).
    if (await tap(find.textContaining(text))) return true;

    // Scroll-then-retry runs UNCONDITIONALLY (no actionWords check, no
    // "already in tree" precondition). This matters specifically for
    // plain ListView(children: [...]) forms (e.g. create_activity_screen,
    // which has 8+ fields then a Save button): ListView is Sliver-backed
    // and lazily builds only what's within the viewport + cache extent,
    // so a Save button after a long field list may genuinely not be IN
    // THE TREE yet — find.textContaining('Save').evaluate() would be
    // empty, not just non-hit-testable. scrollToText's own loop already
    // re-checks inTree() as it scrolls, which is exactly what reveals
    // this kind of virtualized content. This is a pure scroll — it never
    // navigates between tabs/screens — so it's safe to run for action
    // words (Save/Create/etc.) too, unlike the fallbacks below.
    await scrollToText(text, maxScrolls: 10);
    if (await tap(find.textContaining(text))) return true;

    // Action-button words (form/dialog buttons) never warrant the
    // navigation fallbacks below — they only make sense within whatever
    // form or dialog is CURRENTLY open. Falling through to tab/key
    // navigation could tap stale coordinates belonging to a covered-but-
    // still-mounted previous route, which could accidentally dismiss the
    // very form/dialog the caller is trying to interact with.
    const actionWords = {
      'Save', 'Create', 'Add', 'Cancel', 'Submit', 'Confirm', 'Done',
      'Delete', 'Remove', 'Update', 'Send', 'OK', 'Yes', 'No',
    };
    if (actionWords.contains(text)) return false;

    // The activity/sessions tab is labeled differently per job type
    // ('Sessions', 'Classes', 'Appointments', 'Bookings', 'Activities'...).
    // owner_shell.dart tags that NavigationDestination with the stable
    // key 'nav_activity_tab' regardless of label. If the caller is
    // searching for one of these common aliases, try the stable key.
    const activityAliases = {
      'Activities', 'Sessions', 'Classes', 'Appointments', 'Bookings',
    };
    if (activityAliases.contains(text)) {
      if (await tapKey('nav_activity_tab')) return true;
    }

    // These are tab labels themselves — no cross-tab search for them.
    const tabLabels = {
      'Sessions', 'Activities', 'Finance', 'Revenue', 'Network',
      'Settings', 'Discover', 'Marketplace', 'Home', 'Dashboard',
      'Chats', 'Messages', 'Control', 'Panel',
      // NOTE: 'Catalog' and 'Shop' deliberately excluded — they're module
      // cards INSIDE ActivityHubScreen, not navigation tabs. Including them
      // here used to block tapText('Catalog') from ever reaching the
      // ActivityHub-scroll fallback below, which is the only place that
      // card actually lives.
    };
    if (tabLabels.contains(text)) return false;

    // Feature screens (Schedule, Catalog, Challenges, Homework, Rewards,
    // Reviews, Media, Inventory...) are module cards or engagement chips
    // inside ActivityHubScreen. Navigate there via stable key, then SCROLL
    // DOWN — engagement chips sit at the BOTTOM of the vertical scroll
    // and are not hit-testable until scrolled into view.
    if (await tapKey('nav_activity_tab')) {
      await scrollToText(text, maxScrolls: 12);
      if (await tap(find.textContaining(text))) return true;
    }

    // Last-resort: check remaining named tabs. IMPORTANT: if none of them
    // contain the text, restore the Home/Dashboard tab before giving up.
    // Test code often chains alternatives as separate calls, e.g.
    // `tapText('Rewards') || tapText('Loyalty') || tapText('Points')` —
    // each is a fresh, independent call. Without restoring, a failed
    // attempt here would leave the app sitting on e.g. the Settings tab,
    // and the NEXT call (searching for 'Loyalty') would search from
    // Settings instead of the Dashboard where the real content lives,
    // failing for an unrelated reason.
    for (final tab in ['Settings', 'Network', 'Discover']) {
      if (!exists(find.text(tab))) continue;
      await tester.tap(find.text(tab).first, warnIfMissed: false);
      await tester.pumpAndSettle();
      if (await tap(find.textContaining(text))) return true;
    }
    for (final home in ['Home', 'Dashboard']) {
      if (exists(find.text(home))) {
        await tester.tap(find.text(home).first, warnIfMissed: false);
        await tester.pumpAndSettle();
        break;
      }
    }
    return false;
  }
  Future<bool> tapKey(String key)   => tap(byKey(key));
  Future<bool> tapIcon(IconData icon) => tap(byIcon(icon));

  Future<bool> tapFirst(Finder f) async {
    try {
      // Prefer hit-testable (visible) widgets; fall back to any if none visible.
      final visible = f.hitTestable();
      final target  = visible.evaluate().isNotEmpty ? visible : f;
      if (!exists(target)) return false;
      await tester.tap(target.first, warnIfMissed: false);
      await tester.pumpAndSettle();
      return true;
    } catch (_) { return false; }
  }

  // ── Type ───────────────────────────────────────────────────────────────────

  Future<void> enterText(Finder f, String text) async {
    try {
      await tester.tap(f, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(f, text);
      await tester.pumpAndSettle();
    } catch (_) {}
  }

  Future<void> enterTextByKey(String key, String text) =>
      enterText(byKey(key), text);

  Future<void> enterTextByLabel(String label, String text) async {
    final f = find.widgetWithText(TextFormField, label).first;
    await enterText(f, text);
  }

  // ── Scroll ─────────────────────────────────────────────────────────────────

  Future<void> scrollDown([double pixels = 400]) async {
    // Use .hitTestable() to only scroll the VISIBLE scrollable,
    // not an offstage one from an IndexedStack inactive tab.
    final scrollable = find.byType(Scrollable).hitTestable();
    if (scrollable.evaluate().isEmpty) return;
    await tester.drag(scrollable.first, Offset(0, -pixels));
    await tester.pumpAndSettle();
  }

  Future<bool> scrollToText(String text,
      {int maxScrolls = 15, double step = 300}) async {
    // Stop as soon as the text EXISTS anywhere in the widget tree.
    //
    // Two things to know about Flutter scrollables:
    //  1. ListView builds lazily — text is NOT in the tree until scrolled
    //     into the viewport. So we must scroll until it appears.
    //  2. Once in the viewport, a plain Text widget (e.g. a section header
    //     like 'Commission') is NEVER hit-testable — it has no gesture
    //     handler. Using hitTestable() as the stop condition would cause
    //     us to scroll PAST the header, which ListView lazily unloads,
    //     and then existsText() finds nothing.
    //
    // Solution: stop as soon as the widget appears in the tree (i.e. it
    // entered the viewport). For interactive widgets (buttons, chips)
    // this is also correct — tap() calls ensureVisible() for anything
    // that isn't hit-testable.
    bool inTree() => find.textContaining(text).evaluate().isNotEmpty;
    for (int i = 0; i < maxScrolls; i++) {
      if (inTree()) return true;
      final scrollables = find.byType(Scrollable).hitTestable();
      if (scrollables.evaluate().isEmpty) break;
      try {
        await tester.drag(scrollables.first, Offset(0, -step));
        await tester.pumpAndSettle();
      } catch (_) {
        // A bad drag target (e.g. ambiguous/overlapping scrollable
        // geometry) must never crash the whole test — just stop trying
        // to scroll and fall through to the final inTree() check below.
        break;
      }
    }
    return inTree();
  }

  // ── Dev sign-in helpers ────────────────────────────────────────────────────

  /// Opens the Dev Quick Launch sheet and taps the job chip for [jobId].
  Future<void> devSignInAsJob(String jobId) async {
    await tapKey('dev_quick_launch_btn');
    await wait();
    await tapKey('dev_job_$jobId');
    await settle();
  }

  /// Signs in as partner/staff/client via the dev chip.
  Future<void> devSignInAsRole(String role) async {
    await tapKey('dev_quick_launch_btn');
    await wait();
    await tapKey('dev_role_$role');
    await settle();
  }

  /// Signs out properly:
  /// 1. Navigates to the Settings tab (it's in the NavigationBar — hit-testable).
  /// 2. Taps Sign Out on the now-visible screen.
  /// 3. Also removes the mock session key from SharedPreferences directly
  ///    as a safety net, because if the UI tap ever misses the session would
  ///    persist and cause every subsequent run to auto-sign-in, skipping the
  ///    auth screen entirely.
  Future<void> signOut() async {
    try {
      // Navigate to Settings (NavigationBar label — always hit-testable)
      await tapText('Settings') ||
          await tapIcon(Icons.settings_outlined) ||
          await tapIcon(Icons.settings_rounded);
      await wait();

      // Tap Sign Out on the now-active Settings screen
      if (existsText('Sign Out'))      { await tapText('Sign Out'); }
      else if (existsText('Sign out')) { await tapText('Sign out'); }

      // Handle any confirmation dialog
      if (existsText('Confirm')) { await tapText('Confirm'); }
      else if (existsText('Yes'))     { await tapText('Yes'); }

      await settle(const Duration(seconds: 2));
    } catch (_) {}

    // Hard-clear the SharedPreferences session key so the next test's
    // app.main() + restoreSession() always starts unauthenticated.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ae_mock_session_email');
    } catch (_) {}
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  Future<void> goBack() async {
    try {
      final back = find.byType(BackButton);
      if (exists(back)) {
        await tap(back);
        return;
      }
      // Find the innermost Navigator and only pop if it has pages to pop.
      final navigatorFinders = find.byType(Navigator);
      if (navigatorFinders.evaluate().isEmpty) return;

      final navigator = tester.state<NavigatorState>(navigatorFinders.last);
      if (navigator.canPop()) {
        navigator.pop();
        await tester.pumpAndSettle();
      }
      // If canPop() is false we're at the root — do nothing rather than crash.
    } catch (_) {}
  }

  Future<void> tapTab(String label) async {
    await tapText(label);
    await wait();
  }

  // ── Assertions ─────────────────────────────────────────────────────────────

  void expectText(String text)     => expect(find.text(text),    findsAtLeastNWidgets(1));
  void expectKey(String key)       => expect(find.byKey(Key(key)), findsAtLeastNWidgets(1));
  void expectNoText(String text)   => expect(find.text(text),    findsNothing);

  // ── FAB / dialogs ──────────────────────────────────────────────────────────

  Future<bool> tapFab() => tap(find.byType(FloatingActionButton).hitTestable());

  Future<bool> tapAlertButton(String label) async {
    final btn = find.widgetWithText(TextButton, label)
        .evaluate().isEmpty
        ? find.widgetWithText(FilledButton, label)
        : find.widgetWithText(TextButton, label);
    return tap(btn);
  }

  Future<void> dismissDialog() async {
    await tapText('Cancel');
    await wait();
  }

  // ── Pull to refresh ────────────────────────────────────────────────────────

  Future<void> pullToRefresh() async {
    try {
      await tester.drag(find.byType(RefreshIndicator).first, const Offset(0, 300));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// DEBUG ONLY — prints every visible (hit-testable) Text widget's string
  /// plus a few structural hints (Scaffold/AppBar/route type), so we can
  /// see EXACTLY what's on screen at the moment a specific check fails,
  /// instead of inferring it from static code reading. Call this right
  /// before the assertion in whichever test is still failing, run that
  /// single test in isolation, and paste the printed block back.
  ///
  /// Example temporary edit inside a failing test, right before its rec():
  ///   await r.dumpScreen('03_03 just before stillOpen check');
  void dumpScreen(String label) {
    // ignore: avoid_print
    print('\n========== DUMP: $label ==========');
    final allTexts = find.byType(Text).evaluate();
    // ignore: avoid_print
    print('-- Visible Text widgets (${allTexts.length} total) --');
    for (final e in allTexts) {
      final widget = e.widget;
      if (widget is Text) {
        final isVisible = find
            .byWidgetPredicate((w) => w == widget)
            .hitTestable()
            .evaluate()
            .isNotEmpty;
        // ignore: avoid_print
        print('  [${isVisible ? "VISIBLE" : "in-tree"}] "${widget.data}"');
      }
    }
    final scaffolds = find.byType(Scaffold).evaluate().length;
    final fabs = find.byType(FloatingActionButton).hitTestable().evaluate().length;
    final forms = find.byType(TextFormField).evaluate().length;
    // ignore: avoid_print
    print('-- Structural: Scaffolds=$scaffolds  visibleFABs=$fabs  TextFormFields=$forms --');
    // ignore: avoid_print
    print('========== END DUMP: $label ==========\n');
  }
}
