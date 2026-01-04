part of 'match_bloc.dart';

abstract class MatchEvent {}

class MatchStarted extends MatchEvent {}

class MatchResumed extends MatchEvent {
  final Map<String, dynamic> resumeData;
  MatchResumed(this.resumeData);
}

class FirestoreUpdated extends MatchEvent {
  final Map<String, dynamic> data;
  FirestoreUpdated(this.data);
}

class MatchDeleted extends MatchEvent {}

class AddPointHome extends MatchEvent {}

class AddPointAway extends MatchEvent {}

class UndoPointHome extends MatchEvent {}

class UndoPointAway extends MatchEvent {}

// ------------------- SERVER / DOUBLES EVENTS -------------------

class SetServer extends MatchEvent {
  final Player server;
  final Player receiver;
  SetServer({required this.server, required this.receiver});
}

class SetDoublesPlayers extends MatchEvent {
  final List<Player> home;
  final List<Player> away;
  SetDoublesPlayers({required this.home, required this.away});
}

class SetDoublesServer extends MatchEvent {
  final Player server;
  final Player receiver;

  SetDoublesServer({required this.server, required this.receiver});
}

// ------------------- BREAK / TIMEOUT -------------------

class StartBreak extends MatchEvent {}

class EndBreak extends MatchEvent {}

class StartTimeout extends MatchEvent {
  final bool isHome;
  StartTimeout({required this.isHome});
}

class EndTimeout extends MatchEvent {}

class EndBreakEarly extends MatchEvent {}

class EndTimeoutEarly extends MatchEvent {}

// ------------------- NEXT GAME -------------------

class StartNextGame extends MatchEvent {}
