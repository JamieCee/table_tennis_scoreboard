import 'package:table_tennis_scoreboard/models/player.dart';
import 'package:table_tennis_scoreboard/models/set_score.dart';

//
// class Game {
//   final int order;
//   final bool isDoubles;
//   List<Player> homePlayers;
//   List<Player> awayPlayers;
//   List<SetScore> sets;
//   int setsWonHome;
//   int setsWonAway;
//
//   bool homeTimeoutUsed;
//   bool awayTimeoutUsed;
//
//   Player? startingServer;
//   Player? startingReceiver;
//
//   Game({
//     required this.order,
//     required this.isDoubles,
//     required this.homePlayers,
//     required this.awayPlayers,
//     List<SetScore>? sets,
//     this.setsWonHome = 0,
//     this.setsWonAway = 0,
//     this.homeTimeoutUsed = false,
//     this.awayTimeoutUsed = false,
//     this.startingServer,
//     this.startingReceiver,
//   }) : sets = sets ?? [SetScore()];
//
//   Map<String, dynamic> toMap() {
//     return {
//       'order': order,
//       'isDoubles': isDoubles,
//       'homePlayers': homePlayers.map((p) => p.name).toList(),
//       'awayPlayers': awayPlayers.map((p) => p.name).toList(),
//       'sets': sets.map((s) => s.toMap()).toList(),
//       'setsWonHome': setsWonHome,
//       'setsWonAway': setsWonAway,
//       'homeTimeoutUsed': homeTimeoutUsed,
//       'awayTimeoutUsed': awayTimeoutUsed,
//       'startingServer': startingServer?.name,
//       'startingReceiver': startingReceiver?.name,
//     };
//   }
//
//   factory Game.fromMap(Map<String, dynamic> map) {
//     return Game(
//       order: map['order'],
//       isDoubles: map['isDoubles'] ?? false,
//       homePlayers: (map['homePlayers'] as List<dynamic>)
//           .map((n) => Player(n))
//           .toList(),
//       awayPlayers: (map['awayPlayers'] as List<dynamic>)
//           .map((n) => Player(n))
//           .toList(),
//       sets: (map['sets'] as List<dynamic>)
//           .map((s) => SetScore.fromMap(s))
//           .toList(),
//       setsWonHome: map['setsWonHome'] ?? 0,
//       setsWonAway: map['setsWonAway'] ?? 0,
//       homeTimeoutUsed: map['homeTimeoutUsed'] ?? false,
//       awayTimeoutUsed: map['awayTimeoutUsed'] ?? false,
//       startingServer: map['startingServer'] != null
//           ? Player(map['startingServer'])
//           : null,
//       startingReceiver: map['startingReceiver'] != null
//           ? Player(map['startingReceiver'])
//           : null,
//     );
//   }
//
//   factory Game.fromJson(Map<String, dynamic> json) {
//     var game = Game(
//       order: json['order'],
//       isDoubles: json['isDoubles'],
//       homePlayers: (json['homePlayers'] as List).map((p) => Player(p)).toList(),
//       awayPlayers: (json['awayPlayers'] as List).map((p) => Player(p)).toList(),
//     );
//     // Re-populate the sets from the saved data
//     game.sets = (json['sets'] as List)
//         .map((setData) => SetScore.fromJson(setData))
//         .toList();
//     game.setsWonHome = json['setsWonHome'];
//     game.setsWonAway = json['setsWonAway'];
//     return game;
//   }
// }
class Game {
  final int order;
  final bool isDoubles;
  final List<Player> homePlayers;
  final List<Player> awayPlayers;
  final List<SetScore> sets;
  final int setsWonHome;
  final int setsWonAway;
  final bool homeTimeoutUsed;
  final bool awayTimeoutUsed;
  final Player? startingServer;
  final Player? startingReceiver;

  const Game({
    required this.order,
    required this.isDoubles,
    required this.homePlayers,
    required this.awayPlayers,
    this.sets = const [const SetScore()],
    this.setsWonHome = 0,
    this.setsWonAway = 0,
    this.homeTimeoutUsed = false,
    this.awayTimeoutUsed = false,
    this.startingServer,
    this.startingReceiver,
  });

  Game copyWith({
    List<Player>? homePlayers,
    List<Player>? awayPlayers,
    List<SetScore>? sets,
    int? setsWonHome,
    int? setsWonAway,
    bool? homeTimeoutUsed,
    bool? awayTimeoutUsed,
    Player? startingServer,
    Player? startingReceiver,
  }) {
    return Game(
      order: order,
      isDoubles: isDoubles,
      homePlayers: homePlayers ?? this.homePlayers,
      awayPlayers: awayPlayers ?? this.awayPlayers,
      sets: sets ?? this.sets,
      setsWonHome: setsWonHome ?? this.setsWonHome,
      setsWonAway: setsWonAway ?? this.setsWonAway,
      homeTimeoutUsed: homeTimeoutUsed ?? this.homeTimeoutUsed,
      awayTimeoutUsed: awayTimeoutUsed ?? this.awayTimeoutUsed,
      startingServer: startingServer ?? this.startingServer,
      startingReceiver: startingReceiver ?? this.startingReceiver,
    );
  }

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
      sets:
          (map['sets'] as List<dynamic>?)
              ?.map((s) => SetScore.fromMap(s))
              .toList() ??
          [SetScore()],
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

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      order: json['order'],
      isDoubles: json['isDoubles'] ?? false,
      homePlayers: (json['homePlayers'] as List).map((p) => Player(p)).toList(),
      awayPlayers: (json['awayPlayers'] as List).map((p) => Player(p)).toList(),
      sets:
          (json['sets'] as List?)?.map((s) => SetScore.fromJson(s)).toList() ??
          [SetScore()],
      setsWonHome: json['setsWonHome'] ?? 0,
      setsWonAway: json['setsWonAway'] ?? 0,
      homeTimeoutUsed: json['homeTimeoutUsed'] ?? false,
      awayTimeoutUsed: json['awayTimeoutUsed'] ?? false,
      startingServer: json['startingServer'] != null
          ? Player(json['startingServer'])
          : null,
      startingReceiver: json['startingReceiver'] != null
          ? Player(json['startingReceiver'])
          : null,
    );
  }
}
