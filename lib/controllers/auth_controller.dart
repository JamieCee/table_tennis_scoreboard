import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:table_tennis_scoreboard/models/token_response.dart';
import 'package:table_tennis_scoreboard/services/api/auth_service.dart';
import 'package:table_tennis_scoreboard/services/api/chopper_client.dart';
import 'package:table_tennis_scoreboard/services/secure_storage.dart';

enum LoginResult { success, invalidCredentials, notSubscribed }

class AuthController {
  final _service = ApiClient.client.getService<AuthService>();
  final _storage = SecureStorage();

  Future<LoginResult> login(String username, String password) async {
    final response = await _service.authentication({
      'grant_type': 'password',
      'username': username,
      'password': password,
      'client_id': ApiClient.clientId,
      'client_secret': ApiClient.clientSecret,
    });

    if (!response.isSuccessful) return LoginResult.invalidCredentials;

    final token = TokenResponse.fromJson(response.body as Map<String, dynamic>);

    // Decode the access token
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

    // If the user is not subscribed, return notSubscribed
    if (!isSubscribed) {
      return LoginResult.notSubscribed;
    }

    return LoginResult.success;
  }

  Future<void> logout() async {
    await _storage.clear();
  }
}
