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

    // Reset common state
    serveCount = 0;
    deuce = false;
    currentServer = null;
    currentReceiver = null;

    if (currentGame.isDoubles) {
      // --- DOUBLES LOGIC ---
      if (currentGame.homePlayers.isEmpty) {
        // No doubles teams chosen yet
        onDoublesPlayersNeeded?.call();
        return;
      }

      if (currentGame.startingServer == null) {
        // Teams chosen but no server yet
        onServerSelectionNeeded?.call();
        return;
      }
    } else {
      // --- SINGLES LOGIC ---
      if (currentGame.startingServer == null) {
        onServerSelectionNeeded?.call();
        return;
      }
    }

    // --- RESTORE GAME STATE ---
    _setFirstServerOfSet();

    // Determine correct server rotation based on score
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
      deuce = false;
      _setFirstServerOfSet();
      notifyListeners();
    }
  }

  void _setFirstServerOfSet() {
    final gameStartingServer = currentGame.startingServer;
    final gameStartingReceiver = currentGame.startingReceiver;

    if (gameStartingServer == null || gameStartingReceiver == null) return;

    if (currentGame.isDoubles) {
      // In doubles, the player who was due to serve next will serve.
      // This is a simplified model where the receiver of the last set serves to the partner of the server of the last set.
      // For now, we just reset to the game's starting server which is a common house rule.
      currentServer = gameStartingServer;
      currentReceiver = gameStartingReceiver;
    } else {
      // In singles, the server alternates each set.
      if ((currentGame.sets.length - 1) % 2 == 0) {
        // Sets 1, 3, 5
        currentServer = gameStartingServer;
        currentReceiver = gameStartingReceiver;
      } else {
        // Sets 2, 4
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

  // ----------------------------------------------------
  // SET INTERVAL
  // ----------------------------------------------------
  void startBreak() {
    remainingBreakTime = breakDuration;
    isBreakActive = true;
    notifyListeners();

    onBreakStarted?.call();

    // countdown
    Future.doWhile(() async {
      if (remainingBreakTime!.inSeconds <= 0) {
        endBreak();
        return false;
      }
      await Future.delayed(const Duration(seconds: 1));
      remainingBreakTime = remainingBreakTime! - const Duration(seconds: 1);
      notifyListeners();
      return true;
    });
  }

  void endBreak() {
    isBreakActive = false;
    remainingBreakTime = null;
    notifyListeners();
    onBreakEnded?.call();
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
