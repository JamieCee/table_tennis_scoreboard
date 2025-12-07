import 'package:table_tennis_scoreboard/models/token_response.dart';
import 'package:table_tennis_scoreboard/services/api/auth_service.dart';
import 'package:table_tennis_scoreboard/services/api/chopper_client.dart';
import 'package:table_tennis_scoreboard/services/secure_storage.dart';

class AuthController {
  final _service = ApiClient.client.getService<AuthService>();
  final _storage = SecureStorage();

  Future<bool> login(String username, String password) async {
    final response = await _service.authentication({
      'grant_type': 'password',
      'username': username,
      'password': password,
      'client_id': ApiClient.clientId,
      'client_secret': ApiClient.clientSecret,
    });

    if (!response.isSuccessful) return false;

    final token = TokenResponse.fromJson(response.body as Map<String, dynamic>);

    await _storage.savetokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      tokenType: token.tokenType,
      expiresIn: token.expiresIn,
    );

    return true;
  }

  Future<void> logout() async {
    await _storage.clear();
  }
}
