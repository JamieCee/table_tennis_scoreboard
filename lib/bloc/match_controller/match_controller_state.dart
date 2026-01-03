part of 'match_controller_bloc.dart';

class MatchControllerState {
  final String matchId;
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

  final int pointsToWin;
  final int servesPerTurn;
  final Team home;
  final Team away;
  final MatchType matchType;
  final int setsToWin;
  final bool isObserver;
  final Map<String, int>? handicapDetails;

  MatchControllerState({
    required this.matchId,
    required this.games,
    required this.currentGame,
    required this.currentSet,
    required this.currentServer,
    required this.currentReceiver,
    required this.serveCount,
    required this.deuce,
    required this.isBreakActive,
    required this.remainingBreakTime,
    required this.isTimeoutActive,
    required this.timeoutCalledByHome,
    required this.remainingTimeoutTime,
    required this.matchGamesWonHome,
    required this.matchGamesWonAway,
    required this.isTransitioning,
    required this.isNextGameReady,
    required this.nextGamePreview,
    required this.lastGameResult,
    required this.pointsToWin,
    required this.servesPerTurn,
    required this.home,
    required this.away,
    required this.matchType,
    required this.setsToWin,
    required this.isObserver,
    required this.handicapDetails,
  });

  factory MatchControllerState.initial({
    required Team home,
    required Team away,
    required MatchType matchType,
    required int setsToWin,
    required bool isObserver,
    Map<String, int>? handicapDetails,
  }) {
    int points = (matchType == MatchType.handicap) ? 21 : 11;
    int serves = (matchType == MatchType.handicap) ? 5 : 2;

    return MatchControllerState(
      matchId: '',
      games: [],
      currentGame: null,
      currentSet: null,
      currentServer: null,
      currentReceiver: null,
      serveCount: 0,
      deuce: false,
      isBreakActive: false,
      remainingBreakTime: null,
      isTimeoutActive: false,
      timeoutCalledByHome: false,
      remainingTimeoutTime: null,
      matchGamesWonHome: 0,
      matchGamesWonAway: 0,
      isTransitioning: false,
      isNextGameReady: false,
      nextGamePreview: null,
      lastGameResult: null,
      pointsToWin: points,
      servesPerTurn: serves,
      home: home,
      away: away,
      matchType: matchType,
      setsToWin: setsToWin,
      isObserver: isObserver,
      handicapDetails: handicapDetails,
    );
  }

  MatchControllerState copyWith({
    String? matchId,
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
    int? pointsToWin,
    int? servesPerTurn,
  }) {
    return MatchControllerState(
      matchId: matchId ?? this.matchId,
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
      pointsToWin: pointsToWin ?? this.pointsToWin,
      servesPerTurn: servesPerTurn ?? this.servesPerTurn,
      home: home,
      away: away,
      matchType: matchType,
      setsToWin: setsToWin,
      isObserver: isObserver,
      handicapDetails: handicapDetails,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'home': {
        'name': home.name,
        'players': home.players.map((p) => p.name).toList(),
      },
      'away': {
        'name': away.name,
        'players': away.players.map((p) => p.name).toList(),
      },
      'matchType': matchType.toString(),
      'setsToWin': setsToWin,
      'currentGameIndex': currentGame != null ? games.indexOf(currentGame!) : 0,
      'matchGamesWonHome': matchGamesWonHome,
      'matchGamesWonAway': matchGamesWonAway,
      'games': games.map((g) => g.toMap()).toList(),
      'break': {
        'isActive': isBreakActive,
        'remainingSeconds': remainingBreakTime?.inSeconds ?? 0,
      },
      'timeout': {
        'isActive': isTimeoutActive,
        'team': timeoutCalledByHome ? 'home' : 'away',
        'remainingSeconds': remainingTimeoutTime?.inSeconds ?? 0,
      },
      'isTransitioning': isTransitioning,
      'isNextGameReady': isNextGameReady,
      'lastGameResult': lastGameResult,
      'currentServer': currentServer?.name,
      'currentReceiver': currentReceiver?.name,
      'serveCount': serveCount,
      'deuce': deuce,
    };
  }

  bool get isCurrentGameCompleted =>
      currentGame != null &&
      (currentGame!.setsWonHome == setsToWin ||
          currentGame!.setsWonAway == setsToWin);

  bool get isGameEditable =>
      !isCurrentGameCompleted && !isBreakActive && !isTimeoutActive;

  bool get isMatchOver {
    if (matchType == MatchType.singles || matchType == MatchType.handicap) {
      return matchGamesWonHome > 0 || matchGamesWonAway > 0;
    }
    final completedGames = matchGamesWonHome + matchGamesWonAway;
    return completedGames >= games.length;
  }
}
