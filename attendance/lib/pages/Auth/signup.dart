import 'package:attendance/Pages/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:attendance/db/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to capture user input
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Handle optional position field
        String? position = _positionController.text.trim();
        if (position.isEmpty) position = null;

        await AuthService.signup(
          _firstNameController.text.trim(),
          _lastNameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          position,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to Login Page on success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } catch (e) {
        if (!mounted) return;
        // Show error message
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

  // Helper method to keep code DRY for text field decorations
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
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.0),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Image.asset('assets/images/logo.png', height: 130, width: 200),
                const Text(
                  'Register',
                  style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.w600),
                ),
                const Text(
                  'Ready for adventures? Join us',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(30.0),
                  padding: const EdgeInsets.all(10.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Form(
                    key: _formKey, // Attach FormKey here
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // First Name Field
                        TextFormField(
                          controller: _firstNameController,
                          decoration: _buildInputDecoration(
                            'First Name',
                            'Enter your first name',
                            Icons.person,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),

                        // Last Name Field
                        TextFormField(
                          controller: _lastNameController,
                          decoration: _buildInputDecoration(
                            'Last Name',
                            'Enter your last name',
                            Icons.person_outline,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _buildInputDecoration(
                            'Email',
                            'Enter your email',
                            Icons.email,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            // Basic email regex validation
                            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),

                        // Position Field (Optional)
                        TextFormField(
                          controller: _positionController,
                          decoration: _buildInputDecoration(
                            'Position (Optional)',
                            'e.g., Software Engineer',
                            Icons.work,
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _isObscured,
                          decoration:
                              _buildInputDecoration(
                                'Password',
                                'Enter your password',
                                Icons.lock,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscured
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscured = !_isObscured;
                                    });
                                  },
                                ),
                              ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters long';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),

                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _isObscured,
                          decoration: _buildInputDecoration(
                            'Confirm Password',
                            'Re-enter your password',
                            Icons.lock_outline,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24.0),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
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
                                    'Register',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20.0),

                        // Sign In Routing
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(fontSize: 15),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign In',
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
