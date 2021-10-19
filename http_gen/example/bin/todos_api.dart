import 'dart:async';

import 'package:http_annotations/http_annotations.dart';
import 'package:http/http.dart';
import 'dart:convert';

part 'todos_api.http.dart';

class TodoDto {
  final int id;
  final String title;

  TodoDto({required this.id, required this.title});

  factory TodoDto.fromJson(Map<String, dynamic> json) {
    return TodoDto(
      id: json['id'] as int,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }
}

class LoginResponse {
  final bool ok;
  final String? token;
  final Map<String, dynamic>? errors;

  LoginResponse({
    required this.ok,
    this.token,
    this.errors,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      ok: json['ok'] as bool,
      token: json['token'] as String?,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'LoginResponse(ok= $ok, token= $token, errors= $errors)';
  }
}

@HttpApi('http://localhost:3000')
abstract class TodosApi {
  factory TodosApi([Client? client]) = _$TodosApi;

  @Route.get('/api/v0/todos')
  @Header.acceptJson()
  Future<List<TodoDto>> listOfTodoDto();

  @Route.post('api/v0/todo/{id}')
  Future<Map<String, dynamic>> map(
    int id,
    @Body() TodoDto todo,
  );

  @Route.get('api/v0/todos')
  Future<List<Map<String, dynamic>>> listOfMap();

  @Route.patch('api/v0/todos')
  Future<Response> bodyString(@Body() String body);

  @Route.put('api/v0/todos')
  @Header.acceptJson()
  Future<TodoDto> urlEncoded(@Body() Map<String, String> body);

  @Route.put('api/v0/todos')
  @Header.acceptJson()
  Future<Map<String, dynamic>> uhm(@Body() Map<String, String> body);

  @Route.get('/api/v0/version')
  @Header.acceptJson()
  Future<Response> getVersion({
    @Header('Api-Key') required String apiKey,
  });

  @Route.get('/api/v0/todos')
  Future<List<TodoDto>> getTodos(
    @QueryParam() int page,
    @QueryParam('named_limit') int limit,
  );
}

@HttpApi('http://localhost:3000')
abstract class TodosApiWithInterceptors with InterceptorsMixin {
  factory TodosApiWithInterceptors([InterceptorsHttpClient? client]) = _$TodosApiWithInterceptors;

  @Route.get('/api/v0/todos')
  @Header.acceptJson()
  Future<List<TodoDto>> listOfTodoDto();
}
