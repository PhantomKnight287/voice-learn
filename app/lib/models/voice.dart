import 'package:app/models/user.dart';

List<Tiers> tiersFromStrings(List<dynamic> tiers) {
  return tiers.map((tier) => tierFromString(tier as String)).toList();
}

class Voice {
  final String id;
  final String name;
  final String? accent;
  final String? gender;
  final String? description;
  final String previewUrl;
  final String provider;
  final String? createdAt;
  final String? updatedAt;
  final int? chats;
  final List<Tiers> tiers;

  Voice({
    this.accent,
    required this.id,
    required this.name,
    this.gender,
    this.description,
    required this.previewUrl,
    required this.provider,
    this.createdAt,
    this.updatedAt,
    this.chats,
    required this.tiers,
  });

  factory Voice.fromJSON(Map<String, dynamic> json) {
    List<dynamic> backendTiers = json['tiers'];
    List<Tiers> tierEnums = tiersFromStrings(backendTiers);
    return Voice(
      id: json['id'],
      name: json['name'],
      previewUrl: json['previewUrl'],
      provider: json['provider'],
      accent: json['accent'],
      chats: json['_count']?['chats'],
      createdAt: json['createdAt'],
      description: json['description'],
      gender: json['gender'],
      updatedAt: json['updatedAt'],
      tiers: tierEnums,
    );
  }
}
