import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/game.dart';
import '../models/player.dart';
import '../models/set_score.dart';
import '../models/team.dart';

class MatchController extends ChangeNotifier {
  final Team home;
  final Team away;

  late List<Game> games;
  late Game currentGame;
  late SetScore currentSet;

  VoidCallback? onDoublesPlayersNeeded;
  VoidCallback? onServerSelectionNeeded;

  int matchGamesWonHome = 0;
  int matchGamesWonAway = 0;

  Player? currentServer;
  Player? currentReceiver;
  int serveCount = 0;
  bool deuce = false;

  Duration breakDuration = const Duration(minutes: 2); // configurable
  Duration? remainingBreakTime;
  bool isBreakActive = false;
  Timer? _breakTimer;

  VoidCallback? onBreakStarted;
  VoidCallback? onBreakEnded;

  MatchController({required this.home, required this.away}) {
    _initializeGames();
    _loadGame(0);
  }

  // ----------------------------------------------------
  // INITIALIZATION
  // ----------------------------------------------------
  void _initializeGames() {
    final List<List<Player>> playerCombinations = [
      [home.players[0]], [away.players[1]], // 1 v 2
      [home.players[2]], [away.players[0]], // 3 v 1
      [home.players[1]], [away.players[2]], // 2 v 3
      [home.players[2]], [away.players[1]], // 3 v 2
      [], [], // Game 5 = doubles
      [home.players[0]], [away.players[2]], // 1 v 3
      [home.players[1]], [away.players[0]], // 2 v 1
      [home.players[2]], [away.players[2]], // 3 v 3
      [home.players[1]], [away.players[1]], // 2 v 2
      [home.players[0]], [away.players[0]], // 1 v 1
    ];

    games = [];
    for (int i = 0; i < playerCombinations.length; i += 2) {
      games.add(
        Game(
          order: (i ~/ 2) + 1,
          isDoubles: i == 8, // Game 5 (index 8,9) is doubles
          homePlayers: List.from(playerCombinations[i]),
          awayPlayers: List.from(playerCombinations[i + 1]),
        ),
      );
    }
  }

  void _loadGame(int index) {
    currentGame = games[index];
    currentSet = currentGame.sets.last;

    serveCount = 0;
    deuce = false;
    currentServer = null;
    currentReceiver = null;

    if (currentGame.isDoubles) {
      if (currentGame.homePlayers.isEmpty) {
        onDoublesPlayersNeeded?.call();
        return;
      }
      if (currentGame.startingServer == null) {
        onServerSelectionNeeded?.call();
        return;
      }
    } else {
      if (currentGame.startingServer == null) {
        onServerSelectionNeeded?.call();
        return;
      }
    }

    _setFirstServerOfSet();

    // Adjust server rotation based on existing points
    int totalPoints = currentSet.home + currentSet.away;
    int tempServeCount = 0;

    for (var i = 0; i < totalPoints; i++) {
      tempServeCount++;
      final isDeuce = currentSet.home >= 10 && currentSet.away >= 10;
      final interval = isDeuce ? 1 : 2;

      if (tempServeCount >= interval) {
        tempServeCount = 0;
        if (currentGame.isDoubles) {
          _rotateDoublesServer();
        } else {
          _swapServerSingles();
        }
      }
    }

    serveCount = tempServeCount;
    notifyListeners();
  }

  // ----------------------------------------------------
  // CONTROL
  // ----------------------------------------------------
  void addPointHome() {
    if (isBreakActive) return;
    currentSet.home++;
    _afterPoint();
  }

  void addPointAway() {
    if (isBreakActive) return;
    currentSet.away++;
    _afterPoint();
  }

  void undoPointHome() {
    if (isBreakActive) return;
    if (currentSet.home > 0) currentSet.home--;
    notifyListeners();
  }

  void undoPointAway() {
    if (isBreakActive) return;
    if (currentSet.away > 0) currentSet.away--;
    notifyListeners();
  }

  void _afterPoint() {
    serveCount++;
    _maybeRotateServer();
    _checkSetEnd();
    notifyListeners();
  }

  bool get isCurrentGameCompleted =>
      currentGame.setsWonHome == 3 || currentGame.setsWonAway == 3;

  bool get isGameEditable => !isCurrentGameCompleted && !isBreakActive;

  void _checkSetEnd() {
    if ((currentSet.home >= 11 || currentSet.away >= 11) &&
        (currentSet.home - currentSet.away).abs() >= 2) {
      if (currentSet.home > currentSet.away) {
        currentGame.setsWonHome++;
      } else {
        currentGame.setsWonAway++;
      }

      if (isCurrentGameCompleted) {
        _completeGame();
        return;
      }

      // Start break before next set
      startBreak();
    }
  }

