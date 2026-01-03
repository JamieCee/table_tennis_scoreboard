import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_tennis_scoreboard/controllers/match_controller.dart';
import 'package:table_tennis_scoreboard/models/game.dart';
import 'package:table_tennis_scoreboard/models/player.dart';
import 'package:table_tennis_scoreboard/models/set_score.dart';
import 'package:table_tennis_scoreboard/models/team.dart';
import 'package:table_tennis_scoreboard/services/match_state_manager.dart';
import 'package:table_tennis_scoreboard/shared/configuration.dart';

part 'match_controller_event.dart';
part 'match_controller_state.dart';

class MatchControllerBloc
    extends Bloc<MatchControllerEvent, MatchControllerState> {
  final String matchId;
  final Team home;
  final Team away;
  final bool isObserver;
  final MatchType matchType;
  final int setsToWin;
  final MatchStateManager _matchStateManager;
  final Map<String, int>? handicapDetails;

  late final CollectionReference _matchesCollection;

  Timer? _breakTimer;
  Timer? _timeoutTimer;

  MatchControllerBloc({
    required this.home,
    required this.away,
    required this.matchId,
    this.isObserver = false,
    this.matchType = MatchType.team,
    this.setsToWin = 3,
    this.handicapDetails,
    required MatchStateManager matchStateManager,
  }) : _matchStateManager = matchStateManager,
       super(
         MatchControllerState.initial(
           home: home,
           away: away,
           matchType: matchType,
           setsToWin: setsToWin,
           handicapDetails: handicapDetails,
           isObserver: isObserver,
         ),
       ) {
    _matchesCollection = FirebaseFirestore.instance.collection('matches');

    on<InitializeMatch>(_onInitializeMatch);
    on<ResumeMatch>(_onResumeMatch);
    on<AddPointHome>(_onAddPointHome);
    on<AddPointAway>(_onAddPointAway);
    on<UndoPointHome>(_onUndoPointHome);
    on<UndoPointAway>(_onUndoPointAway);
    on<StartBreak>(_onStartBreak);
    on<EndBreak>(_onEndBreak);
    on<StartTimeout>(_onStartTimeout);
    on<EndTimeout>(_onEndTimeout);
    on<SetServer>(_onSetServer);
    on<SetDoublesPlayers>(_onSetDoublesPlayers);
    on<StartNextGame>(_onStartNextGame);
    on<DeleteMatch>(_onDeleteMatch);
    on<UpdateFromMap>(_onUpdateFromMap);

    // Listen to Firestore changes
    _listenToFirestore();

    if (!isObserver) _matchStateManager.startControlling();
  }

  // ------------------------
  // Event Handlers
  // ------------------------
  void _onInitializeMatch(
    InitializeMatch event,
    Emitter<MatchControllerState> emit,
  ) {
    final initialGames = _initializeGames();
    final currentGame = initialGames.first;
    final currentSet = currentGame.sets.last;

    emit(
      state.copyWith(
        games: initialGames,
        currentGame: currentGame,
        currentSet: currentSet,
      ),
    );

    if (!isObserver) _createMatchInFirestore();
  }

  void _onResumeMatch(ResumeMatch event, Emitter<MatchControllerState> emit) {
    _resumeFromData(event.resumeData, emit);
  }

  void _onAddPointHome(AddPointHome event, Emitter<MatchControllerState> emit) {
    if (!state.isGameEditable) return;

    final updatedSet = state.currentSet!.copyWith(
      home: state.currentSet!.home + 1,
    );

    // Chain helpers
    var newState = state.copyWith(currentSet: updatedSet);
    newState = _maybeRotateServer(newState);
    newState = _checkSetEnd(newState); // returns updated state
    emit(newState);

    // Firestore push after emit
    _pushToFirestore();
  }

  void _onAddPointAway(AddPointAway event, Emitter<MatchControllerState> emit) {
    if (!state.isGameEditable) return;
    final updatedSet = state.currentSet!.copyWith(
      away: state.currentSet!.away + 1,
    );
    _afterPoint(updatedSet, emit);
  }

  void _onUndoPointHome(
    UndoPointHome event,
    Emitter<MatchControllerState> emit,
  ) {
    if (!state.isGameEditable || state.currentSet!.home == 0) return;
    final updatedSet = state.currentSet!.copyWith(
      home: state.currentSet!.home - 1,
    );
    emit(state.copyWith(currentSet: updatedSet));
    _pushToFirestore();
  }

  void _onUndoPointAway(
    UndoPointAway event,
    Emitter<MatchControllerState> emit,
  ) {
    if (!state.isGameEditable || state.currentSet!.away == 0) return;
    final updatedSet = state.currentSet!.copyWith(
      away: state.currentSet!.away - 1,
    );
    emit(state.copyWith(currentSet: updatedSet));
    _pushToFirestore();
  }

  Future<void> _afterPoint(
    SetScore updatedSet,
    Emitter<MatchControllerState> emit,
  ) async {
    if (!state.isGameEditable) return;

    // Update the set first
    var newState = state.copyWith(currentSet: updatedSet);

    // Rotate server & check set end
    newState = _maybeRotateServer(newState);
    newState = _checkSetEnd(newState);

    emit(newState);

    // Firestore update
    await _pushToFirestoreAsync(newState);
  }

  Future<void> _pushToFirestoreAsync(MatchControllerState s) async {
    if (isObserver) return;
    await _matchesCollection
        .doc(matchId)
        .set(s.toMap(), SetOptions(merge: true));
  }

  MatchControllerState _maybeRotateServer(MatchControllerState s) {
    final totalPoints = s.currentSet!.home + s.currentSet!.away;
    final deuceThreshold = (matchType == MatchType.handicap) ? 20 : 10;
    final isDeuce =
        s.currentSet!.home >= deuceThreshold &&
        s.currentSet!.away >= deuceThreshold;

    var newState = s.copyWith(deuce: isDeuce);

    if (isDeuce || (totalPoints > 0 && totalPoints % s.servesPerTurn == 0)) {
      final temp = newState.currentServer;
      newState = newState.copyWith(
        currentServer: newState.currentReceiver,
        currentReceiver: temp,
      );
    }

    return newState;
  }

  MatchControllerState _checkSetEnd(MatchControllerState s) {
    final home = s.currentSet!.home;
    final away = s.currentSet!.away;
    var newState = s;

    if ((home >= s.pointsToWin || away >= s.pointsToWin) &&
        (home - away).abs() >= 2) {
      final newSetsWonHome = s.currentGame!.setsWonHome + (home > away ? 1 : 0);
      final newSetsWonAway = s.currentGame!.setsWonAway + (away > home ? 1 : 0);
      final updatedGame = s.currentGame!.copyWith(
        setsWonHome: newSetsWonHome,
        setsWonAway: newSetsWonAway,
      );

      newState = newState.copyWith(currentGame: updatedGame);

      // Handle match/game completion here if needed
    }

    return newState;
  }

  void _completeGame(Game completedGame, Emitter<MatchControllerState> emit) {
    final newHomeMatches =
        state.matchGamesWonHome +
        (completedGame.setsWonHome > completedGame.setsWonAway ? 1 : 0);
    final newAwayMatches =
        state.matchGamesWonAway +
        (completedGame.setsWonAway > completedGame.setsWonHome ? 1 : 0);

    final lastGameResult = {
      'homeScore': completedGame.setsWonHome,
      'awayScore': completedGame.setsWonAway,
      'setScores': completedGame.sets
          .map((s) => {'home': s.home, 'away': s.away})
          .toList(),
    };

    emit(
      state.copyWith(
        matchGamesWonHome: newHomeMatches,
        matchGamesWonAway: newAwayMatches,
        lastGameResult: lastGameResult,
        currentGame: completedGame,
      ),
    );

    if (!state.isMatchOver && completedGame.order < state.games.length) {
      emit(
        state.copyWith(
          nextGamePreview: state.games[completedGame.order],
          isTransitioning: true,
          isNextGameReady: true,
        ),
      );
    } else if (state.isMatchOver) {
      _matchStateManager.stopControlling();
      _clearActiveMatchId();
    }

    _pushToFirestore();
  }

  // ------------------------
  // Firestore Helpers
  // ------------------------
  void _listenToFirestore() {
    _matchesCollection.doc(matchId).snapshots().listen((snapshot) {
      if (!snapshot.exists) return;
      add(UpdateFromMap(snapshot.data() as Map<String, dynamic>));
    });
  }

  void _pushToFirestore() {
    if (isObserver) return;
    _matchesCollection.doc(matchId).set(state.toMap(), SetOptions(merge: true));
  }

  Future<void> _createMatchInFirestore() async {
    await _matchesCollection.doc(matchId).set(state.toMap());
  }

  Future<void> _clearActiveMatchId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeMatchId');
  }

  // ------------------------
  // Helper for initializing games
  // ------------------------
  List<Game> _initializeGames() {
    List<Game> games = [];
    if (matchType == MatchType.handicap || matchType == MatchType.singles) {
      final game = Game(
        order: 1,
        isDoubles: false,
        homePlayers: [home.players[0]],
        awayPlayers: [away.players[0]],
      );
      game.sets.clear();
      game.sets.add(SetScore());
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
    return games;
  }

  // Break
  void _onStartBreak(StartBreak event, Emitter<MatchControllerState> emit) {
    if (state.isObserver) return;
    emit(
      state.copyWith(
        isBreakActive: true,
        remainingBreakTime: Duration(seconds: TableTennisConfig.setBreak),
      ),
    );

    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.remainingBreakTime!.inSeconds - 1;
      if (remaining <= 0) {
        timer.cancel();
        add(EndBreak());
      } else {
        emit(state.copyWith(remainingBreakTime: Duration(seconds: remaining)));
        _pushToFirestore();
      }
    });
    _pushToFirestore();
  }

  void _onEndBreak(EndBreak event, Emitter<MatchControllerState> emit) {
    _breakTimer?.cancel();
    emit(state.copyWith(isBreakActive: false, remainingBreakTime: null));
    _createNewSet(emit);
  }

  // Timeout
  void _onStartTimeout(StartTimeout event, Emitter<MatchControllerState> emit) {
    if (state.isObserver || state.isTimeoutActive) return;

    int remainingSeconds = TableTennisConfig.timeoutTimer;

    emit(
      state.copyWith(
        isTimeoutActive: true,
        timeoutCalledByHome: event.isHome,
        remainingTimeoutTime: Duration(seconds: remainingSeconds),
      ),
    );

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      remainingSeconds--;

      if (remainingSeconds <= 0) {
        timer.cancel();
        add(EndTimeout());
      } else {
        emit(
          state.copyWith(
            remainingTimeoutTime: Duration(seconds: remainingSeconds),
          ),
        );
        await _pushToFirestoreAsync(
          state.copyWith(
            remainingTimeoutTime: Duration(seconds: remainingSeconds),
          ),
        );
      }
    });
  }

  void _onEndTimeout(EndTimeout event, Emitter<MatchControllerState> emit) {
    _timeoutTimer?.cancel();
    emit(state.copyWith(isTimeoutActive: false, remainingTimeoutTime: null));
  }

  // Server
  void _onSetServer(SetServer event, Emitter<MatchControllerState> emit) {
    if (state.isObserver) return;
    final server = event.server;
    final receiver = event.receiver;
    _setFirstServerOfSet(server, receiver, emit);
  }

  // Doubles players
  void _onSetDoublesPlayers(
    SetDoublesPlayers event,
    Emitter<MatchControllerState> emit,
  ) {
    if (state.isObserver) return;
    final game = state.currentGame!;
    final updatedGame = game.copyWith(
      homePlayers: event.home,
      awayPlayers: event.away,
    );
    emit(state.copyWith(currentGame: updatedGame));
    _pushToFirestore();
  }

  // Start next game
  void _onStartNextGame(
    StartNextGame event,
    Emitter<MatchControllerState> emit,
  ) {
    final next = state.nextGamePreview;
    if (next == null || state.isObserver) return;

    emit(
      state.copyWith(
        currentGame: next,
        currentSet: next.sets.last,
        isTransitioning: false,
        isNextGameReady: false,
        nextGamePreview: null,
        lastGameResult: null,
      ),
    );

    _pushToFirestore();
  }

  // Delete match
  void _onDeleteMatch(
    DeleteMatch event,
    Emitter<MatchControllerState> emit,
  ) async {
    if (state.isObserver) return;
    _matchStateManager.stopControlling();
    await _matchesCollection.doc(matchId).delete();
  }

  // Firestore update
  void _onUpdateFromMap(
    UpdateFromMap event,
    Emitter<MatchControllerState> emit,
  ) {
    final data = event.data;
    final gamesData =
        (data['games'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final games = gamesData.map((g) => Game.fromMap(g)).toList();

    final gameIndex = (data['currentGameIndex'] ?? 0).clamp(
      0,
      games.length - 1,
    );
    final currentGame = games.isNotEmpty ? games[gameIndex] : null;
    final currentSet = currentGame != null && currentGame.sets.isNotEmpty
        ? currentGame.sets.last
        : null;

    emit(
      state.copyWith(
        games: games,
        currentGame: currentGame,
        currentSet: currentSet,
        matchGamesWonHome: data['matchGamesWonHome'] ?? state.matchGamesWonHome,
        matchGamesWonAway: data['matchGamesWonAway'] ?? state.matchGamesWonAway,
        isBreakActive: (data['break']?['isActive'] ?? false),
        remainingBreakTime: Duration(
          seconds: data['break']?['remainingSeconds'] ?? 0,
        ),
        isTimeoutActive: (data['timeout']?['isActive'] ?? false),
        timeoutCalledByHome: (data['timeout']?['team'] ?? 'home') == 'home',
        remainingTimeoutTime: Duration(
          seconds: data['timeout']?['remainingSeconds'] ?? 0,
        ),
        currentServer: data['currentServer'] != null
            ? Player(data['currentServer'])
            : null,
        currentReceiver: data['currentReceiver'] != null
            ? Player(data['currentReceiver'])
            : null,
        serveCount: data['serveCount'] ?? state.serveCount,
        deuce: data['deuce'] ?? state.deuce,
        isTransitioning: data['isTransitioning'] ?? state.isTransitioning,
        isNextGameReady: data['isNextGameReady'] ?? state.isNextGameReady,
        lastGameResult: data['lastGameResult'] != null
            ? Map<String, dynamic>.from(data['lastGameResult'])
            : state.lastGameResult,
      ),
    );
  }

  // 1. Create a new set
  void _createNewSet(Emitter<MatchControllerState> emit) {
    final currentGame = state.currentGame!;
    final newSet = SetScore();

    // Handle handicap details if available
    if (state.matchType == MatchType.handicap &&
        state.handicapDetails != null) {
      final playerIndex = state.handicapDetails!['playerIndex']!;
      final points = state.handicapDetails!['points']!;
      if (playerIndex == 0) {
        newSet.home = points;
      } else {
        newSet.away = points;
      }
    }

    final updatedSets = List<SetScore>.from(currentGame.sets)..add(newSet);
    final updatedGame = currentGame.copyWith(sets: updatedSets);
    emit(state.copyWith(currentGame: updatedGame, currentSet: newSet));
  }

  // 2. Set the first server for a set
  void _setFirstServerOfSet(
    Player? server,
    Player? receiver,
    Emitter<MatchControllerState> emit,
  ) {
    final currentGame = state.currentGame!;
    if (server == null || receiver == null) return;

    Player firstServer = server;
    Player firstReceiver = receiver;

    if (!currentGame.isDoubles && (currentGame.sets.length - 1) % 2 != 0) {
      firstServer = receiver;
      firstReceiver = server;
    }

    emit(
      state.copyWith(
        currentGame: currentGame.copyWith(
          startingServer: firstServer,
          startingReceiver: firstReceiver,
        ),
        currentServer: firstServer,
        currentReceiver: firstReceiver,
        serveCount: 0,
      ),
    );
  }

  // 3. Resume from saved data
  void _resumeFromData(
    Map<String, dynamic> data,
    Emitter<MatchControllerState> emit,
  ) {
    final gamesData =
        (data['games'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final games = gamesData.map((g) => Game.fromMap(g)).toList();

    final gameIndex = (data['currentGameIndex'] ?? 0).clamp(
      0,
      games.length - 1,
    );
    final currentGame = games.isNotEmpty ? games[gameIndex] : null;
    final currentSet = currentGame?.sets.last;

    emit(
      state.copyWith(
        games: games,
        currentGame: currentGame,
        currentSet: currentSet,
        matchGamesWonHome: data['matchGamesWonHome'] ?? 0,
        matchGamesWonAway: data['matchGamesWonAway'] ?? 0,
        currentServer: data['currentServer'] != null
            ? Player(data['currentServer'])
            : null,
        currentReceiver: data['currentReceiver'] != null
            ? Player(data['currentReceiver'])
            : null,
        serveCount: data['serveCount'] ?? 0,
        deuce: data['deuce'] ?? false,
        isBreakActive: data['break']?['isActive'] ?? false,
        remainingBreakTime: Duration(
          seconds: data['break']?['remainingSeconds'] ?? 0,
        ),
        isTimeoutActive: data['timeout']?['isActive'] ?? false,
        timeoutCalledByHome: (data['timeout']?['team'] ?? 'home') == 'home',
        remainingTimeoutTime: Duration(
          seconds: data['timeout']?['remainingSeconds'] ?? 0,
        ),
        isTransitioning: data['isTransitioning'] ?? false,
        isNextGameReady: data['isNextGameReady'] ?? false,
        lastGameResult: data['lastGameResult'] != null
            ? Map<String, dynamic>.from(data['lastGameResult'])
            : null,
      ),
    );
  }
}

/// ------------------------
/// SetScore copyWith extension
/// ------------------------
extension SetScoreCopy on SetScore {
  SetScore copyWith({int? home, int? away}) {
    return SetScore(home: home ?? this.home, away: away ?? this.away);
  }
}
