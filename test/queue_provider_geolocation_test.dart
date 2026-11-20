import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app2/geolocation_service.dart';
import 'package:waiting_room_app2/local_queue_service.dart';
import 'package:waiting_room_app2/main.dart';
import 'package:waiting_room_app2/queue_provider.dart';

import 'queue_provider_geolocation_test.mocks.dart';

@GenerateMocks([GeolocationService, QueueProvider])
void main() {
  setUpAll(() {
    // Confirm databaseFactory = databaseFactoryFfi in test setup (troubleshooting guide)
    databaseFactory = databaseFactoryFfi;
  });

  group('Part 3.1: Unit Test with Mocked Geolocation', () {
    test('addClient saves client with geolocation', () async {
      final mockGeo = MockGeolocationService();
      final mockPos = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      when(mockGeo.getCurrentPosition()).thenAnswer((_) async => mockPos);

      final provider = QueueProvider(
        geoService: mockGeo,
        localDb: LocalQueueService(inMemory: true),
      );

      await provider.addClient('Test User');

      final client = provider.clients.last;
      expect(client['lat'], 37.7749);
      expect(client['lng'], -122.4194);
    });
  });

  group('Part 3.2: Widget Test for Location Display', () {
    testWidgets('Displays location when available', (tester) async {
      final provider = MockQueueProvider();
      when(provider.clients).thenReturn([
        {
          'id': '1',
          'name': 'Sam',
          'lat': 51.5074,
          'lng': -0.1278,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      when(provider.error).thenReturn(null);

      await tester.pumpWidget(
        ChangeNotifierProvider<QueueProvider>.value(
          value: provider,
          child: const MaterialApp(home: WaitingRoomScreen()),
        ),
      );

      expect(find.text('Sam'), findsOneWidget);
      expect(find.textContaining('51.5074'), findsOneWidget);
    });
  });
}

