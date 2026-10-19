import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waiting_room_app2/main.dart';
import 'package:waiting_room_app2/queue_provider.dart';
import 'helpers/fake_client_repository.dart';

void main() {
  testWidgets('Next Client removes the first client from the list',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => QueueProvider(FakeClientRepository()),
        child: const WaitingRoomApp(),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Client A');
    await tester.tap(find.byKey(const Key('addButton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Client B');
    await tester.tap(find.byKey(const Key('addButton')));
    await tester.pumpAndSettle();

    expect(find.text('Clients in Queue: 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nextClientButton')));
    await tester.pumpAndSettle();

    expect(find.text('Client A'), findsNothing);
    expect(find.text('Client B'), findsOneWidget);
    expect(find.text('Clients in Queue: 1'), findsOneWidget);
  });
}
