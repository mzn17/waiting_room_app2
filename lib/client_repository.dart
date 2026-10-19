import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app2/models/client.dart';

abstract class ClientRepository {
  Stream<List<Client>> watchClients();
  Future<void> add(String name);
  Future<void> remove(String id);
}

class SupabaseClientRepository implements ClientRepository {
  final SupabaseClient _db;

  SupabaseClientRepository(this._db);

  @override
  Stream<List<Client>> watchClients() {
    // .stream() loads the initial rows AND pushes realtime inserts/deletes.
    return _db
        .from('clients')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((rows) => rows.map(Client.fromMap).toList());
  }

  @override
  Future<void> add(String name) async {
    await _db.from('clients').insert({'name': name});
  }

  @override
  Future<void> remove(String id) async {
    await _db.from('clients').delete().eq('id', id);
  }
}
