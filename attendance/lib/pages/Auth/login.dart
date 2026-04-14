import 'package:attendance/Pages/Auth/signup.dart';
import 'package:attendance/db/auth_service.dart';
import 'package:attendance/pages/Admin/home_screen.dart';
import 'package:attendance/pages/Employee/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:attendance/theme/appTheme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Calling the signin method from your AuthService
        final response = await AuthService.signin(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;
        bool isAdmin = response['user']['isAdmin'];
        int UserId = response['user']['id'].toInt();
        print("userid : $UserId");
        // bool isApproved = response['user']['isApproved'];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isAdmin
                ? const AdminHomeScreen()
                // : const EmployeeHomeScreen(),
                : EmployeeHomeScreen(id: UserId),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Helper for consistent styling
  InputDecoration _buildInputDecoration(
    String label,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      fillColor: AppColors.background,
      prefixIcon: Icon(icon, size: 18),
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.0),
        borderSide: const BorderSide(color: AppColors.primaryText, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3.0),
        borderSide: const BorderSide(color: AppColors.primaryText, width: 1.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.17),
                Image.asset('assets/images/logo.png', height: 130, width: 200),
                const Text(
                  'LogIn',
                  style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.w600),
                ),
                const Text(
                  'Log in to continue',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(30.0),
                  padding: const EdgeInsets.all(10.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email Field (labeled as Username/Email)
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _buildInputDecoration(
                            'Email',
                            'Enter your email...',
                            Icons.person,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16.0),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _isObscured,
                          decoration:
                              _buildInputDecoration(
                                'Password',
                                'Enter your password...',
                                Icons.key,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscured
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    size: 18,
                                  ),
                                  onPressed: () => setState(
                                    () => _isObscured = !_isObscured,
                                  ),
                                ),
                              ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            } else {
                              return null;
                            }
                          },
                        ),

                        const SizedBox(height: 32.0),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryText,
                              foregroundColor: AppColors.background,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryGreen,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Log in',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20.0),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'New to Ahaz? ',
                              style: TextStyle(fontSize: 15),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
