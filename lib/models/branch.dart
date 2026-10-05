import 'package:cloud_firestore/cloud_firestore.dart';

class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  factory Branch.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Branch(
      id: doc.id,
      name: d['name'] ?? '',
      latitude: (d['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (d['longitude'] as num?)?.toDouble() ?? 0,
      radiusMeters: (d['radiusMeters'] as num?)?.toDouble() ?? 100,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'nameLower': name.toLowerCase(),
      };
}
