import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'match_check_event.dart';
part 'match_check_state.dart';

class MatchCheckBloc extends Bloc<MatchCheckEvent, MatchCheckState> {
  MatchCheckBloc() : super(MatchCheckInitial()) {
    on<CheckForActiveMatch>(_onCheckForActiveMatch);
    on<DiscardActiveMatch>(_onDiscardActiveMatch);
  }

  Future<void> _onCheckForActiveMatch(
    CheckForActiveMatch event,
    Emitter<MatchCheckState> emit,
  ) async {
    emit(MatchCheckInProgress());
    try {
      final prefs = await SharedPreferences.getInstance();
      final matchId = prefs.getString('activeMatchId');

      if (matchId == null) {
        emit(NoActiveMatch());
        return;
      }

      final matchDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .get();

      if (!matchDoc.exists || (matchDoc.data()?['isMatchOver'] ?? false)) {
        await prefs.remove('activeMatchId');
        emit(NoActiveMatch());
      } else {
        emit(ActiveMatchFound(matchId: matchId, matchData: matchDoc.data()!));
      }
    } catch (e) {
      emit(MatchCheckError("Failed to check for active match: $e"));
    }
  }

  Future<void> _onDiscardActiveMatch(
    DiscardActiveMatch event,
    Emitter<MatchCheckState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('activeMatchId');

      await FirebaseFirestore.instance
          .collection('matches')
          .doc(event.matchId)
          .delete();

      emit(NoActiveMatch());
    } catch (e) {
      emit(MatchCheckError("Failed to discard match: $e"));
    }
  }
}
