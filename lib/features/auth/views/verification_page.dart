import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resident Verification')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/resident/home'),
          child: const Text('Continue to KAISA'),
        ),
      ),
    );
  }
}
