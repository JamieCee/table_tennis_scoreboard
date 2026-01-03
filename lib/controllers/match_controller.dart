import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ✅ 1. Import the new MatchStateManager
import 'package:table_tennis_scoreboard/services/match_state_manager.dart';

import '../models/game.dart';
import '../models/player.dart';
import '../models/set_score.dart';
import '../models/team.dart';
import '../shared/configuration.dart';

enum MatchType { singles, team, handicap }

class MatchController extends ChangeNotifier {
  final String matchId;
  final Team home;
  final Team away;
  final bool isObserver;
  final MatchType matchType;
  final int setsToWin;

  late final CollectionReference _matchesCollection;
  // ✅ 2. Add MatchStateManager as a final property
  final MatchStateManager _matchStateManager;

  late List<Game> games;
  late Game currentGame;
  late SetScore currentSet;

  Player? currentServer;
  Player? currentReceiver;
  int serveCount = 0;
  bool deuce = false;

  Duration breakDuration = Duration(seconds: TableTennisConfig.setBreak);
  Duration? remainingBreakTime;
  bool isBreakActive = false;
  Timer? _breakTimer;
  VoidCallback? onBreakStarted;
  VoidCallback? onBreakEnded;

  bool _isFirstLoad = false;

  bool isTimeoutActive = false;
  bool timeoutCalledByHome = false;
  Duration? remainingTimeoutTime;
  Timer? _timeoutTimer;

  int matchGamesWonHome = 0;
  int matchGamesWonAway = 0;

  bool isTransitioning = false;
  bool isNextGameReady = false;
  Game? nextGamePreview;
  Map<String, dynamic>? lastGameResult;

  VoidCallback? onDoublesPlayersNeeded;
  VoidCallback? onServerSelectionNeeded;
  VoidCallback? onMatchDeleted;
  VoidCallback? onNextGameStarted;

  final Map<String, int>? handicapDetails;
  late final int pointsToWin;
  late final int _servesPerTurn;

  void Function(Map<String, int> finalScore, List<Map<String, int>> setScores)?
  onGameFinished;

  MatchController({
    required this.home,
    required this.away,
    required this.matchId,
    this.isObserver = false,
    this.matchType = MatchType.team,
    this.setsToWin = 3,
    this.handicapDetails,
    // ✅ 3. Require MatchStateManager in the constructor
    required MatchStateManager matchStateManager,
  }) : _matchStateManager = matchStateManager {
    _isFirstLoad = false;
    _initializeRules();
    _matchesCollection = FirebaseFirestore.instance.collection('matches');
    _initializeGames();
    _loadGame(0);
    if (!isObserver) {
      _matchStateManager.startControlling();
      createMatchInFirestore();
    }
    _listenToFirestore();
  }

  MatchController.resume({
    required this.home,
    required this.away,
    required this.matchId,
    required this.isObserver,
    required this.matchType,
    required this.setsToWin,
    this.handicapDetails,
    required Map<String, dynamic> resumeData,
    // ✅ 4. Require MatchStateManager in the resume constructor as well
    required MatchStateManager matchStateManager,
  }) : _matchStateManager = matchStateManager {
    _isFirstLoad = true;
    _initializeRules();

    _matchesCollection = FirebaseFirestore.instance.collection('matches');

    if (resumeData['games'] != null) {
      games = (resumeData['games'] as List)
          .map((gameData) => Game.fromJson(gameData))
          .toList();
    } else {
      _initializeGames();
    }

    final savedGameIndex = resumeData['currentGameIndex'] as int? ?? 0;
    _loadGame(savedGameIndex);

    final serverName = resumeData['currentServer'] as String?;
    if (serverName != null) {
      currentServer = Player(serverName);
    }

    final receiverName = resumeData['currentReceiver'] as String?;
    if (receiverName != null) {
      currentReceiver = Player(receiverName);
    }
    serveCount = resumeData['serveCount'] as int? ?? 0;
    deuce = resumeData['deuce'] as bool? ?? false;

    if (!isObserver) {
      _matchStateManager.startControlling();
    }
    _listenToFirestore();
  }

  void _initializeRules() {
    if (matchType == MatchType.handicap) {
      pointsToWin = 21;
      _servesPerTurn = 5;
    } else {
      pointsToWin = 11;
      _servesPerTurn = 2;
    }
  }

