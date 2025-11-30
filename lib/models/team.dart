import 'player.dart';

class Team {
  final String name;
  final List<Player> players;

  Team({required this.name, required this.players});

  // Add this factory constructor
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      name: json['name'] as String,
      // This maps the list of player strings into a list of Player objects
      players: (json['players'] as List<dynamic>)
          .map((playerName) => Player(playerName as String))
          .toList(),
    );
  }

  // You should also have a toJson method for saving data
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'players': players.map((player) => player.name).toList(),
    };
  }
}
