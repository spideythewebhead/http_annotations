import 'dart:async';

import 'package:http_annotations/http_annotations.dart';
import 'package:http/http.dart';
import 'dart:convert';

part 'todos_api.http.dart';

class Todo {
  final int id;
  final String title;

  Todo({required this.id, required this.title});

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
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

@HttpApi('http://localhost:3000/api/v0')
abstract class TodosApi {
  factory TodosApi([Client? client]) = _$TodosApi;

  @Route.get('/todos')
  @Header.acceptJson()
  Future<List<Todo>> getTodosList(
    @Header('Authorization') String auth,
  );

  @Route.post('/todo/{id}')
  Future<Map<String, dynamic>> updateTodo(
    int id,
    @Body() Todo todo,
  );

  @Route.get('/api/v0/version')
  @Header.acceptJson()
  Future<Response> getVersion({
    @Header('Api-Key') required String apiKey,
  });

  @Route.get('/todos')
  Future<List<Todo>> getPaginatedTodos(
    @QueryParam() int page,
    @QueryParam('page_limit') int limit,
  );
}
