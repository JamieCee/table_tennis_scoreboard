import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }) {
    _initializeRules();
    _matchesCollection = FirebaseFirestore.instance.collection('matches');
    _initializeGames();
    _loadGame(0);
    if (!isObserver) {
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
    required Map<String, dynamic> resumeData, // Pass the Firestore data here
  }) {
    _initializeRules();

    _matchesCollection = FirebaseFirestore.instance.collection('matches');

    // 1. Rebuild the games list from the saved data
    if (resumeData['games'] != null) {
      games = (resumeData['games'] as List)
          .map((gameData) => Game.fromJson(gameData))
          .toList();
    } else {
      // Fallback if games data is missing
      _initializeGames();
    }

    // 2. Load the correct game and set based on saved index
    final savedGameIndex = resumeData['currentGameIndex'] as int? ?? 0;
    _loadGame(savedGameIndex);

    // 3. Now, restore the server and receiver from the saved data.
    //    This overrides the 'null' values set by _loadGame.
    final serverName = resumeData['currentServer'] as String?;
    if (serverName != null) {
      currentServer = Player(serverName);
    }

    final receiverName = resumeData['currentReceiver'] as String?;
    if (receiverName != null) {
      currentReceiver = Player(receiverName);
    }

    // Restore serve count
    serveCount = resumeData['serveCount'] as int? ?? 0;

    // Restore deuce status
    deuce = resumeData['deuce'] as bool? ?? false;

    // DO NOT call createMatchInFirestore(). The match already exists.
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
      // This block now handles both singles and handicap setup.
      game = Game(
        order: 1,
        isDoubles: false,
        homePlayers: [home.players[0]],
        awayPlayers: [away.players[0]],
      );

      // The Game() constructor adds a default 0-0 set. Remove it.
      game.sets.clear();

      // Now, add the first set using our single, reliable method.
      // We need to temporarily assign `currentGame` so `_createNewSet` works.
      currentGame = game;
      _createNewSet(); // This will add either a 0-0 set or a handicap set.

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
            isDoubles: i == 8, // doubles placeholder
            // isDoubles: false,
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
    // serveCount++;

    _maybeRotateServer();
    _checkSetEnd();
    _pushToFirestore();
    notifyListeners();
  }

  void _checkSetEnd() {
    final home = currentSet.home;
    final away = currentSet.away;

    // Check for deuce condition in a handicap game
    if (matchType == MatchType.handicap && home >= 20 && home == away) {
      deuce = true;
    }

    // Use _pointsToWin for dynamic win condition
    if ((home >= pointsToWin || away >= pointsToWin) &&
        (home - away).abs() >= 2) {
      if (home > away) {
        currentGame.setsWonHome++;
      } else {
        currentGame.setsWonAway++;
      }

      // Deuce is over when a set is won
      deuce = false;

      if (isCurrentGameCompleted) {
        _completeGame();
      } else {
        startBreak();
      }
    }
    // if ((home >= 11 || away >= 11) && (home - away).abs() >= 2) {
    //   if (home > away) {
    //     currentGame.setsWonHome++;
    //   } else {
    //     currentGame.setsWonAway++;
    //   }
    //
    //   if (isCurrentGameCompleted) {
    //     _completeGame();
    //   } else {
    //     startBreak();
    //   }
    // }
  }

  bool get isCurrentGameCompleted =>
      currentGame.setsWonHome == setsToWin ||
      currentGame.setsWonAway == setsToWin;

  bool get isGameEditable =>
      !isCurrentGameCompleted && !isBreakActive && !isTimeoutActive;

  bool get isMatchOver {
    if (matchType == MatchType.singles) {
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

  // helper method
  void _createNewSet() {
    final newSet = SetScore(); // Always start with a fresh SetScore object.

    // Apply handicap *only* if it's a handicap match.
    if (matchType == MatchType.handicap && handicapDetails != null) {
      final playerIndex = handicapDetails!['playerIndex']!;
      final points = handicapDetails!['points']!;

      if (playerIndex == 0) {
        // Home gets the head start
        newSet.home = points;
      } else {
        // Away gets the head start
        newSet.away = points;
      }
    }

    // Add the new set (either 0-0 or with a handicap) to the current game.
    currentGame.sets.add(newSet);
    currentSet =
        currentGame.sets.last; // Update the reference to the current set.
  }

  void _maybeRotateServer() {
    final totalPoints = currentSet.home + currentSet.away;

    // Deuce Logic (common for all match types, just the point threshold changes)
    final deuceThreshold = (matchType == MatchType.handicap) ? 20 : 10;
    deuce =
        currentSet.home >= deuceThreshold && currentSet.away >= deuceThreshold;

    if (deuce) {
      // In deuce, it's one serve each for all game types.
      _swapServerSingles();
      return; // Server is swapped every point, so we are done.
    }

    // Handicap serving logic (before deuce)
    if (matchType == MatchType.handicap) {
      // Swap servers every 5 points (e.g., after the 5th, 10th, 15th point etc.)
      if (totalPoints > 0 && totalPoints % 5 == 0) {
        _swapServerSingles();
      }
      return; // Handicap logic is handled, exit the function.
    }

    // Standard serving logic (for Team and Singles)
    if (totalPoints > 0 && totalPoints % 2 == 0) {
      // This is a simpler way to handle serve changes.
      // It swaps after 2, 4, 6, 8, etc. total points.
      _swapServerSingles();
    }
  }
  // void _maybeRotateServer() {
  //   deuce = currentSet.home >= 10 && currentSet.away >= 10;
  //   if (serveCount >= (deuce ? 1 : 2)) {
  //     serveCount = 0;
  //     currentGame.isDoubles ? _rotateDoublesServer() : _swapServerSingles();
  //   }
  // }

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
      // --- Replace the old logic with this single line ---
      _createNewSet(); // This correctly creates the next set.
      // ---
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
    List<Map<String, int>> setScores = [];

    setScores = currentGame.sets
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
    }

    if (!isObserver) {
      _clearActiveMatchId();
    }

    _pushToFirestore();
    notifyListeners();
  }

  Future<void> _clearActiveMatchId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeMatchId');
  }

  Game? get nextGame {
    final currentIndex = games.indexOf(currentGame);
    if (currentIndex == -1 || currentIndex + 1 >= games.length) return null;
    return games[currentIndex + 1];
  }

  void startNextGame() {
    if (nextGamePreview == null || isObserver) {
      return;
    }

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
    _breakTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }
}
