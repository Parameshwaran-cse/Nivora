import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class AdminPlaceholderScreen extends StatelessWidget {
  final String title;

  const AdminPlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          '$title Management — coming soon',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.darkTextSecondary,
          ),
        ),
      ),
    );
  }
}
