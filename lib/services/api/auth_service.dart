import 'package:chopper/chopper.dart';

part 'auth_service.chopper.dart';

@ChopperApi()
abstract class AuthService extends ChopperService {
  static AuthService create([ChopperClient? client]) => _$AuthService(client);

  @Post(path: '/auth')
  Future<Response> authentication(@Body() Map<String, dynamic> body);
}
