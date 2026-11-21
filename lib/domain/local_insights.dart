import '../core/theme/oobli_colors.dart';
import '../core/utils/formatters.dart';
import '../data/models/ai_models.dart';
import '../data/models/goal.dart';
import 'spending_stats.dart';

/// Rule-based insights used when the AI service is unavailable, so every
/// "Oobli says..." surface always has something true and useful to show.
abstract final class LocalInsights {
  static AiInsights build(SpendingStats stats, {Goal? primaryGoal}) {
    final end = stats.today.add(const Duration(days: 1));
    final weekStart = end.subtract(const Duration(days: 7));
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));

    return AiInsights(
      headline: headline(stats),
      cards: _cards(stats, weekStart, end),
      activityNote: _activityNote(stats, weekStart, prevWeekStart, end),
      analyticsNote: _analyticsNote(stats, weekStart, prevWeekStart, end),
      goalNote: primaryGoal == null ? '' : goalProjection(primaryGoal, stats),
      isFallback: true,
    );
  }

  static String headline(SpendingStats stats) {
    if (stats.all.isEmpty) return "Let's get your money story started";
    final day = stats.sameDayLastWeekChange;
    if (day != null && day >= 1) {
      return "You've spent ${Fmt.kes(stats.spentToday)} today, more than a usual ${Fmt.weekdayName(stats.today)}";
    }
    if (day != null && day.abs() >= 0.05) {
      return 'Your spending is ${Fmt.percent(day.abs())} ${day < 0 ? 'lower' : 'higher'} '
          'than last ${Fmt.weekdayName(stats.today)}';
    }
    final week = stats.weekOverWeekChange;
    if (week != null) {
      return 'This week is ${Fmt.percent(week.abs())} ${week <= 0 ? 'lower' : 'higher'} than last week';
    }
    return 'You spent ${Fmt.kes(stats.spentToday)} today';
  }

  static List<InsightCard> _cards(SpendingStats stats, DateTime weekStart, DateTime end) {
    final cards = <InsightCard>[];
    final recurring = stats.recurringCharges();
    if (recurring.isNotEmpty) {
      final r = recurring.first;
      cards.add(InsightCard(
        title: 'Subscription Alert',
        body: 'Oobli noticed a ${Fmt.kes(r.amount)} payment to ${r.merchant} every month. '
            'Still using it?',
        tone: Tone.warning,
      ));
    }

    final averages = stats.weekdayAverages();
    final todayAvg = averages[stats.today.weekday] ?? 0;
    if (todayAvg > 0 && stats.spentToday > todayAvg * 1.2) {
      cards.add(InsightCard(
        title: 'Spending Pattern',
        body: 'You typically spend ${Fmt.kes(todayAvg)} on ${Fmt.weekdayName(stats.today)}s. '
            "You've already spent ${Fmt.kes(stats.spentToday)} today.",
        tone: Tone.primary,
      ));
    }

    final categories = stats.byCategory(weekStart, end);
    if (cards.length < 2 && categories.isNotEmpty) {
      final top = categories.entries.first;
      cards.add(InsightCard(
        title: 'Top Category',
        body: '${top.key.label} took ${Fmt.kes(top.value)} this week — '
            '${Fmt.percent(top.value / categories.values.fold(0.0, (a, b) => a + b))} of your spending.',
        tone: Tone.primary,
      ));
    }
    if (cards.length < 2 && stats.needsReviewCount > 0) {
      cards.add(InsightCard(
        title: 'Quick Review',
        body: '${stats.needsReviewCount} transactions were auto-categorised. '
            'A quick check keeps your charts accurate.',
        tone: Tone.info,
      ));
    }
    return cards.take(2).toList();
  }

  static String _activityNote(SpendingStats stats, DateTime weekStart, DateTime prevStart, DateTime end) {
    final now = stats.byCategory(weekStart, end);
    final before = stats.byCategory(prevStart, weekStart);
    for (final entry in now.entries) {
      final prev = before[entry.key] ?? 0;
      if (prev > 0 && entry.value > prev * 1.1) {
        return "You've spent ${Fmt.percent((entry.value - prev) / prev)} more on "
            '${entry.key.label} this week than last week.';
      }
    }
    final total = stats.spentBetween(weekStart, end);
    return total > 0
        ? "You've spent ${Fmt.kes(total)} in the last 7 days. Nice and steady."
        : 'No spending recorded this week yet.';
  }

  static String _analyticsNote(SpendingStats stats, DateTime weekStart, DateTime prevStart, DateTime end) {
    final now = stats.byChannel(weekStart, end);
    final before = stats.byChannel(prevStart, weekStart);
    if (now.isEmpty) return 'Once Oobli sees a few transactions, your channel breakdown appears here.';
    final top = now.entries.first;
    final prev = before[top.key] ?? 0;
    if (prev > 0) {
      final change = (top.value - prev) / prev;
      return "You've spent ${Fmt.percent(change.abs())} ${change >= 0 ? 'more' : 'less'} on "
          '${top.key.label} this week compared to last.';
    }
    return '${top.key.label} lead your spending this week at ${Fmt.kes(top.value)}.';
  }

  /// "At your current save rate, you'll hit this goal by December!"
  static String goalProjection(Goal goal, SpendingStats stats) {
    if (goal.isComplete) return 'You did it! ${goal.title} is fully funded. Time to celebrate.';
    final monthStart = stats.today.monthStart;
    final monthly = [
      for (var i = 1; i <= 3; i++)
        stats.savedBetween(
          DateTime(monthStart.year, monthStart.month - i),
          DateTime(monthStart.year, monthStart.month - i + 1),
        ),
    ].fold(0.0, (a, b) => a + b) / 3;
    if (monthly <= 0) {
      return 'Move a little into savings each week and Oobli will project when you hit '
          '${goal.title}.';
    }
    final months = (goal.remaining / monthly).ceil();
    final eta = DateTime(stats.today.year, stats.today.month + months);
    final weekly = (goal.remaining / 52 / 100).ceil() * 100;
    return "At your current M-Pesa save rate, you'll hit this goal by ${Fmt.monthName(eta)}! "
        'Want to boost it with a weekly ${Fmt.ksh(weekly.clamp(200, 5000))} sweep?';
  }

  /// Milestones shown on Oobli Goals, derived from progress and dates.
  static List<Milestone> milestones(Goal goal) {
    final quarter = (goal.target * 0.25 / 1000).round() * 1000;
    String when(double fraction) {
      if (goal.deadline == null) return 'Upcoming';
      final span = goal.deadline!.difference(goal.createdAt);
      final date = goal.createdAt.add(span * fraction);
      if (date.isBefore(DateTime.now())) return 'Behind schedule · was due ${Fmt.shortDate(date)}';
      final months = (date.difference(DateTime.now()).inDays / 30).round();
      if (months >= 2) return 'In $months months';
      return Fmt.shortDate(date);
    }

    return [
      Milestone(
        label: 'Initial Deposit',
        date: Fmt.shortDate(goal.createdAt),
        completed: goal.saved > 0,
      ),
      Milestone(
        label: 'Reach ${Fmt.ksh(quarter)}',
        date: goal.saved >= quarter ? 'Done' : when(0.25),
        completed: goal.saved >= quarter,
      ),
      Milestone(
        label: 'Halfway Mark',
        date: goal.progress >= 0.5 ? 'Done' : when(0.5),
        completed: goal.progress >= 0.5,
      ),
      Milestone(
        label: 'Final Purchase',
        date: goal.deadline == null ? 'When you reach ${Fmt.ksh(goal.target)}' : Fmt.shortDate(goal.deadline!),
        completed: goal.isComplete,
      ),
    ];
  }

  static WrappedStory wrapped(MonthRecap recap) {
    final badges = <WrappedBadge>[
      if (recap.saved > 0) const WrappedBadge(label: 'Saver', icon: 'saver'),
      if (recap.transactionCount >= 30) const WrappedBadge(label: 'M-Pesa Power User', icon: 'power'),
      if (recap.previousTotal > 0 && recap.total < recap.previousTotal)
        const WrappedBadge(label: 'Spend Shrinker', icon: 'trend'),
    ];
    final peak = recap.peakWeekday == null
        ? null
        : Fmt.weekdayName(DateTime(2024, 1, recap.peakWeekday!));
    final top = recap.categories.entries.isEmpty ? null : recap.categories.entries.first;

    var winTitle = 'Financial Win!';
    var winBody = 'You tracked ${recap.transactionCount} transactions this month. Oobli is proud!';
    for (final entry in recap.categories.entries) {
      final prev = recap.previousCategories[entry.key] ?? 0;
      if (prev > 0 && entry.value < prev) {
        winBody = 'You spent ${Fmt.percent((prev - entry.value) / prev)} less on '
            '${entry.key.label.toLowerCase()} compared to last month. Oobli is proud!';
        break;
      }
    }
    if (recap.saved > 0 && winBody.startsWith('You tracked')) {
      winTitle = 'Saver Mode';
      winBody = 'You moved ${Fmt.kes(recap.saved)} into savings this month. Keep it going!';
    }

    return WrappedStory(
      insight: top == null
          ? 'A quiet month! Add or sync transactions to see your story.'
          : 'Your biggest category was ${top.key.label} at ${Fmt.kes(top.value)}'
              '${peak == null ? '' : ', and your spending peaked on ${peak}s'}.'
              '${recap.aiCategorized > 0 ? ' Oobli auto-categorised ${recap.aiCategorized} transactions for you!' : ''}',
      badges: badges.isEmpty ? const [WrappedBadge(label: 'Getting Started', icon: 'star')] : badges,
      winTitle: winTitle,
      winBody: winBody,
    );
  }
}
