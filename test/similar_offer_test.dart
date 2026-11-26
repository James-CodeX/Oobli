import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oobli/core/theme/app_theme.dart';
import 'package:oobli/data/models/category.dart';
import 'package:oobli/data/models/transaction.dart';
import 'package:oobli/features/transactions/similar_sheet.dart';
import 'package:oobli/state/transactions_controller.dart';

import 'support/fakes.dart';

Transaction tx(String id, String merchant) => Transaction(
      id: id,
      fingerprint: id,
      amount: 500,
      direction: TxDirection.out,
      merchant: merchant,
      category: TxCategory.shopping,
      channel: TxChannel.till,
      source: TxSource.mpesa,
      occurredAt: DateTime(2026, 11, 20),
      aiCategorized: true,
    );

void main() {
  // The "could be Groceries too" snack stays up after the screen that showed
  // it closes (Quick sort's Done), so Review must still open the sheet.
  for (final leaveFirst in [false, true]) {
    testWidgets('Review opens the similar sheet${leaveFirst ? ' after leaving the screen' : ''}', (tester) async {
      final source = tx('a', 'Naivas Westlands');
      final container = ProviderContainer(overrides: [
        ...await overrides(transactions: [source, tx('b', 'Naivas Kilimani'), tx('c', 'Naivas Kilimani')]),
      ]);
      addTearDown(container.dispose);
      await container.read(transactionsProvider.future);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (home) => Scaffold(
              body: TextButton(
                child: const Text('Open sort'),
                onPressed: () => Navigator.of(home).push(MaterialPageRoute<void>(
                  builder: (page) => Scaffold(
                    body: Column(children: [
                      TextButton(
                        child: const Text('Sort'),
                        onPressed: () => offerSimilar(page, source, TxCategory.groceries),
                      ),
                      TextButton(child: const Text('Done'), onPressed: () => Navigator.pop(page)),
                    ]),
                  ),
                )),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open sort'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();
      expect(find.text('2 similar transactions could be Groceries too'), findsOneWidget);

      if (leaveFirst) {
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(find.text('Review'), findsOneWidget, reason: 'the snack is still showing');
      }

      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(find.text('File these as Groceries too?'), findsOneWidget);
      expect(find.text('Naivas Kilimani'), findsOneWidget);
    });
  }
}
