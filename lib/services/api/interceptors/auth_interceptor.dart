import 'package:chopper/chopper.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:table_tennis_scoreboard/models/token_response.dart';
import 'package:table_tennis_scoreboard/services/api/auth_service.dart';
import 'package:table_tennis_scoreboard/services/api/chopper_client.dart';

import '../../secure_storage.dart';

class AuthInterceptor implements Interceptor {
  final SecureStorage storage;
  bool _refreshing = false;

  AuthInterceptor(this.storage);

  @override
  Future<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) async {
    final token = await storage.getAccessToken();
    final request = chain.request;

    final headers = Map<String, String>.from(request.headers)
      ..putIfAbsent('x-api-key', () => ApiClient.apiKey);

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final updatedRequest = request.copyWith(headers: headers);

    final response = await chain.proceed(updatedRequest);

    if (response.statusCode == 401 && !_refreshing) {
      _refreshing = true;

      final refreshed = await _refreshToken();
      _refreshing = false;

      if (refreshed) {
        final newToken = await storage.getAccessToken();

        final retryheaders = Map<String, String>.from(updatedRequest.headers)
          ..['Authorization'] = 'Bearer $newToken';
        final retryRequest = updatedRequest.copyWith(headers: retryheaders);

        return chain.proceed(retryRequest);
      } else {
        await storage.clear();
      }
    }
    return response;
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null) return false;

    final authService = ApiClient.client.getService<AuthService>();

    final response = await authService.authentication({
      'grant_type': 'refresh_token',
      'client_id': ApiClient.clientId,
      'client_secret': ApiClient.clientSecret,
      'refresh_token': refreshToken,
    });

    if (!response.isSuccessful) {
      await storage.clear();
      return false;
    }

    final token = TokenResponse.fromJson(response.body as Map<String, dynamic>);

    // Decode the access token
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token.accessToken);
    final user = decodedToken['user'];
    final isSubscribed = user is Map && user['tt_account_subscribed'] == true;

    await storage.saveTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      tokenType: token.tokenType,
      expiresIn: token.expiresIn,
      isSubscribed: isSubscribed,
    );

    return true;
  }
}
