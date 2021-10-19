import 'dart:async';

import 'package:http/http.dart';

class Interceptor {
  final FutureOr<Request> Function(Request request)? onRequest;
  final FutureOr<Response> Function(Response response)? onResponse;

  Interceptor({
    this.onRequest,
    this.onResponse,
  });
}
