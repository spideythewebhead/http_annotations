import 'package:http_annotations/http_annotations.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';

class _MethodWithRouteAnnotation {
  final MethodElement method;
  final Route annotation;

  _MethodWithRouteAnnotation({
    required this.method,
    required this.annotation,
  });
}

class HttpApiGenerator extends GeneratorForAnnotation<HttpApi> {
  late String baseUrl;

  @override
  String generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    final useFlutterCompute = annotation.read('useFlutterCompute').boolValue;
    baseUrl = annotation.read('baseUrl').stringValue;

    if (element.kind != ElementKind.CLASS) {
      throw 'HttpApi annotation expected on class';
    }

    if (baseUrl.isEmpty) {
      throw '''
        $element 
        Empty base url for HttpApi
      ''';
    }

    return _createOutput(
      element as ClassElement,
      baseUrl,
      useFlutterCompute,
    );
  }

  String _createOutput(
    ClassElement element,
    String baseUrl,
    bool useFlutterCompute,
  ) {
    final methods = _getMethodsWithRouteAnnotation(element);
    final closeMethod = element.getMethod('close');

    final privateClassName = '_\$${element.name}';

    final methodsBuffer = StringBuffer();

    for (final wrapper in methods) {
      methodsBuffer.writeln(
        _implementMethod(wrapper.method, wrapper.annotation),
      );
    }

    final jsonDecode = '''
      FutureOr<dynamic> _jsonDecode(String payload) async {
        ${useFlutterCompute ? '''
          if (Platform.environment.containsKey('flutter')) {
            return compute(jsonDecode, payload);
          }
        ''' : ''}

        return jsonDecode(payload);
      }
    ''';

    if (_hasWithInterceptorsHttpClient(element)) {
      return '''
      $jsonDecode

      class $privateClassName with InterceptorsMixin implements ${element.name} {
        final String baseUrl = '$baseUrl';

        late final InterceptorsHttpClient client;

        $privateClassName([InterceptorsHttpClient? client]) {
          this.client = client ?? InterceptorsHttpClient();
        }

        $methodsBuffer

        @override
        void addInterceptor(Interceptor interceptor) => client.addInterceptor(interceptor);
        
        @override
        void removeInterceptor(Interceptor interceptor) => client.removeInterceptor(interceptor);

        ${closeMethod != null ? '''
          @override
          void close() {
            client.close();
          }
        ''' : ''}
      }
      ''';
    }

    return '''
    $jsonDecode

    class $privateClassName implements ${element.name} {
      final String baseUrl = '$baseUrl';

      late final Client client;

      $privateClassName([Client? client]) {
        this.client = client ?? Client();
      }

      $methodsBuffer

      ${closeMethod != null ? '''
        @override
        void close() {
          client.close();
        }
      ''' : ''}
    }
  ''';
  }

  List<_MethodWithRouteAnnotation> _getMethodsWithRouteAnnotation(ClassElement element) {
    final methods = <_MethodWithRouteAnnotation>[];

    for (final method in element.methods) {
      if (!method.returnType.isDartAsyncFuture) continue;

      for (final metadata in method.metadata) {
        final constantValue = metadata.computeConstantValue();

        if (constantValue == null) continue;

        final annotation = ConstantReader(constantValue);

        if (annotation.instanceOf(TypeChecker.fromRuntime(Route))) {
          methods.add(
            _MethodWithRouteAnnotation(
              method: method,
              annotation: Route(
                annotation.read('method').stringValue,
                annotation.read('path').stringValue,
              ),
            ),
          );
          break;
        }
      }
    }

    return methods;
  }

  String _implementMethod(MethodElement method, Route route) {
    final returnType = method.returnType;
    final returnTypeElements = _extractReturnSignaturesTypes(returnType as ParameterizedType);
    final headers = {
      ..._getConstantHeaders(method),
      ..._getDynamicHeaders(method),
    };
    final queryParams = _getQueryParams(method);
    final codesWithBody = _getStatusCodesWithBody(method);
    ParameterElement? body;

    if (route.path != 'get') {
      body = _getBody(method);
    }

    final requestBody = _makeRequest(
      route: route,
      headers: headers,
      queryParams: queryParams,
      codesWithBody: codesWithBody,
      returnTypeElements: returnTypeElements,
      bodyElement: body,
    );

    return '''
        @override
    ${method.declaration} async {
      $requestBody
    }
    ''';
  }

  List<DartType> _extractReturnSignaturesTypes(DartType type) {
    final types = <DartType>[];

    void visit(DartType type) {
      if (type is! ParameterizedType || type.typeArguments.isEmpty) return;

      for (final typeArg in type.typeArguments) {
        types.add(typeArg);

        if (typeArg.isDynamic) {
          continue;
        }

        visit(typeArg);
      }
    }

    visit(type as ParameterizedType);

    return types;
  }

  Map<String, String> _getConstantHeaders(MethodElement method) {
    final headers = <String, String>{};

    for (final metadata in method.metadata) {
      final constantValue = metadata.computeConstantValue();

      if (constantValue == null) continue;

      final annotation = ConstantReader(constantValue);

      if (annotation.instanceOf(TypeChecker.fromRuntime(Header))) {
        if (annotation.peek('value')?.isString ?? false) {
          headers[annotation.read('key').stringValue] = annotation.read('value').stringValue;
        }
      }
    }

    return headers;
  }

  Map<String, String> _getDynamicHeaders(MethodElement method) {
    final headers = <String, String>{};

    for (final parameter in method.parameters) {
      for (final metadata in parameter.metadata) {
        final constantValue = metadata.computeConstantValue();

        if (constantValue == null) continue;

        final annotation = ConstantReader(constantValue);

        if (annotation.instanceOf(TypeChecker.fromRuntime(Header))) {
          if (!parameter.type.isDartCoreString) {
            throw 'header "${parameter.name}" is not "string" but "${parameter.type.getDisplayString(withNullability: true)}"';
          }
          headers[annotation.read('key').stringValue] = '\$${parameter.name}';
        }
      }
    }

    return headers;
  }

  Map<String, String> _getQueryParams(MethodElement method) {
    final params = <String, String>{};

    for (final parameter in method.parameters) {
      for (final metadata in parameter.metadata) {
        final constantValue = metadata.computeConstantValue();

        if (constantValue == null) continue;

        final annotation = ConstantReader(constantValue);

        if (annotation.instanceOf(TypeChecker.fromRuntime(QueryParam))) {
          if (!(parameter.type.isDartCoreString || parameter.type.isDartCoreInt || parameter.type.isDartCoreBool)) {
            throw 'query param "${parameter.name}" unsupported type "${parameter.type.getDisplayString(withNullability: true)}" (string, int, bool are supported)"';
          }

          final name = annotation.peek('name')?.stringValue ?? parameter.name;
          params[name] = '\$${parameter.name}';
        }
      }
    }

    return params;
  }

  ParameterElement? _getBody(MethodElement method) {
    for (final parameter in method.parameters) {
      for (final metadata in parameter.metadata) {
        final constantValue = metadata.computeConstantValue();

        if (constantValue == null) continue;

        final annotation = ConstantReader(constantValue);

        if (annotation.instanceOf(TypeChecker.fromRuntime(Body))) {
          return parameter;
        }
      }
    }

    return null;
  }

  List<int> _getStatusCodesWithBody(MethodElement method) {
    for (final metadata in method.metadata) {
      final constantValue = metadata.computeConstantValue();

      if (constantValue == null) continue;

      final annotation = ConstantReader(constantValue);

      if (annotation.instanceOf(TypeChecker.fromRuntime(StatusCodesWithBody))) {
        return annotation
            .read('codes')
            .listValue
            .map(
              (e) => e.toIntValue()!,
            )
            .toList(growable: false);
      }
    }

    return const <int>[200];
  }

  String _makeRequest({
    required Route route,
    required Map<String, String> headers,
    required Map<String, String> queryParams,
    required List<int> codesWithBody,
    required List<DartType> returnTypeElements,
    ParameterElement? bodyElement,
  }) {
    final isResponse = _isResponseObject(returnTypeElements.first);
    final isJsonResponse = _isJsonCovertable(returnTypeElements.first);

    String? queryParamsString;

    if (queryParams.isNotEmpty) {
      queryParamsString = '${{for (final param in queryParams.entries) "'${param.key}'": "'${param.value}'"}}';
    }

    String url;

    if (route.path.startsWith(RegExp(r'https?'))) {
      url = route.path;
    } else {
      url = '$baseUrl${route.path}';
    }

    url = url.replaceAllMapped(RegExp(r'{([\w\d]{1,})}'), (m) => '\$${m.group(1)}');

    String bodyString = '';

    if (bodyElement != null) {
      if (_hasToJson(bodyElement.type.element!)) {
        bodyString = 'body: jsonEncode(${bodyElement.name}.toJson()),';
        headers['content-type'] = 'application/json; charset=utf8;';
      } else if (_isJsonMap(bodyElement.type)) {
        bodyString = 'body: jsonEncode(${bodyElement.name}),';
        headers['content-type'] = 'application/json; charset=utf8;';
      } else {
        bodyString = 'body: ${bodyElement.name},';
      }
    }

    final headersString = '${{for (final header in headers.entries) "'${header.key}'": "'${header.value}'"}}';

    return '''
      final uri = Uri.parse('$url')${queryParamsString != null ? '.replace(queryParameters: $queryParamsString)' : ''};

      final response = await client.${route.method}(
        uri, 
        headers: $headersString,
        $bodyString
      );

      ${isResponse ? 'return response;' : ''}

      ${isJsonResponse ? '''
      if (const $codesWithBody.contains(response.statusCode)) {
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.startsWith('application/json')) {
          ${_getJsonBody(returnTypeElements)}
        }
      }

      throw response;
      ''' : ''}

      ${isResponse || isJsonResponse ? '' : 'throw response;'}
    ''';
  }

  String _getJsonBody(List<DartType> types) {
    String visit(int depth, int previousDepth) {
      if (depth >= types.length) return '';

      final type = types[depth];

      if (type.isDartCoreList) {
        if (depth == 0) {
          return '''
          final body = await _jsonDecode(response.body);
          return [
            for (final i0 in body)
              ${visit(1 + depth, 0)}
          ];
          ''';
        }

        return '''
        [
          for (final i${depth} in i${depth - 1})
            ${visit(1 + depth, depth)}
        ]
        ''';
      } else if (_isJsonMap(type)) {
        if (depth == 0) {
          return '''
          final body = await _jsonDecode(response.body);
          return {
            for (final i0 in body.entries)
              i0.key: ${visit(2 + depth, depth)}
          };
          ''';
        }

        return '''
        {
          for (final i${depth} in i${depth - 1}.entries)
            i$depth.key: ${visit(2 + depth, depth)}
        }
        ''';
      } else if (_hasFromJson(type)) {
        if (depth == 0) {
          return '''
            final body = await _jsonDecode(response.body);
            return ${type.getDisplayString(withNullability: false)}.fromJson(body);
          ''';
        }

        final isInsideMap = _isJsonMap(types[previousDepth]);

        return '${type.getDisplayString(withNullability: false)}.fromJson(i$previousDepth${isInsideMap ? '.value' : ''})';
      } else if (_isJsonMap(types[previousDepth])) {
        return 'i${previousDepth}.value';
      }

      return '';
    }

    return visit(0, 0);
  }

  bool _isJsonCovertable(DartType type) {
    if (type.isDartCoreList && type is ParameterizedType) {
      final typeArg = type.typeArguments.single;

      return _isJsonMap(typeArg) || _hasFromJson(typeArg);
    } else if (_isJsonMap(type) || _hasFromJson(type)) {
      return true;
    }

    return false;
  }

  bool _isJsonMap(DartType type) {
    return type.getDisplayString(withNullability: false) == 'Map<String, dynamic>';
  }

  bool _isResponseObject(DartType type) {
    return type.getDisplayString(withNullability: true) == 'Response';
  }

  bool _hasToJson(Element element) {
    if (element is ClassElement) {
      bool isMethodToJson(MethodElement method) {
        return method.name == 'toJson';
      }

      return element.methods.any(isMethodToJson) || element.mixins.any((mixin) => mixin.methods.any(isMethodToJson));
    }

    return false;
  }

  bool _hasFromJson(DartType type) {
    if (type.element is ClassElement) {
      return (type.element as ClassElement).constructors.any((c) => c.name == 'fromJson');
    }

    return false;
  }

  bool _hasWithInterceptorsHttpClient(ClassElement element) {
    return element.constructors.single.parameters.any((param) {
      final paramTypeName = param.type.getDisplayString(withNullability: true);
      return paramTypeName == 'InterceptorsHttpClient' || paramTypeName == 'InterceptorsHttpClient?';
    });
  }
}
