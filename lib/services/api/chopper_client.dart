import 'package:chopper/chopper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:table_tennis_scoreboard/services/api/interceptors/api_key_header_interceptor.dart';

import '../secure_storage.dart';
import 'auth_service.dart';

class ApiClient {
  static late ChopperClient client;

  static String get baseUrl => dotenv.env['BASE_URL']!;
  static String get clientId => dotenv.env['CLIENT_ID']!;
  static String get clientSecret => dotenv.env['CLIENT_SECRET']!;
  static String get apiKey => dotenv.env['X_API_KEY']!;

  static final storage = SecureStorage();

  static void create() {
    client = ChopperClient(
      baseUrl: Uri.parse(baseUrl),
      services: [AuthService.create()],
      converter: JsonConverter(),
      interceptors: [ApiKeyHeaderInterceptor()],
    );
  }
}