  void _initializeGames() {
    games = [];
    Game game;

    if (matchType == MatchType.handicap || matchType == MatchType.singles) {
      game = Game(
        order: 1,
        isDoubles: false,
        homePlayers: [home.players[0]],
        awayPlayers: [away.players[0]],
      );
      game.sets.clear();
      currentGame = game;
      _createNewSet();
      games.add(game);
    } else {
      final playerCombinations = [
        [home.players[0]],
        [away.players[1]],
        [home.players[2]],
        [away.players[0]],
        [home.players[1]],
        [away.players[2]],
        [home.players[2]],
        [away.players[1]],
        [],
        [],
        [home.players[0]],
        [away.players[2]],
        [home.players[1]],
        [away.players[0]],
        [home.players[2]],
        [away.players[2]],
        [home.players[1]],
        [away.players[1]],
        [home.players[0]],
        [away.players[0]],
      ];

      for (int i = 0; i < playerCombinations.length; i += 2) {
        games.add(
          Game(
            order: (i ~/ 2) + 1,
            isDoubles: i == 8,
            homePlayers: List.from(playerCombinations[i]),
            awayPlayers: List.from(playerCombinations[i + 1]),
          ),
        );
      }
    }
  }

  void _loadGame(int index) {
    if (index < 0 || index >= games.length) return;
    currentGame = games[index];
    if (currentGame.sets.isEmpty) {
      currentGame.sets.add(SetScore());
    }
    currentSet = currentGame.sets.last;
    currentServer = null;
    currentReceiver = null;
    serveCount = 0;
    deuce = false;
    notifyListeners();
  }

  Future<void> createMatchInFirestore() async {
    await _matchesCollection.doc(matchId).set(toMap());
  }

  void _listenToFirestore() {
    _matchesCollection.doc(matchId).snapshots().listen((snapshot) {
      if (!snapshot.exists) {
        onMatchDeleted?.call();
        return;
      }
      final data = snapshot.data() as Map<String, dynamic>;
      _updateFromMap(data);
    });
  }

  void _pushToFirestore() {
    if (isObserver) return;
    _matchesCollection.doc(matchId).set(toMap(), SetOptions(merge: true));
  }

