// import 'dart:async';
//
// import 'package:flutter/material.dart';
//
// import '../models/game.dart';
// import '../models/player.dart';
// import '../models/set_score.dart';
// import '../models/team.dart';
// import '../shared/configuration.dart';
//
// class MatchController extends ChangeNotifier {
//   final Team home;
//   final Team away;
//
//   late List<Game> games;
//   late Game currentGame;
//   late SetScore currentSet;
//
//   VoidCallback? onDoublesPlayersNeeded;
//   VoidCallback? onServerSelectionNeeded;
//
//   int matchGamesWonHome = 0;
//   int matchGamesWonAway = 0;
//
//   Player? currentServer;
//   Player? currentReceiver;
//   int serveCount = 0;
//   bool deuce = false;
//
//   Duration breakDuration = Duration(
//     seconds: TableTennisConfig.setBreak,
//   ); // configurable
//   Duration? remainingBreakTime;
//   bool isBreakActive = false;
//   Timer? _breakTimer;
//
//   bool isTimeoutActive = false;
//   int timeoutSecondsRemaining = 0;
//   Timer? _timeoutTimer;
//   String? timeoutTeam; // 'home' or 'away'
//
//   // Transition for next game, to prevent race condition on the dialog
//   bool isTransitioning = false;
//   bool isNextGameReady = false;
//   Game? nextGamePreview;
//
//   VoidCallback? onBreakStarted;
//   VoidCallback? onBreakEnded;
//
//   MatchController({required this.home, required this.away}) {
//     _initializeGames();
//     _loadGame(0);
//   }
//
//   // ----------------------------------------------------
//   // INITIALIZATION
//   // ----------------------------------------------------
//   void _initializeGames() {
//     final List<List<Player>> playerCombinations = [
//       [home.players[0]], [away.players[1]], // 1 v 2
//       [home.players[2]], [away.players[0]], // 3 v 1
//       [home.players[1]], [away.players[2]], // 2 v 3
//       [home.players[2]], [away.players[1]], // 3 v 2
//       [], [], // Game 5 = doubles
//       [home.players[0]], [away.players[2]], // 1 v 3
//       [home.players[1]], [away.players[0]], // 2 v 1
//       [home.players[2]], [away.players[2]], // 3 v 3
//       [home.players[1]], [away.players[1]], // 2 v 2
//       [home.players[0]], [away.players[0]], // 1 v 1
//     ];
//
//     games = [];
//     for (int i = 0; i < playerCombinations.length; i += 2) {
//       games.add(
//         Game(
//           order: (i ~/ 2) + 1,
//           isDoubles: i == 8, // Game 5 (index 8,9) is doubles
//           homePlayers: List.from(playerCombinations[i]),
//           awayPlayers: List.from(playerCombinations[i + 1]),
//         ),
//       );
//     }
//   }
//
//   void _loadGame(int index) {
//     currentGame = games[index];
//
//     // Reset
//     currentGame.startingServer = null;
//     currentGame.startingReceiver = null;
//     currentGame.homeTimeoutUsed = false;
//     currentGame.awayTimeoutUsed = false;
//     currentSet = currentGame.sets.last;
//
//     serveCount = 0;
//     deuce = false;
//     currentServer = null;
//     currentReceiver = null;
//
//     notifyListeners();
//   }
//
//   // ----------------------------------------------------
//   // CONTROL
//   // ----------------------------------------------------
//   void addPointHome() {
//     if (isBreakActive) return;
//     currentSet.home++;
//     _afterPoint();
//   }
//
//   void addPointAway() {
//     if (isBreakActive) return;
//     currentSet.away++;
//     _afterPoint();
//   }
//
//   void undoPointHome() {
//     if (isBreakActive) return;
//     if (currentSet.home > 0) currentSet.home--;
//     notifyListeners();
//   }
//
//   void undoPointAway() {
//     if (isBreakActive) return;
//     if (currentSet.away > 0) currentSet.away--;
//     notifyListeners();
//   }
//
//   void _afterPoint() {
//     serveCount++;
//     _maybeRotateServer(); // do we swap the server?
//     _checkSetEnd(); // Is it the end of the set?
//     notifyListeners();
//   }
//
//   bool get isCurrentGameCompleted =>
//       currentGame.setsWonHome == 3 || currentGame.setsWonAway == 3;
//
//   bool get isGameEditable => !isCurrentGameCompleted && !isBreakActive;
//
//   void _checkSetEnd() {
//     if ((currentSet.home >= 11 || currentSet.away >= 11) &&
//         (currentSet.home - currentSet.away).abs() >= 2) {
//       if (currentSet.home > currentSet.away) {
//         currentGame.setsWonHome++;
//       } else {
//         currentGame.setsWonAway++;
//       }
//
//       if (isCurrentGameCompleted) {
//         _completeGame();
//         return;
//       }
//
//       // Start break before next set
//       startBreak();
//     }
//   }
//
//   void _setFirstServerOfSet() {
//     final gameStartingServer = currentGame.startingServer;
//     final gameStartingReceiver = currentGame.startingReceiver;
//
//     if (gameStartingServer == null || gameStartingReceiver == null) return;
//
//     if (currentGame.isDoubles) {
//       currentServer = gameStartingServer;
//       currentReceiver = gameStartingReceiver;
//     } else {
//       if ((currentGame.sets.length - 1) % 2 == 0) {
//         currentServer = gameStartingServer;
//         currentReceiver = gameStartingReceiver;
//       } else {
//         currentServer = gameStartingReceiver;
//         currentReceiver = gameStartingServer;
//       }
//     }
//     serveCount = 0;
//   }
//
//   void setDoublesPlayers(List<Player> home, List<Player> away) {
//     currentGame.homePlayers = home;
//     currentGame.awayPlayers = away;
//     notifyListeners();
//   }
//
//   void setDoublesStartingServer(Player server, Player receiver) {
//     setServer(server, receiver);
//   }
//
//   // /// Ends the break and immediately starts the next set
//   // void endBreakEarly() {
//   //   _breakTimer?.cancel(); // stop UI timer
//   //   endBreak(); // mark break inactive
//   //
//   //   // Prepare next set
//   //   currentGame.sets.add(SetScore()); // add a new empty set
//   //   currentSet = currentGame.sets.last;
//   //
//   //   _setFirstServerOfSet(); // pick first server for the new set
//   //   serveCount = 0; // reset server rotation
//   //   notifyListeners();
//   // }
//   Future<void> _completeGame() async {
//     if (currentGame.setsWonHome > currentGame.setsWonAway) {
//       matchGamesWonHome++;
//     } else {
//       matchGamesWonAway++;
//     }
//
//     if (currentGame.order < games.length) {
//       // Get the next game details but don’t load it yet
//       nextGamePreview = games[currentGame.order];
//
//       isTransitioning = true;
//       isNextGameReady = true;
//       notifyListeners();
//     }
//   }
//
//   void startNextGame() {
//     if (nextGamePreview == null) return;
//
//     isTransitioning = false;
//     isNextGameReady = false;
//
//     final index = nextGamePreview!.order - 1;
//     _loadGame(index);
//     nextGamePreview = null;
//
//     // Call dialogs *after* load
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (currentGame.isDoubles && currentGame.homePlayers.isEmpty) {
//         onDoublesPlayersNeeded?.call();
//       } else if (currentGame.startingServer == null) {
//         onServerSelectionNeeded?.call();
//       }
//     });
//
//     notifyListeners();
//   }
//
//   // ----------------------------------------------------
//   // SERVING
//   // ----------------------------------------------------
//   void setServer(Player? p, Player? receiver) {
//     currentGame.startingServer = p;
//     currentGame.startingReceiver = receiver;
//     currentServer = p;
//     currentReceiver = receiver;
//     serveCount = 0;
//     notifyListeners();
//   }
//
//   void _maybeRotateServer() {
//     deuce = currentSet.home >= 10 && currentSet.away >= 10;
//     if (serveCount >= (deuce ? 1 : 2)) {
//       serveCount = 0;
//       if (currentGame.isDoubles) {
//         _rotateDoublesServer();
//       } else {
//         _swapServerSingles();
//       }
//     }
//   }
//
//   void _swapServerSingles() {
//     final tempServer = currentServer;
//     currentServer = currentReceiver;
//     currentReceiver = tempServer;
//   }
//
//   void _rotateDoublesServer() {
//     if (currentGame.homePlayers.length < 2 ||
//         currentGame.awayPlayers.length < 2)
//       return;
//
//     final h1 = currentGame.homePlayers[0];
//     final h2 = currentGame.homePlayers[1];
//     final a1 = currentGame.awayPlayers[0];
//     final a2 = currentGame.awayPlayers[1];
//
//     final sequence = [
//       [h1, a1],
//       [a1, h2],
//       [h2, a2],
//       [a2, h1],
//     ];
//
//     int currentIndex = sequence.indexWhere(
//       (pair) => pair[0] == currentServer && pair[1] == currentReceiver,
//     );
//
//     if (currentIndex != -1) {
//       int nextIndex = (currentIndex + 1) % sequence.length;
//       currentServer = sequence[nextIndex][0];
//       currentReceiver = sequence[nextIndex][1];
//     }
//   }
//
//   void flipServerAndReceiver() {
//     final temp = currentServer;
//     currentServer = currentReceiver;
//     currentReceiver = temp;
//     notifyListeners();
//   }
//
//   void endBreak({bool early = false}) {
//     isBreakActive = false;
//     _breakTimer?.cancel();
//     _breakTimer = null;
//
//     // Add a new set (only if the game isn't finished)
//     if (!isCurrentGameCompleted) {
//       currentGame.sets.add(SetScore());
//       currentSet = currentGame.sets.last;
//
//       _setFirstServerOfSet();
//       serveCount = 0;
//     }
//
//     notifyListeners();
//   }
//
//   // ----------------------------------------------------
//   // SET BREAK
//   // ----------------------------------------------------
//   void startBreak({Duration? duration}) {
//     remainingBreakTime = duration ?? breakDuration;
//     isBreakActive = true;
//     notifyListeners();
//     onBreakStarted?.call();
//
//     _breakTimer?.cancel(); // cancel any existing timer
//     _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (remainingBreakTime == null) return;
//
//       if (remainingBreakTime!.inSeconds <= 0) {
//         endBreak();
//         timer.cancel();
//       } else {
//         remainingBreakTime = remainingBreakTime! - const Duration(seconds: 1);
//         notifyListeners();
//       }
//     });
//   }
//
//   void endBreakEarly() {
//     endBreak(early: true);
//   }
//
//   // ----------------------------------------------------
//   // Timeout
//   // ----------------------------------------------------
//   // ----------------------------------------------------
//   // Timeout
//   // ----------------------------------------------------
//   bool timeoutCalledByHome = false;
//   Duration? remainingTimeoutTime;
//
//   void startTimeout({required bool isHome}) {
//     if (isTimeoutActive) return;
//     if (isHome && currentGame.homeTimeoutUsed) return;
//     if (!isHome && currentGame.awayTimeoutUsed) return;
//
//     // cancel any existing timeout timer just to be safe
//     _timeoutTimer?.cancel();
//
//     isTimeoutActive = true;
//     timeoutCalledByHome = isHome;
//     remainingTimeoutTime = Duration(seconds: TableTennisConfig.timeoutTimer);
//
//     if (isHome) currentGame.homeTimeoutUsed = true;
//     if (!isHome) currentGame.awayTimeoutUsed = true;
//
//     notifyListeners();
//
//     _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!isTimeoutActive || remainingTimeoutTime == null) {
//         timer.cancel();
//         return;
//       }
//
//       if (remainingTimeoutTime!.inSeconds <= 1) {
//         endTimeout();
//         timer.cancel();
//       } else {
//         remainingTimeoutTime =
//             remainingTimeoutTime! - const Duration(seconds: 1);
//         notifyListeners();
//       }
//     });
//   }
//
//   void endTimeout() {
//     _timeoutTimer?.cancel();
//     _timeoutTimer = null;
//     isTimeoutActive = false;
//     remainingTimeoutTime = null;
//     notifyListeners();
//   }
//
//   void endTimeoutEarly() {
//     endTimeout();
//   }
//
//   // ----------------------------------------------------
//   // NAVIGATION
//   // ----------------------------------------------------
//   void nextGame() {
//     int nextIndex = games.indexOf(currentGame) + 1;
//     if (nextIndex < games.length) _loadGame(nextIndex);
//   }
//
//   void previousGame() {
//     int prevIndex = games.indexOf(currentGame) - 1;
//     if (prevIndex >= 0) _loadGame(prevIndex);
//   }
//
//   // ----------------------------------------------------
//   // RESET
//   // ----------------------------------------------------
//   void reset() {
//     matchGamesWonHome = 0;
//     matchGamesWonAway = 0;
//     _initializeGames();
//     _loadGame(0);
//     notifyListeners();
//   }
//
//   @override
//   void dispose() {
//     _breakTimer?.cancel();
//     super.dispose();
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/player.dart';
import '../models/set_score.dart';
import '../models/team.dart';
import '../shared/configuration.dart';

/// --------------------------------------------------------------
/// MatchController manages the full match state:
/// - Scores
/// - Sets & games
/// - Breaks
/// - Timeouts
/// - Server rotation (singles/doubles)
/// - Next game transitions
/// --------------------------------------------------------------
class MatchController extends ChangeNotifier {
  final Team home;
  final Team away;

  /// List of all games
  late List<Game> games;

  /// Current game and set
  late Game currentGame;
  late SetScore currentSet;

  /// Callbacks for dialogs
  VoidCallback? onDoublesPlayersNeeded;
  VoidCallback? onServerSelectionNeeded;

  /// Match score counters
  int matchGamesWonHome = 0;
  int matchGamesWonAway = 0;

  /// Current server and receiver tracking
  Player? currentServer;
  Player? currentReceiver;
  int serveCount = 0;
  bool deuce = false;

  /// Break timer state
  Duration breakDuration = Duration(seconds: TableTennisConfig.setBreak);
  Duration? remainingBreakTime;
  bool isBreakActive = false;
  Timer? _breakTimer;
  VoidCallback? onBreakStarted;
  VoidCallback? onBreakEnded;

  /// Timeout state
  bool isTimeoutActive = false;
  bool timeoutCalledByHome = false;
  Duration? remainingTimeoutTime;
  Timer? _timeoutTimer;

  /// Next game transition
  bool isTransitioning = false;
  bool isNextGameReady = false;
  Game? nextGamePreview;

  /// --------------------------------------------------------------
  /// Constructor
  /// --------------------------------------------------------------
  MatchController({required this.home, required this.away}) {
    _initializeGames();
    _loadGame(0);
  }

  // --------------------------------------------------------------
  // INITIALIZATION
  // --------------------------------------------------------------

  /// Prepare all games for the match
  void _initializeGames() {
    final playerCombinations = [
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
          isDoubles: i == 8, // Hardcoded doubles (Game 5)
          homePlayers: List.from(playerCombinations[i]),
          awayPlayers: List.from(playerCombinations[i + 1]),
        ),
      );
    }
  }

  /// Loads a specific game
  void _loadGame(int index) {
    currentGame = games[index];

    // Reset game state
    currentGame.startingServer = null;
    currentGame.startingReceiver = null;
    currentGame.homeTimeoutUsed = false;
    currentGame.awayTimeoutUsed = false;

    currentSet = currentGame.sets.last;
    currentServer = null;
    currentReceiver = null;
    serveCount = 0;
    deuce = false;

    notifyListeners();
  }

  // --------------------------------------------------------------
  // SCORING
  // --------------------------------------------------------------

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
    if (isBreakActive || currentSet.home == 0) return;
    currentSet.home--;
    notifyListeners();
  }

  void undoPointAway() {
    if (isBreakActive || currentSet.away == 0) return;
    currentSet.away--;
    notifyListeners();
  }

  /// Called after any point is added
  void _afterPoint() {
    serveCount++;
    _maybeRotateServer();
    _checkSetEnd();
    notifyListeners();
  }

  bool get isCurrentGameCompleted =>
      currentGame.setsWonHome == 3 || currentGame.setsWonAway == 3;

  bool get isGameEditable => !isCurrentGameCompleted && !isBreakActive;

  /// Check if current set is complete and handle set/game progression
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

  // --------------------------------------------------------------
  // SERVER MANAGEMENT
  // --------------------------------------------------------------

  void _setFirstServerOfSet() {
    final server = currentGame.startingServer;
    final receiver = currentGame.startingReceiver;
    if (server == null || receiver == null) return;

    if (currentGame.isDoubles) {
      currentServer = server;
      currentReceiver = receiver;
    } else {
      if ((currentGame.sets.length - 1) % 2 == 0) {
        currentServer = server;
        currentReceiver = receiver;
      } else {
        currentServer = receiver;
        currentReceiver = server;
      }
    }
    serveCount = 0;
  }

  void setServer(Player? server, Player? receiver) {
    currentGame.startingServer = server;
    currentGame.startingReceiver = receiver;
    currentServer = server;
    currentReceiver = receiver;
    serveCount = 0;
    notifyListeners();
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

  void flipServerAndReceiver() {
    final temp = currentServer;
    currentServer = currentReceiver;
    currentReceiver = temp;
    notifyListeners();
  }

  // --------------------------------------------------------------
  // BREAKS
  // --------------------------------------------------------------

  void startBreak({Duration? duration}) {
    remainingBreakTime = duration ?? breakDuration;
    isBreakActive = true;
    onBreakStarted?.call();
    notifyListeners();

    _breakTimer?.cancel();
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

  void endBreak({bool early = false}) {
    _breakTimer?.cancel();
    _breakTimer = null;
    isBreakActive = false;
    onBreakEnded?.call();

    if (!isCurrentGameCompleted) {
      currentGame.sets.add(SetScore());
      currentSet = currentGame.sets.last;
      _setFirstServerOfSet();
      serveCount = 0;
    }

    notifyListeners();
  }

  void endBreakEarly() => endBreak(early: true);

  // --------------------------------------------------------------
  // TIMEOUTS
  // --------------------------------------------------------------

  void startTimeout({required bool isHome}) {
    if (isTimeoutActive) return;
    if ((isHome && currentGame.homeTimeoutUsed) ||
        (!isHome && currentGame.awayTimeoutUsed))
      return;

    _timeoutTimer?.cancel();
    isTimeoutActive = true;
    timeoutCalledByHome = isHome;
    remainingTimeoutTime = Duration(seconds: TableTennisConfig.timeoutTimer);

    if (isHome) currentGame.homeTimeoutUsed = true;
    if (!isHome) currentGame.awayTimeoutUsed = true;

    notifyListeners();

    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isTimeoutActive || remainingTimeoutTime == null) {
        timer.cancel();
        return;
      }

      if (remainingTimeoutTime!.inSeconds <= 1) {
        endTimeout();
        timer.cancel();
      } else {
        remainingTimeoutTime =
            remainingTimeoutTime! - const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  void endTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    isTimeoutActive = false;
    remainingTimeoutTime = null;
    notifyListeners();
  }

  void endTimeoutEarly() => endTimeout();

  // --------------------------------------------------------------
  // GAME PROGRESSION
  // --------------------------------------------------------------

  Future<void> _completeGame() async {
    if (currentGame.setsWonHome > currentGame.setsWonAway) {
      matchGamesWonHome++;
    } else {
      matchGamesWonAway++;
    }

    if (currentGame.order < games.length) {
      nextGamePreview = games[currentGame.order];
      isTransitioning = true;
      isNextGameReady = true;
      notifyListeners();
    }
  }

  void startNextGame() {
    if (nextGamePreview == null) return;

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

    notifyListeners();
  }

  /// --------------------------------------------------------------
  /// Set the home and away players for a doubles match
  /// Called after the user selects players in the doubles picker dialog
  /// --------------------------------------------------------------
  void setDoublesPlayers(List<Player> home, List<Player> away) {
    currentGame.homePlayers = home;
    currentGame.awayPlayers = away;
    notifyListeners();
  }

  /// --------------------------------------------------------------
  /// Set the starting server and receiver for a doubles match
  /// Typically called after the doubles picker dialog confirms
  /// --------------------------------------------------------------
  void setDoublesStartingServer(Player server, Player receiver) {
    setServer(server, receiver);
  }

  // --------------------------------------------------------------
  // NAVIGATION
  // --------------------------------------------------------------

  void nextGame() {
    int nextIndex = games.indexOf(currentGame) + 1;
    if (nextIndex < games.length) _loadGame(nextIndex);
  }

  void previousGame() {
    int prevIndex = games.indexOf(currentGame) - 1;
    if (prevIndex >= 0) _loadGame(prevIndex);
  }

  // --------------------------------------------------------------
  // RESET
  // --------------------------------------------------------------

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
    _timeoutTimer?.cancel();
    super.dispose();
  }
}
