import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/oobli_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/ai_models.dart';
import '../../state/auth_controller.dart';
import '../../state/insights_controller.dart';
import '../../state/transactions_controller.dart';
import '../../ui/widgets/charts.dart';
import '../../ui/widgets/feedback.dart';
import '../../ui/widgets/oobli_button.dart';
import '../../ui/widgets/pressable.dart';
import '../../ui/widgets/tiles.dart';
import '../assistant/ask_oobli_sheet.dart';
import '../transactions/transaction_editor_sheet.dart';
import '../transactions/transaction_widgets.dart';

/// "Oobli says..." home feed.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Quietly pull in new M-Pesa messages every time the feed opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authControllerProvider).value?.smsSyncEnabled ?? false) {
        ref.read(smsSyncControllerProvider.notifier).sync(silent: true);
      }
    });
  }

  Future<void> _refresh() async {
    final profile = ref.read(authControllerProvider).value;
    try {
      if (profile?.smsSyncEnabled ?? false) {
        final added = await ref.read(smsSyncControllerProvider.notifier).sync();
        if (mounted && added > 0) showOobliSnack(context, 'Oobli found $added new transactions');
      } else {
        ref.invalidate(transactionsProvider);
        await ref.read(transactionsProvider.future);
      }
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final txs = ref.watch(transactionsProvider);
    final profile = ref.watch(authControllerProvider).value;
    final insights = ref.watch(currentInsightsProvider);
    final sync = ref.watch(smsSyncControllerProvider);

    return Scaffold(
      floatingActionButton: const AskOobliButton(),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: c.primary,
          backgroundColor: c.surface,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  name: profile?.name ?? '',
                  headline: insights.headline,
                  syncing: sync.isSyncing,
                ),
              ),
              ...txs.when(
                loading: () => [const SliverToBoxAdapter(child: _LoadingFeed())],
                error: (e, _) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorRetry(error: e, onRetry: () => ref.invalidate(transactionsProvider)),
                  ),
                ],
                data: (list) => list.isEmpty
                    ? [SliverFillRemaining(hasScrollBody: false, child: _EmptyFeed(smsEnabled: profile?.smsSyncEnabled ?? false))]
                    : [
                        const SliverToBoxAdapter(child: _TodayFlowCard()),
                        SliverToBoxAdapter(child: _InsightCards(cards: insights.cards)),
                        const SliverToBoxAdapter(child: _RecentList()),
                      ],
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.headline, required this.syncing});

  final String name;
  final String headline;
  final bool syncing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Oobli says...', style: t.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: Sp.xs),
                    AnimatedSwitcher(
                      duration: Motion.medium,
                      child: Text(
                        headline,
                        key: ValueKey(headline),
                        style: t.bodySmall.copyWith(color: c.onBackground),
                      ),
                    ),
                  ],
                ),
              ),
              Pressable(
                onTap: () => context.push(Routes.settings),
                semanticLabel: 'Profile and settings',
                child: InitialsAvatar(name: name, size: 40),
              ),
            ],
          ),
          AnimatedSize(
            duration: Motion.medium,
            child: syncing
                ? Padding(
                    padding: const EdgeInsets.only(top: Sp.md),
                    child: Row(
                      children: [
                        SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
                        ),
                        const SizedBox(width: Sp.sm),
                        Text('Reading new M-Pesa messages…',
                            style: t.labelMedium.copyWith(color: c.secondaryText)),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _TodayFlowCard extends ConsumerWidget {
  const _TodayFlowCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final stats = ref.watch(statsProvider);
    return Padding(
      padding: const EdgeInsets.all(Sp.lg),
      child: Pressable(
        onTap: () => context.push(Routes.analytics),
        scale: 0.98,
        semanticLabel: "Today's flow, open analytics",
        child: OobliCard(
          shadow: true,
          borderColor: Colors.transparent,
          child: Column(
            children: [
              Row(
                children: [
                  Text("Today's Flow", style: t.titleSmall.copyWith(color: c.secondaryText)),
                  const Spacer(),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: stats.spentToday),
                    duration: Motion.slow,
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Text(
                      Fmt.kes(v, cents: true),
                      style: t.titleLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Sp.md),
              FlowBarChart(points: stats.lastDays(7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCards extends StatelessWidget {
  const _InsightCards({required this.cards});

  final List<InsightCard> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.lg),
      child: Column(
        children: [
          for (final card in cards)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.md),
              child: OobliCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ToneDot(
                          tone: card.tone,
                          icon: card.tone == Tone.warning
                              ? Icons.notifications_active_rounded
                              : Icons.insights_rounded,
                        ),
                        const SizedBox(width: Sp.md),
                        Expanded(child: Text(card.title, style: t.titleLarge)),
                      ],
                    ),
                    const SizedBox(height: Sp.md),
                    Text(card.body, style: t.bodyMedium.copyWith(color: c.secondaryText)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: Sp.md, right: Sp.lg),
                        child: OobliLink('Details', onTap: () => context.push(Routes.analytics)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentList extends ConsumerWidget {
  const _RecentList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final recent = (ref.watch(transactionsProvider).value ?? const []).take(5).toList();
    return Container(
      padding: const EdgeInsets.all(Sp.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Rad.lg)),
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Recent M-Pesa', style: t.titleLarge)),
              OobliButton(
                label: 'Add Manual',
                icon: Icons.add,
                variant: OobliButtonVariant.outline,
                size: OobliButtonSize.small,
                onPressed: () => showTransactionEditor(context),
              ),
            ],
          ),
          const SizedBox(height: Sp.sm),
          for (var i = 0; i < recent.length; i++) ...[
            if (i > 0) const Divider(),
            TransactionRow(tx: recent[i], onEdit: () => showTransactionEditor(context, tx: recent[i])),
          ],
          const SizedBox(height: Sp.sm),
          OobliButton(
            label: 'See all activity',
            variant: OobliButtonVariant.ghost,
            size: OobliButtonSize.medium,
            fullWidth: true,
            onPressed: () => context.push(Routes.activity),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends ConsumerWidget {
  const _EmptyFeed({required this.smsEnabled});

  final bool smsEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncing = ref.watch(smsSyncControllerProvider).isSyncing;
    return Center(
      child: EmptyState(
        title: syncing ? 'Reading your M-Pesa messages…' : 'No transactions yet',
        message: syncing
            ? 'Oobli is organising your spending. This only takes a moment.'
            : smsEnabled
                ? 'Pull down to sync again, or add a transaction yourself.'
                : 'Turn on SMS sync in Settings, or add your first transaction manually.',
        action: OobliButton(
          label: 'Add Transaction',
          icon: Icons.add_rounded,
          size: OobliButtonSize.medium,
          onPressed: () => showTransactionEditor(context),
        ),
        secondary: smsEnabled
            ? null
            : OobliButton(
                label: 'Enable SMS sync',
                variant: OobliButtonVariant.ghost,
                size: OobliButtonSize.medium,
                onPressed: () => context.push(Routes.settings),
              ),
      ),
    );
  }
}

class _LoadingFeed extends StatelessWidget {
  const _LoadingFeed();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(Sp.lg),
        child: Column(
          children: [
            SkeletonBox(height: 200, radius: Rad.xl),
            SizedBox(height: Sp.lg),
            SkeletonBox(height: 140, radius: Rad.xl),
            SizedBox(height: Sp.md),
            SkeletonBox(height: 140, radius: Rad.xl),
          ],
        ),
      );
}
