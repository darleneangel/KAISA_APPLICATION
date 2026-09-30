import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setup')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/verification'),
          child: const Text('Continue'),
        ),
      ),
    );
  }
}
