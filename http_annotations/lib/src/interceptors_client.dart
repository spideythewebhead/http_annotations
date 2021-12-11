import 'dart:async';

import 'package:http/http.dart';

///
/// Provides optional [onRequest] and [onResponse] handlers
/// to be used with [InterceptorsMixin]
class Interceptor {
  final FutureOr<Request> Function(Request request)? onRequest;
  final FutureOr<Response> Function(Response response)? onResponse;

  Interceptor({
    this.onRequest,
    this.onResponse,
  });
}

///
/// A mixin that can be used with your api class to add interceptors
/// in conjunction with [InterceptorsHttpClient]
///
/// ```dart
///
/// @HttpApi('...')
/// class MyApi with InterceptorsMixin {
///   factory MyApi([InterceptorsHttpClient client]) = _$MyApi();
/// }
///
/// ```
class InterceptorsMixin {
  final _interceptors = <Interceptor>[];

  void addInterceptor(Interceptor interceptor) {
    _interceptors.add(interceptor);
  }

  void removeInterceptor(Interceptor interceptor) {
    _interceptors.remove(interceptor);
  }
}

///
/// Http client that supports [InterceptorsMixin]
class InterceptorsHttpClient extends BaseClient with InterceptorsMixin {
  final _client = Client();

  InterceptorsHttpClient();

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    for (final interceptor in _interceptors) {
      if (interceptor.onRequest != null) {
        request = await interceptor.onRequest!(request as Request);
      }
    }

    final streamedResponse = await _client.send(request);

    var response = await Response.fromStream(streamedResponse);

    for (final interceptor in _interceptors) {
      if (interceptor.onResponse != null) {
        response = await interceptor.onResponse!(response);
      }
    }

    return StreamedResponse(
      ByteStream.fromBytes(response.bodyBytes),
      response.statusCode,
      contentLength: response.contentLength,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }

  @override
  void close() {
    _client.close();
  }
}
