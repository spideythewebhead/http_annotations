import 'package:http/http.dart';

import 'todos_api.dart';
import 'user_api.dart';

class MyApi {
  MyApi({
    Client? client,
  }) {
    _client = client ?? Client();
  }

  late final Client _client;

  /// creates its own instance of [InterceptorsHttpClient]
  late final UserApi user = UserApi();
  late final TodosApi todo = TodosApi(_client);
}
