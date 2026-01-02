import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:table_tennis_scoreboard/models/token_response.dart';
import 'package:table_tennis_scoreboard/services/api/auth_service.dart';
import 'package:table_tennis_scoreboard/services/api/chopper_client.dart';
import 'package:table_tennis_scoreboard/services/auth_manager.dart';
import 'package:table_tennis_scoreboard/services/secure_storage.dart';

part 'auth_event.dart';
part 'auth_state.dart';

// This enum can replace the one in your old AuthController
enum LoginResult { success, invalidCredentials, unknownError }

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final SecureStorage _storage;
  final AuthManager _authManager;

  AuthBloc({
    required AuthManager authManager,
    AuthService? authService,
    SecureStorage? storage,
  }) : _authManager = authManager,
       _authService = authService ?? ApiClient.client.getService<AuthService>(),
       _storage = storage ?? SecureStorage(),
       super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authService.authentication({
        'grant_type': 'password',
        'username': event.email, // Use event data
        'password': event.password, // Use event data
        'client_id': ApiClient.clientId,
        'client_secret': ApiClient.clientSecret,
      });

      if (!response.isSuccessful) {
        emit(const AuthFailure('Invalid username or password.'));
        return;
      }

      final token = TokenResponse.fromJson(
        response.body as Map<String, dynamic>,
      );
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token.accessToken);
      final user = decodedToken['user'];
      final isSubscribed = user is Map && user['tt_account_subscribed'] == true;

      await _storage.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
        tokenType: token.tokenType,
        expiresIn: token.expiresIn,
        isSubscribed: isSubscribed,
      );

      // Notify the AuthManager that the user is now logged in
      _authManager.login(isSubscribed);

      // Emit different states based on subscription status
      if (isSubscribed) {
        emit(AuthSuccess());
      } else {
        emit(AuthNotSubscribed());
      }
    } catch (e) {
      // Handle potential network errors or other exceptions
      emit(AuthFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // This logic is taken directly from your AuthController's logout method
    _authManager.logout();
    // You might also want to clear secure storage here
    await _storage.clear();
    emit(AuthInitial()); // Go back to the initial state after logging out.
  }
}
