part of 'team_setup_bloc.dart';

enum TeamSetupStatus { initial, loading, success, failure }

class TeamSetupState extends Equatable {
  const TeamSetupState({
    this.status = TeamSetupStatus.initial,
    this.matchType = MatchType.team,
    this.setsToWin = 3,
    this.handicapPlayerIndex = 0,
    this.handicapPoints = 0.0,
    this.homeTeamName = 'Home Team',
    this.awayTeamName = 'Away Team',
    this.homePlayerNames = const ['', '', ''],
    this.awayPlayerNames = const ['', '', ''],
    this.matchBloc,
    this.errorMessage,
  });

  final TeamSetupStatus status;
  final MatchType matchType;
  final int setsToWin;
  final int handicapPlayerIndex;
  final double handicapPoints;
  final String homeTeamName;
  final String awayTeamName;
  final List<String> homePlayerNames;
  final List<String> awayPlayerNames;
  final MatchBloc? matchBloc; // <-- updated to MatchBloc
  final String? errorMessage;

  TeamSetupState copyWith({
    TeamSetupStatus? status,
    MatchType? matchType,
    int? setsToWin,
    int? handicapPlayerIndex,
    double? handicapPoints,
    String? homeTeamName,
    String? awayTeamName,
    List<String>? homePlayerNames,
    List<String>? awayPlayerNames,
    MatchBloc? matchBloc, // <-- updated
    String? errorMessage,
  }) {
    return TeamSetupState(
      status: status ?? this.status,
      matchType: matchType ?? this.matchType,
      setsToWin: setsToWin ?? this.setsToWin,
      handicapPlayerIndex: handicapPlayerIndex ?? this.handicapPlayerIndex,
      handicapPoints: handicapPoints ?? this.handicapPoints,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      homePlayerNames: homePlayerNames ?? this.homePlayerNames,
      awayPlayerNames: awayPlayerNames ?? this.awayPlayerNames,
      matchBloc: matchBloc ?? this.matchBloc,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    matchType,
    setsToWin,
    handicapPlayerIndex,
    handicapPoints,
    homeTeamName,
    awayTeamName,
    homePlayerNames,
    awayPlayerNames,
    matchBloc,
    errorMessage,
  ];
}
