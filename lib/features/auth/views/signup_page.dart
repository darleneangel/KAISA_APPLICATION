import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/profile-setup'),
          child: const Text('Continue to Profile Setup'),
        ),
      ),
    );
  }
}
