import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'choose_baby_screen.dart';
import 'providers/auth_provider.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final baseURL = dotenv.env['BASE_URL'];
    final url = Uri.parse('$baseURL/users/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        final decodedToken = JwtDecoder.decode(token);
        final emailFromToken = decodedToken['email'] ?? email;
        final userId = decodedToken['id'] ?? '';

        // ✅ Extract extra fields from API response
        final user = data['user'] ?? {};
        final permission = data['permission'] ?? {};

        final username = user['username'] as String?;
        final babyIds = (permission['babyIDArr'] as List<dynamic>? ?? [])
            .map((b) => b['_path']?['segments']?.last.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();

        final subAccountIds = (permission['subAccArr'] as List<dynamic>? ?? [])
            .map((s) => s['_path']?['segments']?.last.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();

        // ✅ Save everything in AuthProvider
        Provider.of<AuthProvider>(context, listen: false).setUser(
          token: token,
          email: emailFromToken,
          userId: userId,
          username: username,
          babyIds: babyIds,
          subAccountIds: subAccountIds,
        );

        // ✅ Navigate to baby selection screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ChooseBabyScreen(),
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
