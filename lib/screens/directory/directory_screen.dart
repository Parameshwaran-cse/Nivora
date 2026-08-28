import 'package:flutter/material.dart';

/// Placeholder Directory screen (Phase 0)
/// Real implementation comes in a later phase per SRD FR-1 / FR-2.
class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Directory')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Faculty Directory',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Coming soon in Phase 1'),
          ],
        ),
      ),
    );
  }
}