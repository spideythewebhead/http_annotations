///
/// Entry point annotation for generating requests
///
/// ```dart
///
/// part 'file_name.http.dart';
///
/// @HttpApi('http://localhost:3000')
/// abstract class MyApi {
///   // create a factory redirect (this is required)
///   factory MyApi() = _MyApi;
///
///   // optional close method to dispose resources
///   void close();
/// }
/// ```
class HttpApi {
  final String baseUrl;

  const HttpApi(this.baseUrl);
}

///
/// Annotate methods with appropirate HTTP Method and path
///
/// ```dart
/// @Route.get('/api/v0/todos')
/// Future<List<Todo>> getTodos();
/// ```
///
/// Parameter replacement support
/// ```dart
/// @Route.get('/api/v0/todo/{id}')
/// Future<Todo> getTodo(int id);
/// ```
class Route {
  final String method;
  final String path;

  const Route(this.method, this.path);

  const Route.get(this.path) : method = 'get';
  const Route.post(this.path) : method = 'post';
  const Route.put(this.path) : method = 'put';
  const Route.patch(this.path) : method = 'patch';
  const Route.delete(this.path) : method = 'delete';
}

///
/// Annotate methods with constant headers
///
/// ```dart
/// @Route.get('/api/v0/todos')
/// @Header('accept', 'application/json')
/// @Header('cache', 'never')
/// Future<List<Todo>> getTodos();
/// ```
class Header {
  final String key;
  final String? value;

  const Header(this.key, [this.value]);

  const Header.contentTypeJson()
      : key = 'content-type',
        value = 'application/json; charset=utf-8;';

  const Header.acceptJson()
      : key = 'accept',
        value = 'application/json; charset=utf-8;';
}

///
/// Annotate methods with HTTP status codes that have body
///
/// By default only status code 200 is supported
///
/// Example, if you want to add for status codes 400 and 401
///
/// ```dart
/// @Route.get('/api/v0/user/login')
/// @StatusCodesWithBody([200, 400, 401])
/// Future<LoginResponse> login();
/// ```
class StatusCodesWithBody {
  final List<int> codes;

  const StatusCodesWithBody(this.codes);
}

///
/// Annotate a parameter with the body of the request (post, put, patch, delete)
///
/// ```dart
/// @Route.post('/api/v0/todo')
/// Future<CreateTodoResponse>(@Body() Map<String, dynamic> json);
/// ```
class Body {
  const Body();
}

///
/// Annotate a parameter with query parameter
///
/// ```dart
/// @Route.get('/api/v0/todos')
/// Future<List<Todo>>(
///   @QueryParam() int page,
///   @QueryParam('named_limit') int limit,
/// );
/// ```
class QueryParam {
  final String? name;

  const QueryParam([this.name]);
}
