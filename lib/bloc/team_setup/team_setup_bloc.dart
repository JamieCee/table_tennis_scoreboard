// lib/bloc/team_setup/team_setup_bloc.dart
import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_tennis_scoreboard/controllers/match_controller.dart';
import 'package:table_tennis_scoreboard/models/player.dart';
import 'package:table_tennis_scoreboard/models/team.dart';
import 'package:table_tennis_scoreboard/services/match_state_manager.dart';

part 'team_setup_event.dart';
part 'team_setup_state.dart';

class TeamSetupBloc extends Bloc<TeamSetupEvent, TeamSetupState> {
  final MatchStateManager _matchStateManager;

  TeamSetupBloc({required MatchStateManager matchStateManager})
    : _matchStateManager = matchStateManager,
      super(const TeamSetupState()) {
    on<MatchTypeChanged>(_onMatchTypeChanged);
    on<SetsToWinChanged>(
      (event, emit) => emit(state.copyWith(setsToWin: event.setsToWin)),
    );
    on<HandicapPlayerChanged>(
      (event, emit) =>
          emit(state.copyWith(handicapPlayerIndex: event.playerIndex)),
    );
    on<HandicapPointsChanged>(
      (event, emit) => emit(state.copyWith(handicapPoints: event.points)),
    );
    on<StartMatchSubmitted>(_onStartMatchSubmitted);
    on<NameChanged>(_onNameChanged);
  }

  void _onNameChanged(NameChanged event, Emitter<TeamSetupState> emit) {
    emit(
      state.copyWith(
        homeTeamName: event.homeTeamName,
        awayTeamName: event.awayTeamName,
        homePlayerNames: event.homePlayerNames,
        awayPlayerNames: event.awayPlayerNames,
      ),
    );
  }

  void _onMatchTypeChanged(
    MatchTypeChanged event,
    Emitter<TeamSetupState> emit,
  ) {
    int newSetsToWin = (event.matchType == MatchType.team) ? 3 : 2;
    emit(
      state.copyWith(
        matchType: event.matchType,
        setsToWin: newSetsToWin,
        handicapPoints: event.matchType != MatchType.handicap
            ? 0
            : state.handicapPoints,
      ),
    );
  }

  String _generateMatchId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> _onStartMatchSubmitted(
    StartMatchSubmitted event,
    Emitter<TeamSetupState> emit,
  ) async {
    // For singles or handicap, only the first player name is required
    if (state.matchType != MatchType.team) {
      if (state.homePlayerNames.first.trim().isEmpty ||
          state.awayPlayerNames.first.trim().isEmpty) {
        emit(
          state.copyWith(
            status: TeamSetupStatus.failure,
            errorMessage: () => "Player names cannot be empty.",
          ),
        );
        // Reset status after a moment to allow the user to see the message and retry
        await Future.delayed(const Duration(seconds: 2));
        emit(state.copyWith(status: TeamSetupStatus.initial));
        return; // Stop execution
      }
    } else {
      // For a team match, all player names are required
      final allHomePlayersValid = state.homePlayerNames.every(
        (name) => name.trim().isNotEmpty,
      );
      final allAwayPlayersValid = state.awayPlayerNames.every(
        (name) => name.trim().isNotEmpty,
      );

      if (!allHomePlayersValid || !allAwayPlayersValid) {
        emit(
          state.copyWith(
            status: TeamSetupStatus.failure,
            errorMessage: () =>
                "All player names are required for a team match.",
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        emit(state.copyWith(status: TeamSetupStatus.initial));
        return; // Stop execution
      }
    }

    emit(state.copyWith(status: TeamSetupStatus.loading));

    try {
      final homePlayers = (state.matchType == MatchType.team)
          ? state.homePlayerNames.map((name) => Player(name)).toList()
          : [Player(state.homePlayerNames.first)];

      final awayPlayers = (state.matchType == MatchType.team)
          ? state.awayPlayerNames.map((name) => Player(name)).toList()
          : [Player(state.awayPlayerNames.first)];

      final home = Team(
        name: (state.matchType == MatchType.team)
            ? state.homeTeamName
            : homePlayers.first.name,
        players: homePlayers,
      );
      final away = Team(
        name: (state.matchType == MatchType.team)
            ? state.awayTeamName
            : awayPlayers.first.name,
        players: awayPlayers,
      );
      final matchId = _generateMatchId();

      final controller = MatchController(
        home: home,
        away: away,
        matchId: matchId,
        matchType: state.matchType,
        setsToWin: state.setsToWin,
        handicapDetails: (state.matchType == MatchType.handicap)
            ? {
                'playerIndex': state.handicapPlayerIndex,
                'points': state.handicapPoints.toInt(),
              }
            : null,
        matchStateManager: _matchStateManager,
      );

      await controller.createMatchInFirestore();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('activeMatchId', matchId);

      _matchStateManager.startControlling();

      emit(
        state.copyWith(
          status: TeamSetupStatus.success,
          matchController: () => controller,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: TeamSetupStatus.failure,
          errorMessage: () => e.toString(),
        ),
      );
      // Reset status after failure to allow retry
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: TeamSetupStatus.initial));
    }
  }
}
