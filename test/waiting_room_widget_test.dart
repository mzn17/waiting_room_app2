import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app2/geolocation_service.dart';
import 'package:waiting_room_app2/local_queue_service.dart';
import 'package:waiting_room_app2/main.dart';
import 'package:waiting_room_app2/queue_provider.dart';

class FakeGeolocationService extends GeolocationService {
  @override
  Future<Position?> getCurrentPosition() async => null;
}

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Next Client removes the first client from the list',
      (WidgetTester tester) async {
    final localDb = LocalQueueService(inMemory: true);
    final provider = QueueProvider(
      localDb: localDb,
      geoService: FakeGeolocationService(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<QueueProvider>.value(
        value: provider,
        child: const WaitingRoomApp(),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Client A');
    await tester.tap(find.byKey(const Key('addButton')));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Client B');
    await tester.tap(find.byKey(const Key('addButton')));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();

    expect(find.text('Clients in Queue: 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nextClientButton')));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();

    expect(find.text('Client A'), findsNothing);
    expect(find.text('Client B'), findsOneWidget);
    expect(find.text('Clients in Queue: 1'), findsOneWidget);
  });
}
