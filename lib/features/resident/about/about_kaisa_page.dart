import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AboutKaisaPage extends StatelessWidget {
  const AboutKaisaPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About KAISA')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/kaisa_logo.png',
                      width: 70,
                      height: 70,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.groups,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'KAISA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Connect • Participate • Impact',
                      style: TextStyle(
                        color: AppColors.lime,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Building stronger Cavite City communities',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
              ),
              const SizedBox(height: 12),
              const Text(
                'KAISA is a proposed multi-platform community engagement and participation management system for Cavite City. It aims to bring residents, community organizations, and local government closer together through more accessible information and participation opportunities.',
                style: TextStyle(fontSize: 15, height: 1.7),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final x in [
                    'Discover local organizations',
                    'Find and join community events',
                    'Stay informed with community updates',
                    'Support responsible citizen participation',
                  ])
                    Chip(
                      label: Text(x),
                      avatar: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.green,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'About this prototype',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              const SizedBox(height: 8),
              const Text(
                'Demonstration content is illustrative. Account verification, approvals, real-time announcements, and other services require integration with the authorized LGU workflows and database.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
