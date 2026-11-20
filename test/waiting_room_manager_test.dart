import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app2/geolocation_service.dart';
import 'package:waiting_room_app2/local_queue_service.dart';
import 'package:waiting_room_app2/queue_provider.dart';

class FakeGeolocationService extends GeolocationService {
  @override
  Future<Position?> getCurrentPosition() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late QueueProvider provider;
  late LocalQueueService localDb;

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    localDb = LocalQueueService(inMemory: true);
    provider = QueueProvider(
      localDb: localDb,
      geoService: FakeGeolocationService(),
    );
  });

  tearDown(() async {
    provider.dispose();
    await localDb.close();
  });

  test('addClient adds a client to the queue', () async {
    await provider.addClient('Alice');
    await pumpEventQueue();
    expect(provider.clients.length, 1);
    expect(provider.clients.first['name'], 'Alice');
  });

  test('addClient ignores empty names', () async {
    await provider.addClient(' ');
    await pumpEventQueue();
    expect(provider.clients, isEmpty);
  });

  test('nextClient removes the first client', () async {
    await provider.addClient('Client A');
    await provider.addClient('Client B');
    await pumpEventQueue();
    await provider.nextClient();
    await pumpEventQueue();
    expect(provider.clients.length, 1);
    expect(provider.clients.first['name'], 'Client B');
  });
}
