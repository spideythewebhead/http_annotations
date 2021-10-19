import 'package:build/src/builder/build_step.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:http_annotations/http_annotations.dart';

final _interceptorMixinName = '_\$InterceptorsMixin';

String _interceptorClientImpl = '''
class $_interceptorMixinName {
  final _interceptors = <Interceptor>[];

  void addInterceptor(Interceptor interceptor) {
    _interceptors.add(interceptor);
  }

  void removeInterceptor(Interceptor interceptor) {
    _interceptors.remove(interceptor);
  }
}

class _Client extends BaseClient {
  final client = Client();

  final $_interceptorMixinName interceptorsMixin;

  _Client(this.interceptorsMixin);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    for (final interceptor in interceptorsMixin._interceptors) {
      if (interceptor.onRequest != null) {
        request = await interceptor.onRequest!(request as Request);
      }
    }

    final streamedResponse = await client.send(request);

    var response = await Response.fromStream(streamedResponse);

    for (final interceptor in interceptorsMixin._interceptors) {
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

  void close() {
    client.close();
  }
}
''';

class WithInterceptorsGenerator extends GeneratorForAnnotation<WithInterceptors> {
  @override
  String generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    return _interceptorClientImpl;
  }
}
