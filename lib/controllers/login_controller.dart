import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../services/database_helper.dart';

class LoginController extends ChangeNotifier {
  LoginController({UserRepository? repository})
    : _repository = repository ?? UserRepository();

  static const String invalidCredentialsMessage = 'Usuário ou senha inválidos.';

  static const String unavailableMessage =
      'Não foi possível validar o acesso. Tente novamente.';

  final UserRepository _repository;

  bool _isSubmitting = false;

  String? _errorMessage;

  User? _authenticatedUser;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  User? get authenticatedUser => _authenticatedUser;

  Future<bool> signIn({
    required String username,
    required String password,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _authenticatedUser = null;
    notifyListeners();
    try {
      final User? user = await _repository.findByCredentials(
        username: username,
        password: password,
      );
      if (user == null) {
        _errorMessage = invalidCredentialsMessage;
        return false;
      }
      _authenticatedUser = user;
      return true;
    } on DatabaseAccessException {
      _errorMessage = unavailableMessage;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
