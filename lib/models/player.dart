// class Player {
//   final String name;
//   Player(this.name);
//
//   Map<String, dynamic> toMap() => {'name': name};
//   factory Player.fromMap(Map<String, dynamic> map) => Player(map['name']);
//
//   @override
//   String toString() => name;
// }

import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String name;
  // You could add other player properties here in the future, like an ID or ranking.

  const Player(this.name);

  // --- Start: Methods for Equatable ---
  // This allows Bloc to know if two Player objects are the same
  // by comparing their properties, not their location in memory.
  @override
  List<Object?> get props => [name];
  // --- End: Methods for Equatable ---

  factory Player.fromMap(Map<String, dynamic> map) => Player(map['name']);

  // --- Start: Methods for JSON Serialization ---

  // Standard method for converting an instance to a Map.
  Map<String, dynamic> toJson() => {'name': name};

  // Standard factory for creating an instance from a Map.
  factory Player.fromJson(Map<String, dynamic> json) => Player(json['name']);

  // --- End: Methods for JSON Serialization ---

  @override
  String toString() => name;
}
