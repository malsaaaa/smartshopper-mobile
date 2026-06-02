/// Retailer model representing a shopping retailer/store
class Retailer {
  final int id;
  final String name;
  final String logoUrl;
  final String website;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  Retailer({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.website,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor for creating from JSON
  factory Retailer.fromJson(Map<String, dynamic> json) {
    return Retailer(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : (json['id'] as int? ?? 0),
      name: json['name'] as String? ?? '',
      logoUrl: (json['logoUrl'] as String? ?? '').isNotEmpty 
          ? json['logoUrl'] as String 
          : (json['icon'] as String? ?? ''),
      website: json['website'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['createdAt'] is String ? DateTime.parse(json['createdAt']) : (json['createdAt'] as dynamic),
      updatedAt: json['updatedAt'] is String ? DateTime.parse(json['updatedAt']) : (json['updatedAt'] as dynamic),
    );
  }

  /// Factory constructor for creating from Firestore
  factory Retailer.fromFirestore(Map<String, dynamic> json, String docId) {
    return Retailer(
      id: int.tryParse(docId) ?? 0,
      name: json['name'] as String? ?? '',
      logoUrl: (json['logoUrl'] as String? ?? '').isNotEmpty 
          ? json['logoUrl'] as String 
          : (json['icon'] as String? ?? ''),
      website: json['website'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'website': website,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'Retailer(id: $id, name: $name, lat: $latitude, lng: $longitude)';
}
