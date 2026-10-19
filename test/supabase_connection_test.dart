// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app2/supabase_config.dart';

void main() {
  test('Supabase connection and insert test', () async {
    final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

    // Verify connection to Supabase and clients table
    final data = await client.from('clients').select();
    expect(data, isNotNull);
    print('Supabase connection successful. Existing records: ${data.length}');

    try {
      // Insert a test client
      final inserted = await client.from('clients').insert({
        'name': 'Test Client - Antigravity',
      }).select();

      expect(inserted, isNotEmpty);
      expect(inserted.first['name'], 'Test Client - Antigravity');
      expect(inserted.first['id'], isNotNull);
      expect(inserted.first['created_at'], isNotNull);

      print('Successfully inserted: $inserted');

      // Clean up test client
      final id = inserted.first['id'];
      await client.from('clients').delete().eq('id', id);

      print('Successfully cleaned up test client with ID: $id');
    } on PostgrestException catch (e) {
      print('PostgrestException: code=${e.code}, message=${e.message}, details=${e.details}');
      if (e.code == '42501') {
        print(
          'Note: Row-Level Security (RLS) is active on "clients". '
          'Insert requires an RLS policy in Supabase dashboard.',
        );
      } else {
        rethrow;
      }
    }
  });
}
