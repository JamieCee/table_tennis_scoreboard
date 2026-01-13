import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:table_tennis_scoreboard/models/game.dart';
import 'package:table_tennis_scoreboard/models/player.dart';
import 'package:table_tennis_scoreboard/models/set_score.dart';
import 'package:table_tennis_scoreboard/models/team.dart';
import 'package:table_tennis_scoreboard/services/match_state_manager.dart';
import 'package:table_tennis_scoreboard/shared/configuration.dart';

part 'match_event.dart';
part 'match_state.dart';

enum MatchType { singles, team, handicap }

class MatchBloc extends Bloc<MatchEvent, MatchState> {
  final String matchId;
  final Team home;
  final Team away;
  final bool isObserver;
  final MatchType matchType;
  final int setsToWin;

  final MatchStateManager _matchStateManager;
  final CollectionReference _matches;

  int matchGamesWonHome = 0;
  int matchGamesWonAway = 0;

  late final int pointsToWin;
  late final int servesPerTurn;

  Timer? _breakTimer;
  Timer? _timeoutTimer;
  StreamSubscription? _firestoreSub;

  MatchBloc({
    required this.matchId,
    required this.home,
    required this.away,
    required this.isObserver,
    required this.matchType,
    required this.setsToWin,
    required MatchStateManager matchStateManager,
  }) : _matchStateManager = matchStateManager,
       _matches = FirebaseFirestore.instance.collection('matches'),
       servesPerTurn = (matchType == MatchType.handicap) ? 5 : 2,
       super(
         MatchState(
           homeTeam: home,
           awayTeam: away,
           games: [],
           matchType: matchType,
           setsToWin: setsToWin,
           pointsToWin: (matchType == MatchType.handicap) ? 21 : 11,
         ),
       ) {
    // Match lifecycle
    on<MatchStarted>(_onStarted);
    on<MatchResumed>(_onResumed);
    on<FirestoreUpdated>(_onFirestoreUpdated);
    on<MatchDeleted>(_onMatchDeleted);

    // Scoring
    on<AddPointHome>(_onAddPointHome);
    on<AddPointAway>(_onAddPointAway);
    on<UndoPointHome>(_onUndoPointHome);
    on<UndoPointAway>(_onUndoPointAway);

    // Server/Doubles
    on<SetServer>(_onSetServer);
    on<SetDoublesPlayers>(_onSetDoublesPlayers);

    // Break / Timeout
    on<StartBreak>(_onStartBreak);
    on<EndBreak>(_onEndBreak);
    on<StartTimeout>(_onStartTimeout);
    on<EndTimeout>(_onEndTimeout);
    on<EndBreakEarly>((event, emit) {
      emit(state.copyWith(isBreakActive: false, remainingBreakTime: null));
    });
    on<EndTimeoutEarly>((event, emit) {
      emit(
        state.copyWith(
          isTimeoutActive: false,
          remainingTimeoutTime: null,
          timeoutCalledByHome: false, // reset who called the timeout
        ),
      );
    });

    on<_BreakTicked>(_onBreakTicked);
    on<_TimeoutTicked>(_onTimeoutTicked);

    // Next game
    on<StartNextGame>(_onStartNextGame);

    // Firestore listener
    _listenToFirestore();

    if (!isObserver) {
      _matchStateManager.startControlling();
      add(MatchStarted());
    }
  }

  void _initRules() {
    if (matchType == MatchType.handicap) {
      pointsToWin = 21;
      servesPerTurn = 5;
    } else {
      pointsToWin = 11;
      servesPerTurn = 2;
    }
  }

  // ---------------------------------------------------------------------------
  // Firestore listener
  // ---------------------------------------------------------------------------
  void _listenToFirestore() {
    _firestoreSub = _matches.doc(matchId).snapshots().listen((snapshot) {
      if (!snapshot.exists) {
        add(MatchDeleted());
        return;
      }
      add(FirestoreUpdated(snapshot.data()! as Map<String, dynamic>));
    });
  }

