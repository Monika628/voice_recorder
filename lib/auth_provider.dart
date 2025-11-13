import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_recorder/auth_service.dart';
import 'package:voice_recorder/user.dart';

class AuthProvider extends ChangeNotifier {
  AuthService   authService;
  AuthProvider(this.authService);

  bool isVisible = false;
  bool isLoading = false;
  String? error;

  void setPasswordFieldStatus() {
    isVisible = !isVisible;
    notifyListeners();
  }

  Future registerUser(UserModel user) async {
    isLoading = true;
    error = null;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 3));
    try {
      await authService.signUp(user);
    } catch (e) {
      error = e.toString();
    //  AppUtil.showToast(error!);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> isUserExists(UserModel user) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      bool result = await authService.login(user);
      if (result) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      error = e.toString();
     // AppUtil.showToast(error!);
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return false;
  }

}
