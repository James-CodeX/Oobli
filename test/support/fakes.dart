import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oobli/core/theme/app_theme.dart';
import 'package:oobli/data/models/ai_models.dart';
import 'package:oobli/data/models/category.dart';
import 'package:oobli/data/models/goal.dart';
import 'package:oobli/data/models/plan.dart';
import 'package:oobli/data/models/transaction.dart';
import 'package:oobli/data/models/user_profile.dart';
import 'package:oobli/core/theme/oobli_colors.dart';
import 'package:oobli/domain/local_insights.dart';
import 'package:oobli/domain/spending_stats.dart';
import 'package:oobli/state/auth_controller.dart';
import 'package:oobli/state/goals_controller.dart';
import 'package:oobli/state/insights_controller.dart';
import 'package:oobli/state/plan_controller.dart';
import 'package:oobli/state/preferences.dart';
import 'package:oobli/state/transactions_controller.dart';
import 'package:oobli/state/wrapped_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

final profile = UserProfile(
  id: 'user-1',
  name: 'Jared Waweru',
  email: 'jared@example.com',
  createdAt: DateTime(2026, 6, 1),
  onboardingComplete: true,
  smsSyncEnabled: false,
  monthlyIncome: 85000,
  streak: 12,
  focus: FocusGoal.saving,
);

int _seq = 0;
Transaction _tx(
  String merchant,
  double amount,
  TxCategory category,
  DateTime at, {
  TxChannel channel = TxChannel.till,
  String? ref,
  bool ai = false,
  TxDirection direction = TxDirection.out,
}) =>
    Transaction(
      id: 't${_seq++}',
      fingerprint: 'fp$_seq',
      amount: amount,
      direction: direction,
      merchant: merchant,
      category: category,
      channel: channel,
      source: TxSource.mpesa,
      occurredAt: at,
      reference: ref,
      aiCategorized: ai,
    );

/// Fixture data modelled on the design screenshots.
List<Transaction> fixtureTransactions() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime at(int daysAgo, int h, int m) => today.subtract(Duration(days: daysAgo)).add(Duration(hours: h, minutes: m));
  return [
    _tx('Naivas Supermarket', 4250, TxCategory.groceries, at(0, 0, 40), ref: 'RL82XJ91', channel: TxChannel.paybill),
    _tx('Mama Mboga Pochi', 350, TxCategory.food, at(0, 0, 25), ref: 'RLJ29S11', channel: TxChannel.pochi, ai: true),
    _tx('KPLC Prepaid', 1000, TxCategory.utilities, at(0, 0, 10), ref: 'RLH01K22', channel: TxChannel.paybill),
    _tx('Shell Service Station', 2500, TxCategory.transport, at(1, 18, 45), ref: 'RKP92M10'),
    _tx('John Kamau', 1200, TxCategory.transfer, at(1, 10, 30), ref: 'RKP11X02', channel: TxChannel.send, ai: true),
    _tx('Netflix', 1100, TxCategory.entertainment, at(28, 0, 1), ref: 'RKF11L99', channel: TxChannel.card),
    _tx('Netflix', 1100, TxCategory.entertainment, at(2, 0, 1), ref: 'RKF11L98', channel: TxChannel.card),
    for (var d = 2; d < 40; d++) ...[
      _tx('Mama Mboga', 300.0 + (d * 37) % 900, TxCategory.groceries, at(d, 9, 0), channel: TxChannel.pochi),
      if (d % 2 == 0) _tx('Super Metro', 100, TxCategory.transport, at(d, 8, 15)),
      if (d % 3 == 0) _tx('Java House', 850.0 + d * 10, TxCategory.food, at(d, 13, 0)),
      if (d % 5 == 0) _tx('Carrefour TRM', 2100.0 + d * 15, TxCategory.groceries, at(d, 17, 0), channel: TxChannel.paybill),
    ],
    _tx('M-Shwari', 5000, TxCategory.savings, at(3, 9, 0), channel: TxChannel.other),
    _tx('Employer Ltd', 85000, TxCategory.income, at(20, 9, 0), channel: TxChannel.received, direction: TxDirection.inbound),
  ];
}

final fixtureGoals = [
  Goal(
    id: 'g1',
    title: 'New MacBook Pro',
    icon: GoalIcon.laptop,
    target: 240000,
    saved: 85000,
    createdAt: DateTime(2026, 10, 12),
    deadline: DateTime(2026, 12, 20),
    isPrimary: true,
  ),
  Goal(id: 'g2', title: 'Coast Trip', icon: GoalIcon.travel, target: 30000, saved: 21000, createdAt: DateTime(2026, 9, 1), tone: Tone.accent),
  Goal(id: 'g3', title: 'Emergency', icon: GoalIcon.emergency, target: 50000, saved: 7500, createdAt: DateTime(2026, 9, 1)),
];