  // ---------------------------------------------------------------------------
  // Match lifecycle
  // ---------------------------------------------------------------------------
  void _onStarted(MatchStarted event, Emitter<MatchState> emit) {
    // Initialize games
    List<Game> games = [];
    if (matchType == MatchType.singles || matchType == MatchType.handicap) {
      final initialSet = SetScore(
        home: matchType == MatchType.handicap ? home.startingPoints : 0,
        away: matchType == MatchType.handicap ? away.startingPoints : 0,
      );

      final game = Game(
        order: 1,
        isDoubles: false,
        homePlayers: [home.players[0]],
        awayPlayers: [away.players[0]],
        sets: [initialSet],
      );
      // game.sets.clear();
      // game.sets.add(SetScore());
      games.add(game);
    } else {
      // Doubles rotation like original controller
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
        final initialSet = SetScore();
        games.add(
          Game(
            order: (i ~/ 2) + 1,
            isDoubles: i == 8,
            homePlayers: List.from(playerCombinations[i]),
            awayPlayers: List.from(playerCombinations[i + 1]),
            sets: [initialSet],
          ),
        );
      }
    }

    emit(
      state.copyWith(
        games: games,
        currentGame: games.first,
        currentSet: games.first.sets.first,
      ),
    );

    _push();
  }

  void _onResumed(MatchResumed event, Emitter<MatchState> emit) {
    _updateFromMap(event.resumeData, emit);
  }

  void _onFirestoreUpdated(FirestoreUpdated event, Emitter<MatchState> emit) {
    _updateFromMap(event.data, emit);
  }

  void _onMatchDeleted(MatchDeleted event, Emitter<MatchState> emit) {
    _matchStateManager.stopControlling();
    _matches.doc(matchId).delete();
  }

  // ---------------------------------------------------------------------------
  // Scoring (immutable)
  // ---------------------------------------------------------------------------
  void _onAddPointHome(AddPointHome e, Emitter<MatchState> emit) {
    if (state.isBreakActive || state.isTimeoutActive) return;
    final set = state.currentSet!;
    final updatedSet = set.copyWith(home: set.home + 1);
    final updatedState = _stateWithUpdatedGames(state, updatedSet);

    _afterPoint(emit, updatedState);
  }

  void _onAddPointAway(AddPointAway e, Emitter<MatchState> emit) {
    if (state.isBreakActive || state.isTimeoutActive) return;
    final set = state.currentSet!;
    final updatedSet = set.copyWith(away: set.away + 1);
    final updatedState = _stateWithUpdatedGames(state, updatedSet);
    // emit(state.copyWith(currentSet: updatedSet));
    _afterPoint(emit, updatedState);
  }

  void _onUndoPointHome(UndoPointHome e, Emitter<MatchState> emit) {
    final set = state.currentSet!;
    if (set.home == 0) return;
    final updatedSet = set.copyWith(home: set.home - 1);
    final updatedState = _stateWithUpdatedGames(state, updatedSet);
    emit(updatedState);
    _push();
  }

  void _onUndoPointAway(UndoPointAway e, Emitter<MatchState> emit) {
    final set = state.currentSet!;
    if (set.away == 0) return;
    final updatedSet = set.copyWith(away: set.away - 1);
    final updatedState = _stateWithUpdatedGames(state, updatedSet);
    emit(updatedState);
    _push();
  }

  void _afterPoint(Emitter<MatchState> emit, MatchState currentState) {
    var stateAfterServer = _maybeRotateServer(currentState);

    emit(stateAfterServer);
    _push(); // This saves the live point score.

    var stateAfterSetCheck = _checkSetEnd(stateAfterServer);

    // We compare them to see if _checkSetEnd did anything.
    if (stateAfterSetCheck != state) {
      // The set or match is over. Emit the final state and push again.
      emit(stateAfterSetCheck);
      _push(); // This saves the result of the completed set/match.

      // If a break should start, we need to explicitly trigger it here
      if (state.isBreakActive) {
        _startBreakTimer();
      }
    }
  }

  MatchState _maybeRotateServer(MatchState currentState) {
    final set = currentState.currentSet!;
    final totalPoints = set.home + set.away;
    final deuceThreshold = (matchType == MatchType.handicap) ? 20 : 10;

    final isDeuce = set.home >= deuceThreshold && set.away >= deuceThreshold;
    final servesPerTurn = isDeuce
        ? 1
        : this.servesPerTurn; // In deuce, serve swaps every point

    bool shouldSwap = totalPoints > 0 && totalPoints % servesPerTurn == 0;

    if (shouldSwap) {
      return currentState.copyWith(
        currentServer: currentState.currentReceiver,
        currentReceiver: currentState.currentServer,
      );
    }
    return currentState;
  }

  MatchState _stateWithUpdatedGames(
    MatchState originalState,
    SetScore updatedSet,
  ) {
    final currentGame = originalState.currentGame!;

    // Create a mutable copy of the sets from the current game
    final updatedSets = List<SetScore>.from(currentGame.sets);

    // Replace the last (active) set with our newly updated set
    if (updatedSets.isNotEmpty) {
      updatedSets[updatedSets.length - 1] = updatedSet;
    }

    // Create an updated Game object with the corrected list of sets
    final updatedGame = currentGame.copyWith(sets: updatedSets);

    // Create an updated master list of all games in the match
    final updatedGames = List<Game>.from(originalState.games);
    final gameIndex = updatedGames.indexWhere(
      (g) => g.order == currentGame.order,
    );

    if (gameIndex != -1) {
      updatedGames[gameIndex] = updatedGame;
    }

    // Return a new state that has BOTH the `currentSet` and `games` list updated.
    return originalState.copyWith(
      currentSet: updatedSet,
      games: updatedGames,
      currentGame: updatedGame,
    );
  }

  MatchState _checkSetEnd(MatchState currentState) {
    final set = currentState.currentSet!;

    final homeScore = set.home;
    final awayScore = set
        .away; // Always get the win condition from the current state for consistency.
    final pointsToWinForSet = currentState.pointsToWin;

    // A set is won if a player reaches the required points AND has a 2-point lead.
    final homeWins =
        homeScore >= pointsToWinForSet && (homeScore - awayScore) >= 2;
    final awayWins =
        awayScore >= pointsToWinForSet && (awayScore - homeScore) >= 2;

    if (homeWins || awayWins) {
      // The set is over. Defer all logic to `_completeSet`.
      return _completeSet(currentState);
    }

    // If the set is not over, return the state unchanged.
    return currentState;
  }

  MatchState _completeSet(MatchState currentState) {
    final currentGame = currentState.currentGame!;
    final currentSet = currentState.currentSet!;
    final homeWonSet = currentSet.home > currentSet.away;

    // --- Boilerplate: Update game and games list with the completed set ---
    final updatedSets = List<SetScore>.from(currentGame.sets);
    updatedSets[updatedSets.length - 1] = currentSet;
    final updatedGame = currentGame.copyWith(sets: updatedSets);

    final updatedGames = List<Game>.from(currentState.games);
    final gameIndex = updatedGames.indexWhere(
      (g) => g.order == currentGame.order,
    );
    if (gameIndex != -1) {
      updatedGames[gameIndex] = updatedGame;
    }
    // --- End Boilerplate ---

    // --- Step 1: Check if the CURRENT GAME is over ---
    // Count how many sets each player has won *in this game*.
    int setsWonHomeInGame = 0;
    int setsWonAwayInGame = 0;
    for (var set in updatedGame.sets) {
      if (set.home > set.away) {
        setsWonHomeInGame++;
      } else if (set.away > set.home) {
        setsWonAwayInGame++;
      }
    }

    final homeWonGame = setsWonHomeInGame >= currentState.setsToWin;
    final awayWonGame = setsWonAwayInGame >= currentState.setsToWin;

    if (homeWonGame || awayWonGame) {
      // ---- GAME IS OVER ----
      // Update the total match score
      int totalMatchGamesWonHome =
          currentState.matchGamesWonHome + (homeWonGame ? 1 : 0);
      int totalMatchGamesWonAway =
          currentState.matchGamesWonAway + (awayWonGame ? 1 : 0);

      // If it's a team match, check if we should move to the next game
      if (currentState.matchType == MatchType.team) {
        final nextGameIndex = gameIndex + 1;
        if (nextGameIndex < updatedGames.length) {
          // There's another game in the team match, prepare for it.
          return currentState.copyWith(
            games: updatedGames,
            currentGame: updatedGames[nextGameIndex],
            currentSet: updatedGames[nextGameIndex].sets.first,
            matchGamesWonHome: totalMatchGamesWonHome,
            matchGamesWonAway: totalMatchGamesWonAway,
            isBreakActive: true, // Start a break between games
            remainingBreakTime: Duration(seconds: TableTennisConfig.setBreak),
          );
        }
      }

      // If it's NOT a team match OR it was the LAST game of a team match, the MATCH is over.
      return currentState.copyWith(
        games: updatedGames,
        currentGame: updatedGame,
        matchGamesWonHome: totalMatchGamesWonHome,
        matchGamesWonAway: totalMatchGamesWonAway,
        isMatchOver: true,
        isBreakActive: false,
      );
    } else {
      // ---- GAME IS NOT OVER, START NEXT SET ----
      final nextSet = SetScore(
        home: currentState.matchType == MatchType.handicap
            ? home.startingPoints
            : 0,
        away: currentState.matchType == MatchType.handicap
            ? away.startingPoints
            : 0,
      );

      // Add the new set to the current game
      final gameForNextSet = updatedGame.copyWith(
        sets: [...updatedGame.sets, nextSet],
      );
      updatedGames[gameIndex] = gameForNextSet;

      return currentState.copyWith(
        games: updatedGames,
        currentGame: gameForNextSet,
        currentSet: nextSet,
        isBreakActive: true, // Start break between sets
        remainingBreakTime: Duration(seconds: TableTennisConfig.setBreak),
        // Note: matchGamesWon counts are NOT updated here
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Server / Doubles
  // ---------------------------------------------------------------------------
  void _onSetServer(SetServer e, Emitter<MatchState> emit) {
    final updatedGame = state.currentGame!.copyWith(
      startingServer: e.server,
      startingReceiver: e.receiver,
    );
    final updatedGames = List<Game>.from(state.games);
    updatedGames[state.games.indexOf(state.currentGame!)] = updatedGame;

    emit(
      state.copyWith(
        currentGame: updatedGame,
        currentServer: e.server,
        currentReceiver: e.receiver,
        serveCount: 0,
      ),
    );

    _push();
  }

  void _onSetDoublesPlayers(SetDoublesPlayers e, Emitter<MatchState> emit) {
    final updatedGame = state.currentGame!.copyWith(
      homePlayers: List.from(e.home),
      awayPlayers: List.from(e.away),
    );
    final updatedGames = List<Game>.from(state.games);
    updatedGames[state.games.indexOf(state.currentGame!)] = updatedGame;

    emit(state.copyWith(currentGame: updatedGame));
    _push();
  }

  // ---------------------------------------------------------------------------
  // Break / Timeout
  // ---------------------------------------------------------------------------
  void _onStartBreak(StartBreak e, Emitter<MatchState> emit) {
    emit(
      state.copyWith(
        isBreakActive: true,
        remainingBreakTime: Duration(seconds: TableTennisConfig.setBreak),
      ),
    );
    _startBreakTimer();
    _push();
  }

  void _onBreakTicked(_BreakTicked e, Emitter<MatchState> emit) {
    final remaining = state.remainingBreakTime;
    if (remaining == null || remaining.inSeconds <= 1) {
      add(EndBreak()); // This is now safe, as we are in a proper event handler
    } else {
      emit(
        state.copyWith(
          remainingBreakTime: remaining - const Duration(seconds: 1),
        ),
      );
      // Optional: call _push() here if you want spectators to see the countdown
    }
  }

  void _onEndBreak(EndBreak e, Emitter<MatchState> emit) {
    _breakTimer?.cancel(); // Important: cancel the timer
    emit(state.copyWith(isBreakActive: false, remainingBreakTime: null));
    _push();
  }

  void _onStartTimeout(StartTimeout e, Emitter<MatchState> emit) {
    emit(
      state.copyWith(
        isTimeoutActive: true,
        timeoutCalledByHome: e.isHome,
        remainingTimeoutTime: Duration(seconds: TableTennisConfig.timeoutTimer),
      ),
    );
    _startTimeoutTimer(); // Note: we no longer pass `emit` or `isHome`
    _push();
  }

  void _onTimeoutTicked(_TimeoutTicked e, Emitter<MatchState> emit) {
    final remaining = state.remainingTimeoutTime;
    if (remaining == null || remaining.inSeconds <= 1) {
      add(EndTimeout()); // This is now safe
    } else {
      emit(
        state.copyWith(
          remainingTimeoutTime: remaining - const Duration(seconds: 1),
        ),
      );
      // Optional: call _push() here
    }
  }

  void _onEndTimeout(EndTimeout e, Emitter<MatchState> emit) {
    _timeoutTimer?.cancel(); // Important: cancel the timer
    emit(state.copyWith(isTimeoutActive: false, remainingTimeoutTime: null));
    _push();
  }

  // ---------------------------------------------------------------------------
  // Next Game
  // ---------------------------------------------------------------------------
  void _onStartNextGame(StartNextGame e, Emitter<MatchState> emit) {
    emit(
      state.copyWith(
        isNextGameReady: false,
        isTransitioning: false,
        lastGameResult: null,
      ),
    );
    _push();
  }

  // ---------------------------------------------------------------------------
  // Timers
  // ---------------------------------------------------------------------------
  void _startBreakTimer() {
    _breakTimer?.cancel();
    // The timer's ONLY job is to add a `_BreakTicked` event every second.
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(_BreakTicked());
    });
  }

  void _startTimeoutTimer() {
    // No longer needs parameters
    _timeoutTimer?.cancel();
    // The timer's ONLY job is to add a `_TimeoutTicked` event every second.
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(_TimeoutTicked());
    });
  }

  bool get isMatchComplete {
    final requiredGames = setsToWin;
    return matchGamesWonHome == requiredGames ||
        matchGamesWonAway == requiredGames;
  }

  // ---------------------------------------------------------------------------
  // Firestore push
  // ---------------------------------------------------------------------------
  void _push() {
    if (isObserver) return;
    _matches.doc(matchId).set(_toMap(), SetOptions(merge: true));
  }

  Map<String, dynamic> _toMap() {
    final currentGameIndex = state.games.indexOf(
      state.currentGame ?? state.games.first,
    );
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
      'games': state.games.map((g) => g.toMap()).toList(),
      'currentGameIndex': currentGameIndex,
      'matchGamesWonHome': state.matchGamesWonHome,
      'matchGamesWonAway': state.matchGamesWonAway,
      'isBreakActive': state.isBreakActive,
      'isTimeoutActive': state.isTimeoutActive,
      'isMatchOver': state.isMatchOver,
      'timeout': {
        'isActive': state.isTimeoutActive,
        'team': state.timeoutCalledByHome ? 'home' : 'away',
        'remainingSeconds': state.remainingTimeoutTime?.inSeconds ?? 0,
      },
      'break': {
        'isActive': state.isBreakActive,
        'remainingSeconds': state.remainingBreakTime?.inSeconds ?? 0,
      },
      'currentServer': state.currentServer?.name,
      'currentReceiver': state.currentReceiver?.name,
      'serveCount': state.serveCount,
      'deuce': state.deuce,
      'isTransitioning': state.isTransitioning,
      'isNextGameReady': state.isNextGameReady,
      'lastGameResult': state.lastGameResult,
    };
  }

  void _updateFromMap(Map<String, dynamic> data, Emitter<MatchState> emit) {
    final gamesData =
        (data['games'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final games = gamesData.isNotEmpty
        ? List.generate(gamesData.length, (i) => Game.fromMap(gamesData[i]))
        : state.games;

    int gameIndex = data['currentGameIndex'] ?? 0;
    if (games.isNotEmpty) gameIndex = gameIndex.clamp(0, games.length - 1);
    final currentGame = games.isNotEmpty ? games[gameIndex] : null;
    final currentSet = currentGame?.sets.isNotEmpty == true
        ? currentGame!.sets.last
        : null;

    final breakData = data['break'] as Map<String, dynamic>? ?? {};
    final timeoutData = data['timeout'] as Map<String, dynamic>? ?? {};

    emit(
      state.copyWith(
        games: games,
        currentGame: currentGame,
        currentSet: currentSet,
        isBreakActive: breakData['isActive'] ?? false,
        remainingBreakTime: Duration(
          seconds: breakData['remainingSeconds'] ?? 0,
        ),
        isTimeoutActive: timeoutData['isActive'] ?? false,
        timeoutCalledByHome: timeoutData['team'] == 'home',
        remainingTimeoutTime: Duration(
          seconds: timeoutData['remainingSeconds'] ?? 0,
        ),
        currentServer: data['currentServer'] != null
            ? Player(data['currentServer'])
            : null,
        currentReceiver: data['currentReceiver'] != null
            ? Player(data['currentReceiver'])
            : null,
        serveCount: data['serveCount'] ?? state.serveCount,
        deuce: data['deuce'] ?? state.deuce,
        matchGamesWonHome: data['matchGamesWonHome'] ?? state.matchGamesWonHome,
        matchGamesWonAway: data['matchGamesWonAway'] ?? state.matchGamesWonAway,
        isTransitioning: data['isTransitioning'] ?? state.isTransitioning,
        isNextGameReady: data['isNextGameReady'] ?? state.isNextGameReady,
        lastGameResult: data['lastGameResult'] != null
            ? Map<String, dynamic>.from(data['lastGameResult'])
            : state.lastGameResult,
      ),
    );
  }

  @override
  Future<void> close() {
    _breakTimer?.cancel();
    _timeoutTimer?.cancel();
    _firestoreSub?.cancel();
    _matchStateManager.stopControlling();
    return super.close();
  }
}
