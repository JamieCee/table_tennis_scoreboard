import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:table_tennis_scoreboard/shared/configuration.dart';
import 'package:url_launcher/url_launcher.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc() : super(SubscriptionInitial()) {
    on<SubscribeButtonPressed>(_onSubscribeButtonPressed);
  }

  Future<void> _onSubscribeButtonPressed(
    SubscribeButtonPressed event,
    Emitter<SubscriptionState> emit,
  ) async {
    final Uri url = Uri.parse(TableTennisConfig.subscribeUrl);

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        // If launchUrl returns false, emit a failure state.
        emit(SubscriptionLaunchUrlFailure('Could not launch ${url.path}'));
      }
      // If successful, we can just revert to the initial state,
      // as there's no ongoing process to track.
      emit(SubscriptionInitial());
    } catch (e) {
      // Catch any other potential exceptions during the launch.
      emit(SubscriptionLaunchUrlFailure('An unexpected error occurred: $e'));
    }
  }
}
