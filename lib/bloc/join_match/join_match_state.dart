part of 'join_match_bloc.dart';

abstract class JoinMatchState extends Equatable {
  const JoinMatchState();

  @override
  List<Object> get props => [];
}

class JoinMatchInitial extends JoinMatchState {}

class JoinMatchLoading extends JoinMatchState {}

class JoinMatchSuccess extends JoinMatchState {
  final MatchBloc matchBloc;

  const JoinMatchSuccess({required this.matchBloc});

  @override
  List<Object> get props => [matchBloc];
}

class JoinMatchFailure extends JoinMatchState {
  final String error;

  const JoinMatchFailure(this.error);

  @override
  List<Object> get props => [error];
}
