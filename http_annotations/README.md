Provides annotations for http code gen

Add in your pubspec.yaml

```
   dependencies:
      http_annotations:
```

```
   dev_depedencies:
      // package that processes the http_annotations for code generation
      http_gen:
      build_runner:
```

Generate the files `dart run build_runner watch --delete-conflicting-outputs`

Common imports on top of the file

```dart
   import 'package:http_annotations/http_annotations.dart';
   import 'package:http/http.dart';
   import 'dart:convert';
   import 'dart:async' show compute; // optional, if you use useFlutterCompute
```

Excluded generated files from analyzer in analysis_options.yaml

```
   analyzer:
      exclude:
         - lib/**/*.http.dart
```

1. Add the generated file as a part of this file and annotate your class with @HttpApi()

   ```dart
   part 'file_name.http.dart';

   @HttpApi(
      'http://localhost:3000',
      useFlutterCompute: true, // is you want to use compute (defaults to false)
   )
   abstract class MyApi {
     // create a factory redirect (this is required)
     factory MyApi() = _$MyApi;

     // optional close method to dispose resources
     void close();
   }
   ```

2. Annotate methods with appropirate HTTP Method and path

   ```dart
   @Route.get('/api/v0/todos')
   Future<List<Todo>> getTodos();
   ```

   Parameter replacement support

   ```dart
   @Route.get('/api/v0/todo/{id}')
   Future<Todo> getTodo(int id);
   ```

3. Annotate methods with headers

   ```dart
   @Route.get('/api/v0/todos')
   @Header.contentTypeJson()
   @Header('cache', 'never')
   Future<List<Todo>> getTodos();
   ```

4. Annotate methods with HTTP status codes that have body

   By default only status code 200 is supported
   Example, if you want to add for status codes 400 and 401

   ```dart
   @Route.get('/api/v0/user/login')
   @StatusCodesWithBody([200, 400, 401])
   Future<LoginResponse> login();
   ```

5. Annotate a parameter with the body of the request (post, put, patch, delete)

   ```dart
   @Route.post('/api/v0/todo')
   Future<CreateTodoResponse>(@Body() Map<String, dynamic> json);
   ```

6. Annotate a parameter with query parameter

   ```dart
   @Route.get('/api/v0/todos')
   Future<List<Todo>>(
     @QueryParam() int page,
     @QueryParam('named_limit') int limit,
   );
   ```