  void _setFirstServerOfSet() {
    final gameStartingServer = currentGame.startingServer;
    final gameStartingReceiver = currentGame.startingReceiver;

    if (gameStartingServer == null || gameStartingReceiver == null) return;

    if (currentGame.isDoubles) {
      currentServer = gameStartingServer;
      currentReceiver = gameStartingReceiver;
    } else {
      if ((currentGame.sets.length - 1) % 2 == 0) {
        currentServer = gameStartingServer;
        currentReceiver = gameStartingReceiver;
      } else {
        currentServer = gameStartingReceiver;
        currentReceiver = gameStartingServer;
      }
    }
    serveCount = 0;
  }

  void setDoublesPlayers(List<Player> home, List<Player> away) {
    currentGame.homePlayers = home;
    currentGame.awayPlayers = away;
    notifyListeners();
  }

  void setDoublesStartingServer(Player server, Player receiver) {
    setServer(server, receiver);
  }

  // /// Ends the break and immediately starts the next set
  // void endBreakEarly() {
  //   _breakTimer?.cancel(); // stop UI timer
  //   endBreak(); // mark break inactive
  //
  //   // Prepare next set
  //   currentGame.sets.add(SetScore()); // add a new empty set
  //   currentSet = currentGame.sets.last;
  //
  //   _setFirstServerOfSet(); // pick first server for the new set
  //   serveCount = 0; // reset server rotation
  //   notifyListeners();
  // }

  void _completeGame() {
    if (currentGame.setsWonHome > currentGame.setsWonAway) {
      matchGamesWonHome++;
    } else {
      matchGamesWonAway++;
    }

    if (currentGame.order < games.length) {
      _loadGame(currentGame.order);
    }

    notifyListeners();
  }

  // ----------------------------------------------------
  // SERVING
  // ----------------------------------------------------
  void setServer(Player? p, Player? receiver) {
    currentGame.startingServer = p;
    currentGame.startingReceiver = receiver;
    currentServer = p;
    currentReceiver = receiver;
    serveCount = 0;
    notifyListeners();
  }

  void _maybeRotateServer() {
    deuce = currentSet.home >= 10 && currentSet.away >= 10;
    if (serveCount >= (deuce ? 1 : 2)) {
      serveCount = 0;
      if (currentGame.isDoubles) {
        _rotateDoublesServer();
      } else {
        _swapServerSingles();
      }
    }
  }

  void _swapServerSingles() {
    final tempServer = currentServer;
    currentServer = currentReceiver;
    currentReceiver = tempServer;
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

    int currentIndex = sequence.indexWhere(
      (pair) => pair[0] == currentServer && pair[1] == currentReceiver,
    );

    if (currentIndex != -1) {
      int nextIndex = (currentIndex + 1) % sequence.length;
      currentServer = sequence[nextIndex][0];
      currentReceiver = sequence[nextIndex][1];
    }
  }

  void flipServerAndReceiver() {
    final temp = currentServer;
    currentServer = currentReceiver;
    currentReceiver = temp;
    notifyListeners();
  }

  void endBreak({bool early = false}) {
    isBreakActive = false;
    _breakTimer?.cancel();
    _breakTimer = null;

    // Add a new set (only if the game isn't finished)
    if (!isCurrentGameCompleted) {
      currentGame.sets.add(SetScore());
      currentSet = currentGame.sets.last;

      _setFirstServerOfSet();
      serveCount = 0;
    }

    notifyListeners();
  }

  // ----------------------------------------------------
  // SET BREAK
  // ----------------------------------------------------
  void startBreak({Duration? duration}) {
    remainingBreakTime = duration ?? breakDuration;
    isBreakActive = true;
    notifyListeners();
    onBreakStarted?.call();

    _breakTimer?.cancel(); // cancel any existing timer
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingBreakTime == null) return;

      if (remainingBreakTime!.inSeconds <= 0) {
        endBreak();
        timer.cancel();
      } else {
        remainingBreakTime = remainingBreakTime! - const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  void endBreakEarly() {
    endBreak(early: true);
  }

  // ----------------------------------------------------
  // NAVIGATION
  // ----------------------------------------------------
  void nextGame() {
    int nextIndex = games.indexOf(currentGame) + 1;
    if (nextIndex < games.length) _loadGame(nextIndex);
  }

  void previousGame() {
    int prevIndex = games.indexOf(currentGame) - 1;
    if (prevIndex >= 0) _loadGame(prevIndex);
  }

  // ----------------------------------------------------
  // RESET
  // ----------------------------------------------------
  void reset() {
    matchGamesWonHome = 0;
    matchGamesWonAway = 0;
    _initializeGames();
    _loadGame(0);
    notifyListeners();
  }

  @override
  void dispose() {
    _breakTimer?.cancel();
    super.dispose();
  }
}
