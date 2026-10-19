import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app2/queue_provider.dart';
import 'helpers/fake_client_repository.dart';

void main() {
  late QueueProvider provider;

  setUp(() {
    provider = QueueProvider(FakeClientRepository());
  });

  tearDown(() => provider.dispose());

  test('addClient adds a client to the queue', () async {
    await provider.addClient('Alice');
    await pumpEventQueue(); // let the stream deliver the update
    expect(provider.clients.length, 1);
    expect(provider.clients.first.name, 'Alice');
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
    expect(provider.clients.first.name, 'Client B');
  });
}
