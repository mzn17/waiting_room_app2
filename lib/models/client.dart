// lib/models/client.dart
class Client {
  final String id;
  final String name;
  final double? lat;
  final double? lng;
  final DateTime createdAt;
  final bool isSynced;

  const Client({
    required this.id,
    required this.name,
    required this.createdAt,
    this.lat,
    this.lng,
    this.isSynced = true,
  });

  /// Fonctionne pour une ligne SQLite ET pour une ligne Supabase.
  factory Client.fromMap(Map<String, dynamic> map) => Client(
        id: map['id'] as String,
        name: map['name'] as String,
        lat: (map['lat'] as num?)?.toDouble(),
        lng: (map['lng'] as num?)?.toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
        isSynced: (map['is_synced'] ?? 1) == 1,
      );

  Map<String, dynamic> toLocalMap() => {
        ...toRemoteMap(),
        'is_synced': isSynced ? 1 : 0,
      };

  /// Sans is_synced : cette colonne n'existe pas dans Supabase.
  Map<String, dynamic> toRemoteMap() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lng': lng,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  Client copyWith({bool? isSynced}) => Client(
        id: id,
        name: name,
        lat: lat,
        lng: lng,
        createdAt: createdAt,
        isSynced: isSynced ?? this.isSynced,
      );
}