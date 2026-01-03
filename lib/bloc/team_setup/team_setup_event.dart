// lib/bloc/team_setup/team_setup_event.dart
part of 'team_setup_bloc.dart';

abstract class TeamSetupEvent extends Equatable {
  const TeamSetupEvent();
  @override
  List<Object?> get props => [];
}

// Event when user taps an item on the bottom navy bar
class MatchTypeChanged extends TeamSetupEvent {
  final MatchType matchType;
  const MatchTypeChanged(this.matchType);
  @override
  List<Object> get props => [matchType];
}

// Event for when any text field (player or team name) is updated
class NameChanged extends TeamSetupEvent {
  final String homeTeamName;
  final String awayTeamName;
  final List<String> homePlayerNames;
  final List<String> awayPlayerNames;

  const NameChanged({
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homePlayerNames,
    required this.awayPlayerNames,
  });
}

// Event when user changes the number of sets to win
class SetsToWinChanged extends TeamSetupEvent {
  final int setsToWin;
  const SetsToWinChanged(this.setsToWin);
  @override
  List<Object> get props => [setsToWin];
}

// Event when the user changes the player receiving the handicap
class HandicapPlayerChanged extends TeamSetupEvent {
  final int playerIndex;
  const HandicapPlayerChanged(this.playerIndex);
  @override
  List<Object> get props => [playerIndex];
}

// Event when the handicap points slider is changed
class HandicapPointsChanged extends TeamSetupEvent {
  final double points;
  const HandicapPointsChanged(this.points);
  @override
  List<Object> get props => [points];
}

// Event when user presses the "Start Match" button
class StartMatchSubmitted extends TeamSetupEvent {}
