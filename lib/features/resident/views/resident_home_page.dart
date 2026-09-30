import 'package:flutter/material.dart';

class ResidentHomePage extends StatelessWidget {
  const ResidentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KAISA')),
      body: const Center(
        child: Text(
          'Resident Home',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
