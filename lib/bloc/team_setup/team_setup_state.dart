// lib/bloc/team_setup/team_setup_state.dart
part of 'team_setup_bloc.dart';

// Enum to represent the status of the form submission
enum TeamSetupStatus { initial, loading, success, failure }

class TeamSetupState extends Equatable {
  // Define the initial state of the form
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
    this.matchController,
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
  final MatchController? matchController; // Will hold the controller on success
  final String? errorMessage;

  // A 'copyWith' method makes it easy to create a new state based on the old one
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
    ValueGetter<MatchController?>? matchController,
    ValueGetter<String?>? errorMessage,
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
      matchController: matchController != null
          ? matchController()
          : this.matchController,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
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
    matchController,
    errorMessage,
  ];
}
