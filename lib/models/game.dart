import 'package:table_tennis_scoreboard/models/player.dart';
import 'package:table_tennis_scoreboard/models/set_score.dart';

class Game {
  final int order;
  final bool isDoubles;
  List<Player> homePlayers;
  List<Player> awayPlayers;
  List<SetScore> sets;
  int setsWonHome;
  int setsWonAway;

  bool homeTimeoutUsed;
  bool awayTimeoutUsed;

  Player? startingServer;
  Player? startingReceiver;

  Game({
    required this.order,
    required this.isDoubles,
    required this.homePlayers,
    required this.awayPlayers,
    List<SetScore>? sets,
    this.setsWonHome = 0,
    this.setsWonAway = 0,
    this.homeTimeoutUsed = false,
    this.awayTimeoutUsed = false,
    this.startingServer,
    this.startingReceiver,
  }) : sets = sets ?? [SetScore()];

  Map<String, dynamic> toMap() {
    return {
      'order': order,
      'isDoubles': isDoubles,
      'homePlayers': homePlayers.map((p) => p.name).toList(),
      'awayPlayers': awayPlayers.map((p) => p.name).toList(),
      'sets': sets.map((s) => s.toMap()).toList(),
      'setsWonHome': setsWonHome,
      'setsWonAway': setsWonAway,
      'homeTimeoutUsed': homeTimeoutUsed,
      'awayTimeoutUsed': awayTimeoutUsed,
      'startingServer': startingServer?.name,
      'startingReceiver': startingReceiver?.name,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      order: map['order'],
      isDoubles: map['isDoubles'] ?? false,
      homePlayers: (map['homePlayers'] as List<dynamic>)
          .map((n) => Player(n))
          .toList(),
      awayPlayers: (map['awayPlayers'] as List<dynamic>)
          .map((n) => Player(n))
          .toList(),
      sets: (map['sets'] as List<dynamic>)
          .map((s) => SetScore.fromMap(s))
          .toList(),
      setsWonHome: map['setsWonHome'] ?? 0,
      setsWonAway: map['setsWonAway'] ?? 0,
      homeTimeoutUsed: map['homeTimeoutUsed'] ?? false,
      awayTimeoutUsed: map['awayTimeoutUsed'] ?? false,
      startingServer: map['startingServer'] != null
          ? Player(map['startingServer'])
          : null,
      startingReceiver: map['startingReceiver'] != null
          ? Player(map['startingReceiver'])
          : null,
    );
  }
}
