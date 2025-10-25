import '../../../data/repositories/auth_repository.dart';

class AuthController {
  final AuthRepository _authRepository = AuthRepository();

  Future<void> login(String email, String password) async {
    await _authRepository.signIn(email: email, password: password);
  }

  Future<void> register(String email, String password, String role) async {
    await _authRepository.signUp(
      email: email,
      password: password,
      role: role,
    );
  }

  Future<void> resetPassword(String email) async {
    await _authRepository.resetPassword(email);
  }

  Future<void> logout() async {
    await _authRepository.signOut();
  }
}
