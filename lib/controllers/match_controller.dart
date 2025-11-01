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

  MatchController({required this.home, required this.away}) {
    _initializeGames();
    _loadGame(0);
  }

  // ----------------------------------------------------
  // INITIALIZATION
  // ----------------------------------------------------
  void _initializeGames() {
    // Game order you provided:
    // index 0 is player 1
    // index 1 is player 2
    // index 2 is player 3
    final order = [
      [home.players[0]], [away.players[1]], // 1 v 2
      [home.players[2]], [away.players[0]], // 3 v 1
      [home.players[1]], [away.players[2]], // 2 v 3
      [home.players[2]], [away.players[1]], // 3 v 2
      // Game 5 = doubles
      [home.players[0], home.players[1]], [away.players[0], away.players[1]],
      [home.players[0]], [away.players[2]], // 1 v 3
      [home.players[1]], [away.players[0]], // 2 v 1
      [home.players[2]], [away.players[2]], // 3 v 3
      [home.players[1]], [away.players[1]], // 2 v 2
      [home.players[0]], [away.players[0]], // 1 v 1
    ];

    games = [];
    for (int i = 0; i < order.length; i += 2) {
      games.add(
        Game(
          order: (i ~/ 2) + 1,
          isDoubles: order[i].length == 2,
          homePlayers: order[i],
          awayPlayers: order[i + 1],
        ),
      );
    }
  }

  void _loadGame(int index) {
    currentGame = games[index];
    currentSet = currentGame.sets.last;
    serveCount = 0;
    currentServer = null;
    currentReceiver = null;

    // Trigger dialogs if needed
    if (currentGame.isDoubles && currentGame.homePlayers.length != 2) {
      if (onDoublesPlayersNeeded != null) {
        onDoublesPlayersNeeded!();
      }
    } else {
      // This handles singles and also the very first game
      if (onServerSelectionNeeded != null) {
        onServerSelectionNeeded!();
      }
    }
  }

  // ----------------------------------------------------
  // CONTROL
  // ----------------------------------------------------

  // Add point to the home team
  void addPointHome() {
    currentSet.home++;
    _afterPoint();
  }

  // Add point to the away team
  void addPointAway() {
    currentSet.away++;
    _afterPoint();
  }

  // Take point away from home team
  void undoPointHome() {
    if (currentSet.home > 0) currentSet.home--;
    notifyListeners();
  }

  // Take away point from the away team
  void undoPointAway() {
    if (currentSet.away > 0) currentSet.away--;
    notifyListeners();
  }

  // After a point, check if we are to swap the server or not
  void _afterPoint() {
    serveCount++;
    _maybeRotateServer();
    _checkSetEnd();
    notifyListeners();
  }

  // Is the current game completed
  bool get isCurrentGameCompleted {
    return currentGame.setsWonHome == 3 || currentGame.setsWonAway == 3;
  }

  // Can we edit game, not if the game is completed
  bool get isGameEditable {
    return !isCurrentGameCompleted;
  }

  void _checkSetEnd() {
    // Check if the current set is finished (11 points & 2-point difference)
    if ((currentSet.home >= 11 || currentSet.away >= 11) &&
        (currentSet.home - currentSet.away).abs() >= 2) {
      // Update sets won for this game
      if (currentSet.home > currentSet.away) {
        currentGame.setsWonHome++;
      } else {
        currentGame.setsWonAway++;
      }

      // Check if the entire game is finished (best of 5 sets)
      if (currentGame.setsWonHome == 3 || currentGame.setsWonAway == 3) {
        _completeGame();
        return; // no need to start a new set
      }

      // Start the next set
      currentGame.sets.add(SetScore());
      currentSet = currentGame.sets.last;
      serveCount = 0;
      deuce = false;

      // Determine the first server for the new set
      _setFirstServerOfSet();

      // Notify UI of the change
      notifyListeners();
    }
  }

  void _setFirstServerOfSet() {
    if (currentGame.isDoubles) {
      // If a starting server was set manually for this set, use it
      if (currentGame.startingServer != null &&
          currentGame.startingReceiver != null) {
        currentServer = currentGame.startingServer;
        currentReceiver = currentGame.startingReceiver;
      } else {
        // Fallback: default to homePlayers[0] -> awayPlayers[0]
        currentServer = currentGame.homePlayers[0];
        currentReceiver = currentGame.awayPlayers[0];
      }
    } else {
      // Singles: alternate between home/away starting server
      if ((currentGame.sets.length - 1) % 2 == 0) {
        currentServer = currentGame.homePlayers.first;
        currentReceiver = currentGame.awayPlayers.first;
      } else {
        currentServer = currentGame.awayPlayers.first;
        currentReceiver = currentGame.homePlayers.first;
      }
    }

    serveCount = 0;
    debugPrint(
      'New set — server is ${currentServer!.name} to ${currentReceiver!.name}',
    );
    notifyListeners();
  }

  void setDoublesStartingServer(Player server, Player receiver) {
    currentGame.startingServer = server;
    currentGame.startingReceiver = receiver;

    currentServer = server;
    currentReceiver = receiver;
    serveCount = 0;

    debugPrint(
      'Doubles starting server set — ${currentServer!.name} serves to ${currentReceiver!.name}',
    );
    notifyListeners();
  }

  void _completeGame() {
    if (currentGame.setsWonHome > currentGame.setsWonAway) {
      matchGamesWonHome++;
    } else {
      matchGamesWonAway++;
    }

    int nextIndex = currentGame.order;
    if (nextIndex < games.length) {
      _loadGame(nextIndex);
    }
  }

  // ----------------------------------------------------
  // SERVING
  // ----------------------------------------------------
  void setServer(Player? p, Player? receiver) {
    currentServer = p;
    currentReceiver = receiver;
    serveCount = 0;
    notifyListeners();
  }

  void _maybeRotateServer() {
    final totalPoints = currentSet.home + currentSet.away;
    deuce = currentSet.home >= 10 && currentSet.away >= 10;
    int interval = deuce ? 1 : 2;

    if (serveCount >= interval) {
      serveCount = 0;
      if (currentGame.isDoubles) {
        _rotateDoublesServer();
      } else {
        _swapServerSingles();
      }
    }
  }

  void _swapServerSingles() {
    if (currentServer == currentGame.homePlayers.first) {
      currentServer = currentGame.awayPlayers.first;
      currentReceiver = currentGame.homePlayers.first;
    } else {
      currentServer = currentGame.homePlayers.first;
      currentReceiver = currentGame.awayPlayers.first;
    }
  }

  void _rotateDoublesServer() {
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

    int nextIndex = (currentIndex + 1) % sequence.length;
    currentServer = sequence[nextIndex][0];
    currentReceiver = sequence[nextIndex][1];
  }

  void flipServerAndReceiver() {
    if (currentServer != null && currentReceiver != null) {
      final temp = currentServer;
      currentServer = currentReceiver;
      currentReceiver = temp;
      debugPrint(
        'Server/Receiver flipped — now ${currentServer!.name} serves to ${currentReceiver!.name}',
      );
      notifyListeners();
    }
  }

  List<List<Player>> get _doublesSequence {
    // Ensure the current game is doubles
    if (!currentGame.isDoubles ||
        currentGame.homePlayers.length != 2 ||
        currentGame.awayPlayers.length != 2) {
      throw Exception(
        "Doubles sequence requested but current game is not doubles or players are missing",
      );
    }

    final h1 = currentGame.homePlayers[0];
    final h2 = currentGame.homePlayers[1];
    final a1 = currentGame.awayPlayers[0];
    final a2 = currentGame.awayPlayers[1];

    // Standard 4-step rotation
    return [
      [h1, a1],
      [a1, h2],
      [h2, a2],
      [a2, h1],
    ];
  }

  // ----------------------------------------------------
  // NAVIGATION
  // ----------------------------------------------------
  void nextGame() {
    int nextIndex = games.indexOf(currentGame) + 1;
    if (nextIndex < games.length) _loadGame(nextIndex);
    notifyListeners();
  }

  void previousGame() {
    int prevIndex = games.indexOf(currentGame) - 1;
    if (prevIndex >= 0) _loadGame(prevIndex);
    notifyListeners();
  }

  // ----------------------------------------------------
  // RESET
  // ----------------------------------------------------
  void reset() {
    matchGamesWonHome = 0;
    matchGamesWonAway = 0;
    serveCount = 0;
    deuce = false;
    currentServer = null;
    currentReceiver = null;

    _initializeGames(); // recreate all games
    _loadGame(0); // load the first game

    notifyListeners();
  }
}
