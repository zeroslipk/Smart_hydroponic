import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';

enum AuthMode { login, register }

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthMode _mode = AuthMode.login;
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  String? _emailError;
  String? _passwordError;
  String? _nameError;
  
  // Getters
  AuthMode get mode => _mode;
  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  bool get isLogin => _mode == AuthMode.login;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get nameError => _nameError;
  
  // Toggle methods
  void toggleMode() {
    _mode = _mode == AuthMode.login ? AuthMode.register : AuthMode.login;
    clearErrors();
    notifyListeners();
  }
  
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }
  
  void clearErrors() {
    _emailError = null;
    _passwordError = null;
    _nameError = null;
    notifyListeners();
  }
  
  void clearEmailError() {
    _emailError = null;
    notifyListeners();
  }
  
  void clearPasswordError() {
    _passwordError = null;
    notifyListeners();
  }
  
  void clearNameError() {
    _nameError = null;
    notifyListeners();
  }
  
  // Validation
  bool validateFields(String email, String password, String name) {
    bool isValid = true;
    
    _emailError = Validators.validateEmail(email);
    if (_emailError != null) isValid = false;
    
    if (isLogin) {
      _passwordError = Validators.validatePassword(password);
    } else {
      _passwordError = Validators.validateStrongPassword(password);
    }
    if (_passwordError != null) isValid = false;
    
    if (!isLogin) {
      _nameError = Validators.validateName(name);
      if (_nameError != null) isValid = false;
    }
    
    notifyListeners();
    return isValid;
  }
  
  // Authentication
  Future<String?> authenticate(String email, String password, String name) async {
    if (!validateFields(email, password, name)) {
      return 'Please fix the errors above';
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      if (isLogin) {
        await _authService.signIn(email: email, password: password);
      } else {
        await _authService.signUp(email: email, password: password, name: name);
      }
      
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message ?? 'Authentication failed';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }
  
  // Password Recovery
  Future<String?> sendPasswordReset(String email) async {
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      return emailError;
    }
    
    try {
      await _authService.sendPasswordResetEmail(email);
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }
}
