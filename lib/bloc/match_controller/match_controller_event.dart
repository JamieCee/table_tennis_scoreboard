part of 'match_controller_bloc.dart';

abstract class MatchControllerEvent {}

class InitializeMatch extends MatchControllerEvent {}

class ResumeMatch extends MatchControllerEvent {
  final Map<String, dynamic> resumeData;
  ResumeMatch(this.resumeData);
}

class AddPointHome extends MatchControllerEvent {}

class AddPointAway extends MatchControllerEvent {}

class UndoPointHome extends MatchControllerEvent {}

class UndoPointAway extends MatchControllerEvent {}

class StartBreak extends MatchControllerEvent {}

class EndBreak extends MatchControllerEvent {}

class StartTimeout extends MatchControllerEvent {
  final bool isHome;
  StartTimeout(this.isHome);
}

class EndTimeout extends MatchControllerEvent {}

class SetServer extends MatchControllerEvent {
  final Player server;
  final Player receiver;
  SetServer(this.server, this.receiver);
}

class SetDoublesPlayers extends MatchControllerEvent {
  final List<Player> home;
  final List<Player> away;
  SetDoublesPlayers(this.home, this.away);
}

class StartNextGame extends MatchControllerEvent {}

class DeleteMatch extends MatchControllerEvent {}

class UpdateFromMap extends MatchControllerEvent {
  final Map<String, dynamic> data;
  UpdateFromMap(this.data);
}
