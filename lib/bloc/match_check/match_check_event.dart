part of 'match_check_bloc.dart';

abstract class MatchCheckEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckForActiveMatch extends MatchCheckEvent {}

class DiscardActiveMatch extends MatchCheckEvent {
  final String matchId;
  DiscardActiveMatch({required this.matchId});

  @override
  List<Object> get props => [matchId];
}
