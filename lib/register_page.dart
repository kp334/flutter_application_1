import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black87,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.9, // Gunakan 90% dari lebar layar
              child: Container(
                constraints: BoxConstraints(minHeight: screenHeight * 0.9),
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCFF5ED),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Register',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Form Fields
                    _buildTextField('Enter Username', usernameController),
                    _buildTextField('Enter Phone Number', phoneController),
                    _buildTextField('Enter Address', addressController),
                    _buildTextField(
                      'Enter Password',
                      passwordController,
                      isPassword: true,
                      isVisible: _isPasswordVisible,
                      onToggle: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    _buildTextField(
                      'Enter Password Again',
                      confirmPasswordController,
                      isPassword: true,
                      isVisible: _isConfirmPasswordVisible,
                      onToggle: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Confirm Button
                    ElevatedButton(
                      onPressed: () {
                        // Logika saat tombol ditekan
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.black),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Link to Login
                    GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Navigasi ke halaman login
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: 'Log in',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            obscureText: isPassword ? !isVisible : false,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade300,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: onToggle,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}