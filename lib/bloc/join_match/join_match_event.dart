part of 'join_match_bloc.dart';

abstract class JoinMatchEvent extends Equatable {
  const JoinMatchEvent();

  @override
  List<Object> get props => [];
}

// Event dispatched when the user presses the "Join Match" button.
class JoinMatchRequested extends JoinMatchEvent {
  final String matchId;

  const JoinMatchRequested({required this.matchId});

  @override
  List<Object> get props => [matchId];
}
