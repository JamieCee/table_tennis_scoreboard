import 'package:equatable/equatable.dart';

import 'player.dart';

class Team extends Equatable {
  final String name;
  final List<Player> players;
  final int startingPoints;

  const Team({
    required this.name,
    required this.players,
    this.startingPoints = 0,
  });

  // A copyWith method is extremely useful for immutable objects, especially with Bloc
  Team copyWith({String? name, List<Player>? players, int? startingPoints}) {
    return Team(
      name: name ?? this.name,
      players: players ?? this.players,
      startingPoints: startingPoints ?? this.startingPoints,
    );
  }

  // Corrected factory constructor
  factory Team.fromJson(Map<String, dynamic> json) {
    var playersList = json['players'] as List<dynamic>? ?? [];

    return Team(
      name: json['name'] as String,
      // Assumes Player.fromJson exists. If Player is just a name, this is fine,
      // but a dedicated fromJson on the Player model is better.
      players: playersList
          .map((playerJson) => Player.fromJson(playerJson))
          .toList(),
      // FIX: Read startingPoints from the JSON, defaulting to 0 if not present
      startingPoints: json['startingPoints'] as int? ?? 0,
    );
  }

  // Corrected toJson method
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      // Assumes Player.toJson exists.
      'players': players.map((player) => player.toJson()).toList(),
      // FIX: Add startingPoints to the JSON when saving
      'startingPoints': startingPoints,
    };
  }

  // Equatable props for state comparison in Bloc
  @override
  List<Object?> get props => [name, players, startingPoints];
}
