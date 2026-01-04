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

class Player {
  final String name;
  const Player(this.name);

  Map<String, dynamic> toMap() => {'name': name};

  factory Player.fromMap(Map<String, dynamic> map) => Player(map['name']);

  @override
  String toString() => name;
}
