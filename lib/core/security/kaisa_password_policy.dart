import 'package:flutter/material.dart';

/// UI guidance for password registration. Match this policy in Supabase Auth.
abstract final class KaisaPasswordPolicy {
  static bool hasLength(String p) => p.runes.length >= 12;
  static bool hasUpper(String p) => RegExp(r'[A-Z]').hasMatch(p);
  static bool hasLower(String p) => RegExp(r'[a-z]').hasMatch(p);
  static bool hasDigit(String p) => RegExp(r'[0-9]').hasMatch(p);
  static bool hasSymbol(String p) => RegExp(r'[^A-Za-z0-9\s]').hasMatch(p);
  static bool isStrong(String p) =>
      hasLength(p) && hasUpper(p) && hasLower(p) && hasDigit(p) && hasSymbol(p);

  static int getScore(String p) {
    if (p.isEmpty) return 0;
    var score = 0;
    if (hasLength(p)) score++;
    if (hasUpper(p) && hasLower(p)) score++;
    if (hasDigit(p)) score++;
    if (hasSymbol(p)) score++;
    return score;
  }

  static String? error(String p) {
    if (p.isEmpty) return 'Enter a password';
    if (!hasLength(p)) return 'Use at least 12 characters';
    if (!hasUpper(p) || !hasLower(p)) {
      return 'Include uppercase and lowercase letters';
    }
    if (!hasDigit(p)) return 'Include at least one number';
    if (!hasSymbol(p)) return 'Include at least one symbol';
    return null;
  }
}

class KaisaPasswordStrengthIndicator extends StatelessWidget {
  const KaisaPasswordStrengthIndicator({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final score = KaisaPasswordPolicy.getScore(password);
    final strong = KaisaPasswordPolicy.isStrong(password);
    final color = password.isEmpty
        ? const Color(0xFFB0BDB5)
        : strong
        ? const Color(0xFF217B4B)
        : score <= 2
        ? const Color(0xFFC65A44)
        : const Color(0xFFD09C22);
    final label = password.isEmpty
        ? 'Enter a password'
        : strong
        ? 'Strong password'
        : score <= 2
        ? 'Weak password'
        : 'Almost there';

    Widget requirement(String label, bool met) => Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 15,
            color: met ? const Color(0xFF217B4B) : const Color(0xFF8A9C90),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF60766B)),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Password strength',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF153D30),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: i == 3 ? 0 : 5),
                decoration: BoxDecoration(
                  color: i < score ? color : const Color(0xFFE4ECE6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        requirement(
          'At least 12 characters',
          KaisaPasswordPolicy.hasLength(password),
        ),
        requirement(
          'Uppercase and lowercase letters',
          KaisaPasswordPolicy.hasUpper(password) &&
              KaisaPasswordPolicy.hasLower(password),
        ),
        requirement(
          'At least one number',
          KaisaPasswordPolicy.hasDigit(password),
        ),
        requirement(
          'At least one symbol',
          KaisaPasswordPolicy.hasSymbol(password),
        ),
      ],
    );
  }
}
