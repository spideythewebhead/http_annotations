import 'myapi.dart';

void main() async {
  final api = MyApi();

  try {
    final loginResponse = await api.user.login({
      'username': 'hi',
      'password': 'mom',
    });

    if (loginResponse.token != null) {
      final todos = await api.todo.getTodosList(loginResponse.token!);
      print(todos);
    }
  } catch (e) {
    print(e);
  }
}
