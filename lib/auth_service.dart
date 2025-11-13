import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_recorder/user.dart';

class AuthService {
  Future<bool> login(UserModel userModel) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userModel.email,
        password: userModel.password,
      );
      return true;
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }


  Future signUp(UserModel userModel) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: userModel.email,
        password: userModel.password,
      );
    } catch (e) {

      rethrow;
    }
  }


  Future logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
    } catch (e) {
      rethrow;
    }
  }
}
