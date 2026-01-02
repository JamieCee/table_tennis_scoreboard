part of 'match_check_bloc.dart';

abstract class MatchCheckState extends Equatable {
  const MatchCheckState();
  @override
  List<Object?> get props => [];
}

// Initial state, nothing has happened yet
class MatchCheckInitial extends MatchCheckState {}

// State when checking is in progress
class MatchCheckInProgress extends MatchCheckState {}

// State when an active match is found
class ActiveMatchFound extends MatchCheckState {
  final String matchId;
  final Map<String, dynamic> matchData;

  const ActiveMatchFound({required this.matchId, required this.matchData});

  @override
  List<Object?> get props => [matchId, matchData];
}

// State when no active match is found
class NoActiveMatch extends MatchCheckState {}

// State when an error occurs
class MatchCheckError extends MatchCheckState {
  final String message;
  const MatchCheckError(this.message);

  @override
  List<Object> get props => [message];
}
