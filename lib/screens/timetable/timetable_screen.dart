import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_provider.dart';
import '../../utils/theme.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.darkAccent.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  size: 64,
                  color: AppTheme.darkAccent,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Pick a department first',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Timetables are specific to departments and faculty. Head to the Home screen to explore.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.darkTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Instruct UiProvider to switch HomeShell back to index 0 (Home)
                    context.read<UiProvider>().setTabIndex(0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkEmphasizedBg,
                    foregroundColor: AppTheme.darkEmphasizedText,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Go to Departments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}