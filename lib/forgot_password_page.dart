import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  bool passwordLamaTerlihat = false;
  bool passwordBaruTerlihat = false;

  final controllerTelepon = TextEditingController();
  final controllerUsername = TextEditingController();
  final controllerPasswordLama = TextEditingController();
  final controllerPasswordBaru = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black87,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 30),
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
                            'Forgot Password',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildTextField('Enter Phone Number', controllerTelepon),
                    _buildTextField('Enter Your Username', controllerUsername),
                    _buildTextField(
                      'Enter Your Current Password',
                      controllerPasswordLama,
                      isPassword: true,
                      isVisible: passwordLamaTerlihat,
                      onToggle: () {
                        setState(() {
                          passwordLamaTerlihat = !passwordLamaTerlihat;
                        });
                      },
                    ),
                    _buildTextField(
                      'Enter A New Password',
                      controllerPasswordBaru,
                      isPassword: true,
                      isVisible: passwordBaruTerlihat,
                      onToggle: () {
                        setState(() {
                          passwordBaruTerlihat = !passwordBaruTerlihat;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        // Aksi konfirmasi
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
                        style: TextStyle(color: Colors.black, fontSize: 16),
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