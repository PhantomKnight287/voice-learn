class LeaderboardItem {
  final int xp;
  final String name;
  final String? avatarHash;
  final String id;
  final String? avatar;
  const LeaderboardItem({
    this.avatarHash,
    required this.name,
    required this.xp,
    required this.id,
    this.avatar,
  });

  factory LeaderboardItem.fromJSON(Map<String, dynamic> json) {
    return LeaderboardItem(
      avatarHash: json['avatarHash'],
      name: json['name'],
      xp: json['xp'],
      id: json['id'],
      avatar: json['avatar'],
    );
  }
}
