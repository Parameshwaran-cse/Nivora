import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import 'admin_login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.darkCardBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.darkAccent.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: AppTheme.darkAccent),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Faculty Find',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This is a college project currently running on sample data. It is designed to help students easily locate faculty and navigate the campus.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.darkTextSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () {
                // Future: mailto link or form
              },
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkCardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.report_problem_outlined, color: Colors.white54),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Report incorrect data',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                  ],
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Admin',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
