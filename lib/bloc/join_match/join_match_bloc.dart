import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_tennis_scoreboard/bloc/match/match_bloc.dart';
import 'package:table_tennis_scoreboard/models/player.dart';
import 'package:table_tennis_scoreboard/models/team.dart';
import 'package:table_tennis_scoreboard/services/match_firestore_service.dart';
import 'package:table_tennis_scoreboard/services/match_state_manager.dart';

part 'join_match_event.dart';
part 'join_match_state.dart';

class JoinMatchBloc extends Bloc<JoinMatchEvent, JoinMatchState> {
  final MatchStateManager _matchStateManager;

  JoinMatchBloc({required MatchStateManager matchStateManager})
    : _matchStateManager = matchStateManager,
      super(JoinMatchInitial()) {
    on<JoinMatchRequested>(_onJoinMatchRequested);
  }

  Future<void> _onJoinMatchRequested(
    JoinMatchRequested event,
    Emitter<JoinMatchState> emit,
  ) async {
    if (event.matchId.isEmpty) {
      emit(const JoinMatchFailure("Please enter a game code."));
      await Future.delayed(const Duration(seconds: 2));
      emit(JoinMatchInitial());
      return;
    }

    emit(JoinMatchLoading());

    try {
      final doc = await MatchFirestoreService(
        event.matchId,
      ).streamMatch().first;
      if (!doc.exists) {
        emit(const JoinMatchFailure("Match not found."));
        await Future.delayed(const Duration(seconds: 2));
        emit(JoinMatchInitial());
        return;
      }

      final data = doc.data()!;
      final homeTeamData = data['home'] as Map<String, dynamic>;
      final awayTeamData = data['away'] as Map<String, dynamic>;

      final homeTeam = Team(
        name: homeTeamData['name'] as String,
        players: (homeTeamData['players'] as List)
            .map((p) => Player(p))
            .toList(),
      );

      final awayTeam = Team(
        name: awayTeamData['name'] as String,
        players: (awayTeamData['players'] as List)
            .map((p) => Player(p))
            .toList(),
      );

      final matchTypeString = data['matchType'] as String?;
      final setsToWin = data['setsToWin'] as int? ?? 3;

      final MatchType matchType;
      if (matchTypeString == 'MatchType.singles') {
        matchType = MatchType.singles;
      } else if (matchTypeString == 'MatchType.handicap') {
        matchType = MatchType.handicap;
      } else {
        matchType = MatchType.team;
      }

      final handicapData = data['handicapDetails'] as Map<String, dynamic>?;

      // Convert dynamic values to int
      final handicapDetails = handicapData?.map(
        (key, value) => MapEntry(key, value as int),
      );

      // Create a new MatchBloc for this match in OBSERVER mode
      final matchBloc = MatchBloc(
        matchId: event.matchId,
        home: homeTeam,
        away: awayTeam,
        isObserver: true,
        matchType: matchType,
        setsToWin: setsToWin,
        matchStateManager: _matchStateManager,
      );

      // Save the active match ID locally so we can resume later if needed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('activeMatchId', event.matchId);

      // Start managing state
      // _matchStateManager.startObserving();

      emit(JoinMatchSuccess(matchBloc: matchBloc));
    } catch (e) {
      if (kDebugMode) print(e);
      emit(
        const JoinMatchFailure(
          "Failed to join match. An unexpected error occurred.",
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      emit(JoinMatchInitial());
    }
  }
}
