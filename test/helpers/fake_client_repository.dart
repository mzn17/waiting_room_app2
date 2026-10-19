import 'dart:async';
import 'package:waiting_room_app2/client_repository.dart';
import 'package:waiting_room_app2/models/client.dart';

class FakeClientRepository implements ClientRepository {
  final _controller = StreamController<List<Client>>.broadcast();
  final List<Client> _items = [];
  int _counter = 0;

  @override
  Stream<List<Client>> watchClients() => _controller.stream;

  @override
  Future<void> add(String name) async {
    _items.add(Client(
      id: '${_counter++}',
      name: name,
      createdAt: DateTime.now(),
    ));
    _controller.add(List.of(_items));
  }

  @override
  Future<void> remove(String id) async {
    _items.removeWhere((c) => c.id == id);
    _controller.add(List.of(_items));
  }
}
