import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/player.dart';
import '../models/set_score.dart';
import '../models/team.dart';
import '../shared/configuration.dart';

class MatchController extends ChangeNotifier {
  final String matchId;
  final Team home;
  final Team away;
  final bool isObserver;

  late final CollectionReference _matchesCollection;
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

  bool isTimeoutActive = false;
  bool timeoutCalledByHome = false;
  Duration? remainingTimeoutTime;
  Timer? _timeoutTimer;

  int matchGamesWonHome = 0;
  int matchGamesWonAway = 0;

  bool isTransitioning = false;
  bool isNextGameReady = false;
  Game? nextGamePreview;

  VoidCallback? onDoublesPlayersNeeded;
  VoidCallback? onServerSelectionNeeded;
  VoidCallback? onMatchDeleted;

  MatchController({
    required this.home,
    required this.away,
    required this.matchId,
    this.isObserver = false,
  }) {
    _matchesCollection = FirebaseFirestore.instance.collection('matches');
    _initializeGames();
    _loadGame(0);
    if (!isObserver) {
      createMatchInFirestore();
    }
    _listenToFirestore();
  }

  void _initializeGames() {
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

    games = [];
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
      'currentServer': currentServer?.name,
      'currentReceiver': currentReceiver?.name,
      'serveCount': serveCount,
      'deuce': deuce,
    };
  }

  void _updateFromMap(Map<String, dynamic> data) {
    matchGamesWonHome = data['matchGamesWonHome'] ?? matchGamesWonHome;
    matchGamesWonAway = data['matchGamesWonAway'] ?? matchGamesWonAway;

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
    if (isObserver || isBreakActive || isTimeoutActive || currentSet.home == 0)
      return;
    currentSet.home--;
    _pushToFirestore();
    notifyListeners();
  }

  void undoPointAway() {
    if (isObserver || isBreakActive || isTimeoutActive || currentSet.away == 0)
      return;
    currentSet.away--;
    _pushToFirestore();
    notifyListeners();
  }

  void _afterPoint() {
    serveCount++;
    _maybeRotateServer();
    _checkSetEnd();
    _pushToFirestore();
    notifyListeners();
  }

  void _checkSetEnd() {
    final home = currentSet.home;
    final away = currentSet.away;

    if ((home >= 11 || away >= 11) && (home - away).abs() >= 2) {
      if (home > away) {
        currentGame.setsWonHome++;
      } else {
        currentGame.setsWonAway++;
      }

      if (isCurrentGameCompleted) {
        _completeGame();
      } else {
        startBreak();
      }
    }
  }

  bool get isCurrentGameCompleted =>
      currentGame.setsWonHome == 3 || currentGame.setsWonAway == 3;

  bool get isGameEditable =>
      !isCurrentGameCompleted && !isBreakActive && !isTimeoutActive;

  bool get isMatchOver => matchGamesWonHome == 5 || matchGamesWonAway == 5;

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

  void _maybeRotateServer() {
    deuce = currentSet.home >= 10 && currentSet.away >= 10;
    if (serveCount >= (deuce ? 1 : 2)) {
      serveCount = 0;
      currentGame.isDoubles ? _rotateDoublesServer() : _swapServerSingles();
    }
  }

  void _swapServerSingles() {
    final temp = currentServer;
    currentServer = currentReceiver;
    currentReceiver = temp;
  }

  void _rotateDoublesServer() {
    if (currentGame.homePlayers.length < 2 ||
        currentGame.awayPlayers.length < 2)
      return;

    final h1 = currentGame.homePlayers[0];
    final h2 = currentGame.homePlayers[1];
    final a1 = currentGame.awayPlayers[0];
    final a2 = currentGame.awayPlayers[1];

    final sequence = [
      [h1, a1],
      [a1, h2],
      [h2, a2],
      [a2, h1],
    ];

    int index = sequence.indexWhere(
      (pair) => pair[0] == currentServer && pair[1] == currentReceiver,
    );

    if (index != -1) {
      int nextIndex = (index + 1) % sequence.length;
      currentServer = sequence[nextIndex][0];
      currentReceiver = sequence[nextIndex][1];
    }
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
      currentGame.sets.add(SetScore());
      currentSet = currentGame.sets.last;
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
        (!isHome && currentGame.awayTimeoutUsed))
      return;

    isTimeoutActive = true;
    timeoutCalledByHome = isHome;
    remainingTimeoutTime = Duration(seconds: TableTennisConfig.timeoutTimer);

    if (isHome)
      currentGame.homeTimeoutUsed = true;
    else
      currentGame.awayTimeoutUsed = true;

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

    if (!isMatchOver && currentGame.order < games.length) {
      nextGamePreview = games[currentGame.order];
      isTransitioning = true;
      isNextGameReady = true;
    }
    notifyListeners();
  }

  void startNextGame() {
    if (nextGamePreview == null || isObserver) return;

    isTransitioning = false;
    isNextGameReady = false;
    _loadGame(nextGamePreview!.order - 1);
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
  }

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

  Future<void> deleteMatch() async {
    if (isObserver) return;
    await _matchesCollection.doc(matchId).delete();
  }

  @override
  void dispose() {
    _breakTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }
}
