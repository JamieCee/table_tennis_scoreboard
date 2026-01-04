part of 'match_bloc.dart';

class MatchState extends Equatable {
  final List<Game> games;
  final Game? currentGame;
  final SetScore? currentSet;

  final Player? currentServer;
  final Player? currentReceiver;
  final int serveCount;
  final bool deuce;

  final bool isBreakActive;
  final Duration? remainingBreakTime;

  final bool isTimeoutActive;
  final bool timeoutCalledByHome;
  final Duration? remainingTimeoutTime;

  final int matchGamesWonHome;
  final int matchGamesWonAway;

  final bool isTransitioning;
  final bool isNextGameReady;
  final Game? nextGamePreview;
  final Map<String, dynamic>? lastGameResult;

  final int setsToWin;
  final MatchType matchType;
  final int pointsToWin;

  // bool get isMatchOver {
  //   if (currentGame == null) return false;
  //   final requiredSets = 3;
  //   return currentGame!.setsWonHome >= requiredSets ||
  //       currentGame!.setsWonAway >= requiredSets;
  // }
  final bool isMatchOver;

  bool get isGameEditable {
    final game = currentGame;
    if (game == null) return false;

    // Game is editable if it's not finished, and no break/timeout is active
    return !isBreakActive && !isTimeoutActive && !isMatchOver;
  }

  Game? get nextGame => nextGamePreview;

  const MatchState({
    required this.games,
    this.currentGame,
    this.currentSet,
    this.currentServer,
    this.currentReceiver,
    this.serveCount = 0,
    this.deuce = false,
    this.isBreakActive = false,
    this.remainingBreakTime,
    this.isTimeoutActive = false,
    this.timeoutCalledByHome = false,
    this.remainingTimeoutTime,
    this.matchGamesWonHome = 0,
    this.matchGamesWonAway = 0,
    this.isTransitioning = false,
    this.isNextGameReady = false,
    this.nextGamePreview,
    this.lastGameResult,
    this.matchType = MatchType.team,
    this.setsToWin = 3,
    this.pointsToWin = 4,
    this.isMatchOver = false,
  });

  factory MatchState.initial() {
    return const MatchState(games: []);
  }

  MatchState copyWith({
    List<Game>? games,
    Game? currentGame,
    SetScore? currentSet,
    Player? currentServer,
    Player? currentReceiver,
    int? serveCount,
    bool? deuce,
    bool? isBreakActive,
    Duration? remainingBreakTime,
    bool? isTimeoutActive,
    bool? timeoutCalledByHome,
    Duration? remainingTimeoutTime,
    int? matchGamesWonHome,
    int? matchGamesWonAway,
    bool? isTransitioning,
    bool? isNextGameReady,
    Game? nextGamePreview,
    Map<String, dynamic>? lastGameResult,
    MatchType? matchType,
    int? setsToWin,
    int? pointsToWin,
    bool? isMatchOver,
  }) {
    return MatchState(
      games: games ?? this.games,
      currentGame: currentGame ?? this.currentGame,
      currentSet: currentSet ?? this.currentSet,
      currentServer: currentServer ?? this.currentServer,
      currentReceiver: currentReceiver ?? this.currentReceiver,
      serveCount: serveCount ?? this.serveCount,
      deuce: deuce ?? this.deuce,
      isBreakActive: isBreakActive ?? this.isBreakActive,
      remainingBreakTime: remainingBreakTime ?? this.remainingBreakTime,
      isTimeoutActive: isTimeoutActive ?? this.isTimeoutActive,
      timeoutCalledByHome: timeoutCalledByHome ?? this.timeoutCalledByHome,
      remainingTimeoutTime: remainingTimeoutTime ?? this.remainingTimeoutTime,
      matchGamesWonHome: matchGamesWonHome ?? this.matchGamesWonHome,
      matchGamesWonAway: matchGamesWonAway ?? this.matchGamesWonAway,
      isTransitioning: isTransitioning ?? this.isTransitioning,
      isNextGameReady: isNextGameReady ?? this.isNextGameReady,
      nextGamePreview: nextGamePreview ?? this.nextGamePreview,
      lastGameResult: lastGameResult ?? this.lastGameResult,
      matchType: matchType ?? this.matchType,
      setsToWin: setsToWin ?? this.setsToWin,
      pointsToWin: pointsToWin ?? this.pointsToWin,
      isMatchOver: isMatchOver ?? this.isMatchOver,
    );
  }

  @override
  List<Object?> get props => [
    games,
    currentGame,
    currentSet,
    currentServer,
    currentReceiver,
    serveCount,
    deuce,
    isBreakActive,
    remainingBreakTime,
    isTimeoutActive,
    timeoutCalledByHome,
    remainingTimeoutTime,
    matchGamesWonHome,
    matchGamesWonAway,
    isTransitioning,
    isNextGameReady,
    nextGamePreview,
    lastGameResult,
    matchType,
    setsToWin,
    pointsToWin,
    isMatchOver,
  ];
}
