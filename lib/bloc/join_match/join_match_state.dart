part of 'join_match_bloc.dart';

abstract class JoinMatchState extends Equatable {
  const JoinMatchState();

  @override
  List<Object> get props => [];
}

// The screen's initial state.
class JoinMatchInitial extends JoinMatchState {}

// State when the app is actively trying to join the match.
class JoinMatchLoading extends JoinMatchState {}

// State when the match is successfully found and joined.
// It will hold the MatchController needed for navigation.
class JoinMatchSuccess extends JoinMatchState {
  final MatchController controller;

  const JoinMatchSuccess({required this.controller});

  @override
  List<Object> get props => [controller];
}

// State for when any error occurs (match not found, network error, etc.).
class JoinMatchFailure extends JoinMatchState {
  final String error;

  const JoinMatchFailure(this.error);

  @override
  List<Object> get props => [error];
}