  Future<void> deleteMatch() async {
    if (isObserver) return;
    // ✅ 5. Notify the manager before deleting
    _matchStateManager.stopControlling();
    await _matchesCollection.doc(matchId).delete();
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
      'currentGameIndex': games.indexOf(currentGame),
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

  void _updateFromMap(Map<String, dynamic> data) {
    matchGamesWonHome = data['matchGamesWonHome'] ?? matchGamesWonHome;
    matchGamesWonAway = data['matchGamesWonAway'] ?? matchGamesWonAway;
    isTransitioning = data['isTransitioning'] ?? isTransitioning;
    isNextGameReady = data['isNextGameReady'] ?? isNextGameReady;
    lastGameResult = data['lastGameResult'] != null
        ? Map<String, dynamic>.from(data['lastGameResult'])
        : lastGameResult;

    final gamesData =
        (data['games'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (gamesData.isNotEmpty) {
      games = List.generate(
        gamesData.length,
        (i) => Game.fromMap(gamesData[i]),
      );
    }

    int gameIndex = data['currentGameIndex'] ?? 0;
    if (games.isNotEmpty) {
      gameIndex = gameIndex.clamp(0, games.length - 1);
      currentGame = games[gameIndex];
      if (currentGame.sets.isEmpty) currentGame.sets.add(SetScore());
      currentSet = currentGame.sets.last;
    }

    final breakData = data['break'] as Map<String, dynamic>? ?? {};
    isBreakActive = breakData['isActive'] ?? false;

    final timeoutData = data['timeout'] as Map<String, dynamic>? ?? {};
    isTimeoutActive = timeoutData['isActive'] ?? false;
    timeoutCalledByHome = timeoutData['team'] == 'home';

    if (isObserver) {
      remainingBreakTime = Duration(
        seconds: breakData['remainingSeconds'] ?? 0,
      );
      remainingTimeoutTime = Duration(
        seconds: timeoutData['remainingSeconds'] ?? 0,
      );
    }

    if (_isFirstLoad) {
      _isFirstLoad = false;
      notifyListeners();
      return;
    }

    currentServer = data['currentServer'] != null
        ? Player(data['currentServer']!)
        : null;
    currentReceiver = data['currentReceiver'] != null
        ? Player(data['currentReceiver']!)
        : null;
    serveCount = data['serveCount'] ?? serveCount;
    deuce = data['deuce'] ?? deuce;

    notifyListeners();
  }

  void addPointHome() {
    if (isObserver || isBreakActive || isTimeoutActive) return;
    currentSet.home++;
    _afterPoint();
  }

  void addPointAway() {
    if (isObserver || isBreakActive || isTimeoutActive) return;
    currentSet.away++;
    _afterPoint();
  }

  void undoPointHome() {
    if (isObserver ||
        isBreakActive ||
        isTimeoutActive ||
        currentSet.home == 0) {
      return;
    }
    currentSet.home--;
    _pushToFirestore();
    notifyListeners();
  }

  void undoPointAway() {
    if (isObserver ||
        isBreakActive ||
        isTimeoutActive ||
        currentSet.away == 0) {
      return;
    }
    currentSet.away--;
    _pushToFirestore();
    notifyListeners();
  }

  void _afterPoint() {
    _maybeRotateServer();
    _checkSetEnd();
    _pushToFirestore();
    notifyListeners();
  }

  void _checkSetEnd() {
    final home = currentSet.home;
    final away = currentSet.away;

    if (matchType == MatchType.handicap && home >= 20 && home == away) {
      deuce = true;
    }

    if ((home >= pointsToWin || away >= pointsToWin) &&
        (home - away).abs() >= 2) {
      if (home > away) {
        currentGame.setsWonHome++;
      } else {
        currentGame.setsWonAway++;
      }
      deuce = false;
      if (isCurrentGameCompleted) {
        _completeGame();
      } else {
        startBreak();
      }
    }
  }

  bool get isCurrentGameCompleted =>
      currentGame.setsWonHome == setsToWin ||
      currentGame.setsWonAway == setsToWin;

  bool get isGameEditable =>
      !isCurrentGameCompleted && !isBreakActive && !isTimeoutActive;

  bool get isMatchOver {
    if (matchType == MatchType.singles || matchType == MatchType.handicap) {
      return matchGamesWonHome > 0 || matchGamesWonAway > 0;
    }
    final completedGames = matchGamesWonHome + matchGamesWonAway;
    return completedGames >= games.length;
  }

  void setServer(Player? server, Player? receiver) {
    if (isObserver) return;
    currentGame.startingServer = server;
    currentGame.startingReceiver = receiver;
    _setFirstServerOfSet();
    _pushToFirestore();
  }

  void _setFirstServerOfSet() {
    final server = currentGame.startingServer;
    final receiver = currentGame.startingReceiver;
    if (server == null || receiver == null) return;

    if (!currentGame.isDoubles && (currentGame.sets.length - 1) % 2 != 0) {
      currentServer = receiver;
      currentReceiver = server;
    } else {
      currentServer = server;
      currentReceiver = receiver;
    }
    serveCount = 0;
  }

  void _createNewSet() {
    final newSet = SetScore();
    if (matchType == MatchType.handicap && handicapDetails != null) {
      final playerIndex = handicapDetails!['playerIndex']!;
      final points = handicapDetails!['points']!;
      if (playerIndex == 0) {
        newSet.home = points;
      } else {
        newSet.away = points;
      }
    }
    currentGame.sets.add(newSet);
    currentSet = currentGame.sets.last;
  }

  void _maybeRotateServer() {
    final totalPoints = currentSet.home + currentSet.away;
    final deuceThreshold = (matchType == MatchType.handicap) ? 20 : 10;
    deuce =
        currentSet.home >= deuceThreshold && currentSet.away >= deuceThreshold;

    if (deuce) {
      _swapServerSingles();
      return;
    }
    if (totalPoints > 0 && totalPoints % _servesPerTurn == 0) {
      _swapServerSingles();
    }
  }

  void _swapServerSingles() {
    final temp = currentServer;
    currentServer = currentReceiver;
    currentReceiver = temp;
  }

  void startBreak() {
    if (isObserver) return;
    remainingBreakTime = breakDuration;
    isBreakActive = true;
    onBreakStarted?.call();

    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingBreakTime == null || remainingBreakTime!.inSeconds <= 0) {
        timer.cancel();
        endBreak();
      } else {
        remainingBreakTime = remainingBreakTime! - const Duration(seconds: 1);
        _pushToFirestore();
        notifyListeners();
      }
    });
    _pushToFirestore();
    notifyListeners();
  }

