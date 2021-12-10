import 'package:http_annotations/http_annotations.dart';
import 'package:http/http.dart';
import 'dart:convert';

part 'user_api.http.dart';

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

@HttpApi('http://localhost:3000/api/v0')
abstract class UserApi with InterceptorsMixin {
  factory UserApi([InterceptorsHttpClient client]) = _$UserApi;

  @Route.post('/login')
  @StatusCodesWithBody([200, 400, 401])
  Future<LoginResponse> login(@Body() Map<String, dynamic> creds);

  @Route.post('/logout')
  Future<Response> logout();
}
