import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeyHeaderInterceptor implements Interceptor {
  FutureOr<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) {
    final request = applyHeader(
      chain.request,
      'x-api-key',
      dotenv.env['X-API-KEY']!,
    );
    return chain.proceed(request);
  }
}