  void endBreak() {
    _breakTimer?.cancel();
    _breakTimer = null;
    isBreakActive = false;
    remainingBreakTime = null;
    onBreakEnded?.call();
    if (!isObserver && !isCurrentGameCompleted) {
      _createNewSet();
      _setFirstServerOfSet();
    }
    if (!isObserver) _pushToFirestore();
    notifyListeners();
  }

  void endBreakEarly() {
    if (isObserver) return;
    endBreak();
  }

  void startTimeout({required bool isHome}) {
    if (isObserver || isTimeoutActive) return;
    if ((isHome && currentGame.homeTimeoutUsed) ||
        (!isHome && currentGame.awayTimeoutUsed)) {
      return;
    }

    isTimeoutActive = true;
    timeoutCalledByHome = isHome;
    remainingTimeoutTime = Duration(seconds: TableTennisConfig.timeoutTimer);

    if (isHome) {
      currentGame.homeTimeoutUsed = true;
    } else {
      currentGame.awayTimeoutUsed = true;
    }

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTimeoutTime == null ||
          remainingTimeoutTime!.inSeconds <= 0) {
        timer.cancel();
        endTimeout();
      } else {
        remainingTimeoutTime =
            remainingTimeoutTime! - const Duration(seconds: 1);
        _pushToFirestore();
        notifyListeners();
      }
    });
    _pushToFirestore();
    notifyListeners();
  }

  void endTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    isTimeoutActive = false;
    remainingTimeoutTime = null;
    if (!isObserver) _pushToFirestore();
    notifyListeners();
  }

  void endTimeoutEarly() {
    if (isObserver) return;
    endTimeout();
  }

  void _completeGame() {
    if (currentGame.setsWonHome > currentGame.setsWonAway) {
      matchGamesWonHome++;
    } else {
      matchGamesWonAway++;
    }
    List<Map<String, int>> setScores = currentGame.sets
        .map((s) => {'home': s.home, 'away': s.away})
        .toList();
    lastGameResult = {
      'homeScore': currentGame.setsWonHome,
      'awayScore': currentGame.setsWonAway,
      'setScores': setScores,
    };
    onGameFinished?.call({
      'home': currentGame.setsWonHome,
      'away': currentGame.setsWonAway,
    }, setScores);

    if (!isMatchOver && currentGame.order < games.length) {
      nextGamePreview = games[currentGame.order];
      isTransitioning = true;
      isNextGameReady = true;
    } else if (isMatchOver) {
      // ✅ 6. Notify the manager when the match is officially over
      _matchStateManager.stopControlling();
      _clearActiveMatchId();
    }
    _pushToFirestore();
    notifyListeners();
  }

  Future<void> _clearActiveMatchId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeMatchId');
  }

  // ✅ 7. RESTORED: nextGame getter
  Game? get nextGame {
    final currentIndex = games.indexOf(currentGame);
    if (currentIndex == -1 || currentIndex + 1 >= games.length) return null;
    return games[currentIndex + 1];
  }

  // ✅ 8. RESTORED: startNextGame method
  void startNextGame() {
    if (nextGamePreview == null || isObserver) return;

    isTransitioning = false;
    isNextGameReady = false;
    lastGameResult = null;

    _loadGame(nextGamePreview!.order - 1); // 1-based to 0-based
    nextGamePreview = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentGame.isDoubles && currentGame.homePlayers.isEmpty) {
        onDoublesPlayersNeeded?.call();
      } else if (currentGame.startingServer == null) {
        onServerSelectionNeeded?.call();
      }
    });
    _pushToFirestore();
    notifyListeners();
    onNextGameStarted?.call();
  }

  // ✅ 9. RESTORED: setDoublesPlayers method
  void setDoublesPlayers(List<Player> home, List<Player> away) {
    if (isObserver) return;
    currentGame.homePlayers = home;
    currentGame.awayPlayers = away;
    _pushToFirestore();
    notifyListeners();
  }

  void setDoublesStartingServer(Player server, Player receiver) {
    if (isObserver) return;
    setServer(server, receiver);
  }

  @override
  void dispose() {
    // ✅ 10. Ensure manager is notified on dispose as a fallback
    _matchStateManager.stopControlling();
    _breakTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }
}
