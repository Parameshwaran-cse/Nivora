import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_provider.dart';
import '../../utils/theme.dart';
import '../home_shell.dart';
import 'admin_placeholder_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dashboard'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.darkAccent.withAlpha(50),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkAccent,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.read<UiProvider>().setTabIndex(4);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeShell()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAdminTile(context, 'Faculty', Icons.people_outline_rounded),
          _buildAdminTile(context, 'Departments', Icons.business_rounded),
          _buildAdminTile(context, 'Designations', Icons.badge_outlined),
          _buildAdminTile(context, 'Locations', Icons.map_outlined),
          _buildAdminTile(context, 'Timetables', Icons.calendar_today_rounded),
          _buildAdminTile(context, 'Timetable Exceptions', Icons.event_busy_outlined),
        ],
      ),
    );
  }

  Widget _buildAdminTile(BuildContext context, String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.darkCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: AppTheme.darkAccent),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminPlaceholderScreen(title: title),
            ),
          );
        },
      ),
    );
  }
}
