import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'geolocation_service.dart';
import 'local_queue_service.dart';

class QueueProvider extends ChangeNotifier {
  final SupabaseClient? _supabase;
  final LocalQueueService _localDb;
  final GeolocationService _geoService;
  StreamSubscription? _subscription;
  String? error;

  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> get clients => _clients;

  QueueProvider({
    LocalQueueService? localDb,
    GeolocationService? geoService,
    SupabaseClient? supabase,
  })  : _localDb = localDb ?? LocalQueueService(),
        _geoService = geoService ?? GeolocationService(),
        // ignore: prefer_initializing_formals
        _supabase = supabase;

  SupabaseClient? get _supabaseClient {
    if (_supabase != null) return _supabase;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    await _loadQueue();
  }

  Future<void> _loadQueue() async {
    // 1. Load from local DB immediately (offline support)
    _clients = await _localDb.getClients();
    notifyListeners();

    // 2. Sync unsynced records to Supabase
    await _syncLocalToRemote();

    // 3. Subscribe to real-time updates
    _setupRealtimeSubscription();
  }

  Future<void> _syncLocalToRemote() async {
    final client = _supabaseClient;
    if (client == null) return;
    final unsynced = await _localDb.getUnsyncedClients();
    for (var c in unsynced) {
      try {
        final remoteClient = Map<String, dynamic>.from(c)..remove('is_synced');
        await client.from('clients').upsert(remoteClient);
        await _localDb.markClientAsSynced(c['id'] as String);
        // Optional: update local _clients list to reflect sync status
      } catch (e) {
        // Log error but continue syncing other items
        debugPrint('Sync failed for ${c['id']}: $e');
        // In production: consider retry logic or user notification
      }
    }
    // Refresh UI if any sync succeeded
    _clients = await _localDb.getClients();
    notifyListeners();
  }

  Future<void> addClient(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final position = await _geoService.getCurrentPosition();
    final newClient = {
      'id': const Uuid().v4(),
      'name': trimmed,
      'lat': position?.latitude,
      'lng': position?.longitude,
      'created_at': DateTime.now().toIso8601String(),
      'is_synced': 0,
    };

    // Save locally immediately
    await _localDb.insertClientLocally(newClient);

    // Update UI instantly
    _clients.add(newClient);
    _clients.sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));
    notifyListeners();

    // Attempt sync (non-blocking for UX)
    unawaited(_syncLocalToRemote());
  }

  void _setupRealtimeSubscription() {
    final client = _supabaseClient;
    if (client == null) return;
    try {
      _subscription?.cancel();
      _subscription = client
          .from('clients')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: true)
          .listen((data) async {
        for (var row in data) {
          final localMap = Map<String, dynamic>.from(row);
          localMap['is_synced'] = 1;
          await _localDb.insertClientLocally(localMap);
        }
        _clients = await _localDb.getClients();
        notifyListeners();
      }, onError: (e) {
        debugPrint('Realtime subscription error: $e');
      });
    } catch (e) {
      debugPrint('Subscription error: $e');
    }
  }

  Future<void> removeClient(String id) async {
    try {
      await _localDb.deleteClientLocally(id);
      _clients.removeWhere((c) => c['id'] == id);
      notifyListeners();
      final client = _supabaseClient;
      if (client != null) {
        try {
          await client.from('clients').delete().eq('id', id);
        } catch (e) {
          debugPrint('Remote delete error: $e');
        }
      }
    } catch (e) {
      error = 'Failed to remove client: $e';
      notifyListeners();
    }
  }

  Future<void> nextClient() async {
    if (_clients.isEmpty) return;
    final firstId = _clients.first['id'] as String;
    await removeClient(firstId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