Plan fixturePlan() => Plan(
      id: 'p1',
      month: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
      income: 85000,
      status: PlanStatus.draft,
      goal: 'Save for a new laptop',
      allocations: const [
        PlanAllocation(bucket: PlanBucket.needs, label: 'Fixed Needs', percent: 50, amount: 42500,
            reason: "Rent, Utilities & Internet based on last month's Paybills."),
        PlanAllocation(bucket: PlanBucket.savings, label: 'Savings Goal', percent: 20, amount: 17000,
            reason: 'Oobli suggests 20% to hit your laptop goal by December.'),
        PlanAllocation(bucket: PlanBucket.flex, label: 'Flex Spending', percent: 20, amount: 17000,
            reason: 'Dining and transport. You usually spend this at Tills.'),
        PlanAllocation(bucket: PlanBucket.emergency, label: 'Emergency', percent: 10, amount: 8500,
            reason: 'Safety net for unexpected M-Pesa requests.'),
      ],
    );

class FakeAuth extends AuthController {
  @override
  Future<UserProfile?> build() async => profile;
}

class FakeTransactions extends TransactionsController {
  FakeTransactions(this.items);
  final List<Transaction> items;
  @override
  Future<List<Transaction>> build() async => items;
}

class FakeGoals extends GoalsController {
  @override
  Future<List<Goal>> build() async => fixtureGoals;
}

class FakePlan extends PlanController {
  FakePlan(this.plan);
  final Plan? plan;
  @override
  Future<Plan?> build() async => plan;
}

class FakeRules extends MerchantRulesController {
  @override
  Future<Map<String, TxCategory>> build() async => {'mama mboga': TxCategory.groceries};
}

class FakeInsights extends InsightsController {
  @override
  Future<AiInsights> build() async {
    final stats = SpendingStats(fixtureTransactions());
    final local = LocalInsights.build(stats, primaryGoal: fixtureGoals.first);
    return AiInsights(
      headline: local.headline,
      cards: const [
        InsightCard(
          title: 'Subscription Alert',
          body: "Oobli noticed a KES 1,100 payment to Netflix. You haven't used the app in 14 days. Cancel?",
          tone: Tone.warning,
        ),
        InsightCard(
          title: 'Spending Pattern',
          body: "You typically spend KES 800 on 'Pochi la Biashara' on Wednesdays. You've already spent KES 1,200 today.",
          tone: Tone.primary,
        ),
      ],
      activityNote: "You've spent 15% more on Groceries this week than your AI plan suggested.",
      analyticsNote: local.analyticsNote,
      goalNote: local.goalNote,
      suggestion: const RecategorizeSuggestion(
        merchant: 'Mama Mboga',
        from: TxCategory.transfer,
        to: TxCategory.groceries,
        body: "You've spent 24% more on Tills this week compared to last. Most of this went to 'Mama Mboga' - "
            'should we re-categorize this as Groceries?',
      ),
    );
  }
}

Future<List<Override>> overrides({List<Transaction>? transactions, Plan? plan}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final txs = transactions ?? fixtureTransactions();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    appVersionProvider.overrideWith((ref) async => '1.1.2'),
    authControllerProvider.overrideWith(FakeAuth.new),
    transactionsProvider.overrideWith(() => FakeTransactions(txs)),
    goalsProvider.overrideWith(FakeGoals.new),
    planProvider.overrideWith(() => FakePlan(plan)),
    merchantRulesProvider.overrideWith(FakeRules.new),
    insightsProvider.overrideWith(FakeInsights.new),
    wrappedProvider.overrideWith((ref) async {
      final stats = SpendingStats(txs);
      final recap = stats.recap(stats.latestRecapMonth());
      return WrappedData(recap: recap, story: LocalInsights.wrapped(recap));
    }),
  ];
}

/// Loads the bundled fonts and Material Icons so goldens render like the device.
Future<void> loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(File(f).readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  }

  final fonts = Directory('assets/fonts').listSync().whereType<File>().map((f) => f.path).toList();
  await load('Poppins', fonts.where((f) => f.contains('Poppins')).toList());

  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) await load('MaterialIcons', [icons.path]);
}

/// Wraps [child] in the app theme (dark, like the designs) and provider scope.
Widget harness(Widget child, List<Override> overrides, {ThemeMode mode = ThemeMode.dark}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        home: child,
      ),
    );

/// Phone viewport matching the 440dp-wide design frames.
void usePhoneViewport(WidgetTester tester, {double height = 956}) {
  tester.view.physicalSize = Size(880, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

/// Advances animations without waiting for the mascot's endless loop to settle.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}
