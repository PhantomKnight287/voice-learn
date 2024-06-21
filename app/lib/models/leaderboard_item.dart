class LeaderboardItem {
  final int xp;
  final String name;
  final String email;
  final String id;
  const LeaderboardItem({
    required this.email,
    required this.name,
    required this.xp,
    required this.id,
  });

  factory LeaderboardItem.fromJSON(Map<String, dynamic> json) {
    return LeaderboardItem(
      email: json['email'],
      name: json['name'],
      xp: json['xp'],
      id: json['id'],
    );
  }
}
