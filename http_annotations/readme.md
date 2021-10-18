Provides annotations for http code gen

View [docs](https://github.com/spideythewebhead/http_annotations) for annotations

Examples for body and return types

Body types

```dart
// Json body
@Route.post('/api/v0/todo')
Future<CreateTodoResponse> createTodo(@Body() Map<String, dynamic> json);

// Parse model into json
// Note, the model class must provider toJson() function
@Route.post('/api/v0/todo')
Future<Response> createTodo(@Body() Todo todo);
```

Return types

> _note_
> in case the convertion or the return types mismatch, an exception will be thrown
> with the original response object, so try-catch your api calls

```dart
// Get the original response
@Route.get('/api/v0/todos')
Future<Response> getTodos();

// Get the parsed json
@Route.get('/api/v0/todos')
Future<List<Map<String, dynamic>>> getTodos();

// Get parsed json into model
// Note, the model class must provide fromJson(Map<String, dynamic>) factory constructor
@Route.get('/api/v0/todos')
Future<List<Todo>> getTodos();
```
