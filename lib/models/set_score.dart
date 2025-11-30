class SetScore {
  int home = 0;
  int away = 0;

  SetScore({this.home = 0, this.away = 0});

  Map<String, dynamic> toMap() => {'home': home, 'away': away};

  factory SetScore.fromMap(Map<String, dynamic> map) {
    return SetScore(home: map['home'] ?? 0, away: map['away'] ?? 0);
  }

  factory SetScore.fromJson(Map<String, dynamic> json) {
    return SetScore(
      home:
          json['home'] as int? ??
          0, // Use ?? 0 as a safeguard against null data
      away: json['away'] as int? ?? 0,
    );
  }
}
