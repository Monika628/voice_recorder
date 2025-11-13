import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_recorder/auth_provider.dart';
import 'package:voice_recorder/forgot_password_screen.dart';
import 'package:voice_recorder/recorder_screen.dart';
import 'package:voice_recorder/signup_screen.dart';
import 'package:voice_recorder/user.dart';

class LoginScreen extends StatefulWidget {
  final Function(bool)? onThemeChanged;

  const LoginScreen({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      UserModel user = UserModel(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      bool loginSuccess = await authProvider.isUserExists(user);

      if (loginSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Login successful!",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RecorderScreen(
              onThemeChanged: widget.onThemeChanged,
            ),
          ),
        );
      } else {
        String errorMessage = "Login failed. Please try again.";
        String actionLabel = "";
        VoidCallback? actionCallback;

        if (authProvider.error != null) {
          if (authProvider.error!.contains('invalid-credential') ||
              authProvider.error!.contains('wrong-password')) {
            errorMessage = "Incorrect email or password!";
            actionLabel = "Forgot?";
            actionCallback = () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
              );
            };
          } else if (authProvider.error!.contains('user-not-found')) {
            errorMessage = "No account found with this email!";
            actionLabel = "Sign Up";
            actionCallback = () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SignupScreen(
                    onThemeChanged: widget.onThemeChanged,
                  ),
                ),
              );
            };
          } else if (authProvider.error!.contains('user-disabled')) {
            errorMessage = "This account has been disabled!";
          } else if (authProvider.error!.contains('too-many-requests')) {
            errorMessage = "Too many attempts. Please try again later!";
          } else if (authProvider.error!.contains('network')) {
            errorMessage = "Network error. Check your connection!";
          } else if (authProvider.error!.contains('invalid-email')) {
            errorMessage = "Invalid email format!";
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
            action: actionLabel.isNotEmpty && actionCallback != null
                ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: actionCallback,
            )
                : null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.08),

                Container(
                  height: screenHeight * 0.12,
                  width: screenHeight * 0.12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: screenHeight * 0.06,
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: screenHeight * 0.035,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),

                SizedBox(height: screenHeight * 0.015),

                Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: screenHeight * 0.02,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),

                SizedBox(height: screenHeight * 0.06),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildInputField(
                        controller: _emailController,
                        hintText: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        screenHeight: screenHeight,
                        screenWidth: screenWidth,
                      ),

                      SizedBox(height: screenHeight * 0.025),

                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return _buildInputField(
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: !authProvider.isVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                authProvider.isVisible ? Icons.visibility : Icons.visibility_off,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              onPressed: () {
                                authProvider.setPasswordFieldStatus();
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            screenHeight: screenHeight,
                            screenWidth: screenWidth,
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.02),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: Colors.redAccent,
                          ),
                          Text(
                            'Remember me',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: screenHeight * 0.016,
                            ),
                          ),
                          const Spacer(),
                          // TextButton(
                          //   onPressed: () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                          //     );
                          //   },
                          //   child: Text(
                          //     'Forgot Password?',
                          //     style: TextStyle(
                          //       color: Colors.redAccent,
                          //       fontSize: screenHeight * 0.016,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Login Button
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Container(
                            width: double.infinity,
                            height: screenHeight * 0.07,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: const LinearGradient(
                                colors: [Colors.redAccent, Colors.red],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: authProvider.isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenHeight * 0.025,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: screenHeight * 0.016,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      SizedBox(height: screenHeight * 0.04),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: screenHeight * 0.018,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignupScreen(
                                    onThemeChanged: widget.onThemeChanged,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: screenHeight * 0.018,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.04),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required double screenHeight,
    required double screenWidth,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
          prefixIcon: Icon(
            icon,
            color: Theme.of(context).iconTheme.color,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onTap,
    required double screenHeight,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: screenHeight * 0.06,
        width: screenHeight * 0.06,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Icon(
          icon,
          color: Theme.of(context).iconTheme.color,
          size: screenHeight * 0.03,
        ),
      ),
    );
  }
}