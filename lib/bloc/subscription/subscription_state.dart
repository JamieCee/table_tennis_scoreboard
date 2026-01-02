part of 'subscription_bloc.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object> get props => [];
}

// The initial state of the screen.
class SubscriptionInitial extends SubscriptionState {}

// A state to represent a failure to launch the URL.
class SubscriptionLaunchUrlFailure extends SubscriptionState {
  final String errorMessage;

  const SubscriptionLaunchUrlFailure(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
