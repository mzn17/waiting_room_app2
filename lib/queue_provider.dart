import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:waiting_room_app2/client_repository.dart';
import 'package:waiting_room_app2/models/client.dart';

class QueueProvider extends ChangeNotifier {
  final ClientRepository _repo;
  List<Client> _clients = [];
  String? error;
  StreamSubscription<List<Client>>? _subscription;

  QueueProvider(this._repo) {
    _subscription = _repo.watchClients().listen(
      (list) {
        _clients = list;
        error = null;
        notifyListeners();
      },
      onError: (Object e) {
        error = e.toString();
        notifyListeners();
      },
    );
  }

  List<Client> get clients => List.unmodifiable(_clients);

  Future<void> addClient(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    try {
      await _repo.add(trimmed);
    } catch (e) {
      error = 'Failed to add client: $e';
      notifyListeners();
    }
  }

  Future<void> removeClient(String id) async {
    try {
      await _repo.remove(id);
    } catch (e) {
      error = 'Failed to remove client: $e';
      notifyListeners();
    }
  }

  Future<void> nextClient() async {
    if (_clients.isEmpty) return;
    await removeClient(_clients.first.id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}