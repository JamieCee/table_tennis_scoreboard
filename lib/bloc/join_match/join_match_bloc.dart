import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:table_tennis_scoreboard/controllers/match_controller.dart';
import 'package:table_tennis_scoreboard/models/player.dart';
import 'package:table_tennis_scoreboard/models/team.dart';
import 'package:table_tennis_scoreboard/services/match_firestore_service.dart';

part 'join_match_event.dart';
part 'join_match_state.dart';

class JoinMatchBloc extends Bloc<JoinMatchEvent, JoinMatchState> {
  JoinMatchBloc() : super(JoinMatchInitial()) {
    on<JoinMatchRequested>(_onJoinMatchRequested);
  }

  Future<void> _onJoinMatchRequested(
    JoinMatchRequested event,
    Emitter<JoinMatchState> emit,
  ) async {
    if (event.matchId.isEmpty) {
      emit(const JoinMatchFailure("Please enter a game code."));
      // Revert back to initial after a validation error
      // so the user can try again without being stuck in a failure state.
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
        return;
      }

      final data = doc.data()!;
      final homeTeam = data['home'];
      final awayTeam = data['away'];
      final matchTypeString = data['matchType'] as String?;
      final setsToWin = data['setsToWin'] as int?;

      MatchType matchType;
      if (matchTypeString == 'MatchType.singles') {
        matchType = MatchType.singles;
      } else if (matchTypeString == 'MatchType.handicap') {
        matchType = MatchType.handicap;
      } else {
        matchType = MatchType.team;
      }

      final controller = MatchController(
        home: Team(
          name: homeTeam['name'],
          players: (homeTeam['players'] as List).map((p) => Player(p)).toList(),
        ),
        away: Team(
          name: awayTeam['name'],
          players: (awayTeam['players'] as List).map((p) => Player(p)).toList(),
        ),
        matchId: event.matchId,
        isObserver: true, // OBSERVER MODE
        matchType: matchType,
        setsToWin: setsToWin ?? 3,
      );

      emit(JoinMatchSuccess(controller: controller));
    } catch (e) {
      emit(
        const JoinMatchFailure(
          "Failed to join match. An unexpected error occurred.",
        ),
      );
    }
  }
}
