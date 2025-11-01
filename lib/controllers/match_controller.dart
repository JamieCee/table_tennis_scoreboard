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
          isDoubles: i == 8, // Game 5 (index 8, 9) is doubles
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
    currentServer = null;
    currentReceiver = null;

    if (currentGame.isDoubles && currentGame.homePlayers.isEmpty) {
      onDoublesPlayersNeeded?.call();
    } else {
      onServerSelectionNeeded?.call();
    }
    notifyListeners();
  }

  // ----------------------------------------------------
  // CONTROL
  // ----------------------------------------------------

  void addPointHome() {
    currentSet.home++;
    _afterPoint();
  }

  void addPointAway() {
    currentSet.away++;
    _afterPoint();
  }

  void undoPointHome() {
    if (currentSet.home > 0) currentSet.home--;
    notifyListeners();
  }

  void undoPointAway() {
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

  bool get isGameEditable => !isCurrentGameCompleted;

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

      currentGame.sets.add(SetScore());
      currentSet = currentGame.sets.last;
      serveCount = 0;
      deuce = false;
      _setFirstServerOfSet();
      notifyListeners();
    }
  }

  void _setFirstServerOfSet() {
    if (currentGame.isDoubles) {
      currentServer = currentGame.startingServer ?? currentGame.homePlayers[0];
      currentReceiver =
          currentGame.startingReceiver ?? currentGame.awayPlayers[0];
    } else {
      if ((currentGame.sets.length - 1) % 2 == 0) {
        currentServer = currentGame.homePlayers.first;
        currentReceiver = currentGame.awayPlayers.first;
      } else {
        currentServer = currentGame.awayPlayers.first;
        currentReceiver = currentGame.homePlayers.first;
      }
    }
    serveCount = 0;
    notifyListeners();
  }

  void setDoublesPlayers(List<Player> home, List<Player> away) {
    currentGame.homePlayers = home;
    currentGame.awayPlayers = away;
    notifyListeners();
  }

  void setDoublesStartingServer(Player server, Player receiver) {
    currentGame.startingServer = server;
    currentGame.startingReceiver = receiver;
    currentServer = server;
    currentReceiver = receiver;
    serveCount = 0;
    notifyListeners();
  }

  void _completeGame() {
    if (currentGame.setsWonHome > currentGame.setsWonAway) {
      matchGamesWonHome++;
    } else {
      matchGamesWonAway++;
    }
    if (currentGame.order < games.length) {
      _loadGame(currentGame.order);
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
    final temp = currentServer;
    currentServer = currentReceiver;
    currentReceiver = temp;
    notifyListeners();
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
}
