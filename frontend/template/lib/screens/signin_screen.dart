  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:http/http.dart' as http;

  import 'choose_baby_screen.dart';
  import 'providers/auth_provider.dart';
import 'package:provider/provider.dart';

  class SignInScreen extends StatefulWidget {
    const SignInScreen({super.key});

    @override
    State<SignInScreen> createState() => _SignInScreenState();
  }

  class _SignInScreenState extends State<SignInScreen> {
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    String? _accountType;
    bool _isLoading = false;

    final List<String> _accountOptions = ['Parent', 'Caregiver'];

    Future<void> _handleSignIn() async {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty || _accountType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please complete all fields")),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final url = Uri.parse('http://10.0.2.2:3000/users/login'); 
      //emulator ip is this, not sure why its not localhost, will kiv, works for now
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        );

                if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final token = data['token'];

          // 🔥 Set token globally
          Provider.of<AuthProvider>(context, listen: false).setToken(token);

          // Navigate to baby selection
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChooseBabyScreen(),
            ),
          );
} else {
          final error = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error['error'] ?? 'Login failed')),
          );
        }
      } catch (e) {
        print('❌ Login error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Network error. Please try again.")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text("Sign In"), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email*",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password*",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _accountType,
                items: _accountOptions
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _accountType = value),
                decoration: const InputDecoration(
                  labelText: "Account Type",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Forgot your Password?"),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign In"),
                ),
              )
            ],
          ),
        ),
      );
    }
  }
