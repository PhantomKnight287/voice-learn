class LeaderboardItem {
  final int xp;
  final String name;
  final String email;

  const LeaderboardItem({
    required this.email,
    required this.name,
    required this.xp,
  });

  factory LeaderboardItem.fromJSON(Map<String, dynamic> json) {
    return LeaderboardItem(
      email: json['email'],
      name: json['name'],
      xp: json['xp'],
    );
  }
}
