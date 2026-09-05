import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_provider.dart';
import '../../utils/theme.dart';
import '../home_shell.dart';
import 'admin_placeholder_screen.dart';
import 'admin_departments_screen.dart';
import 'admin_designations_screen.dart';
import 'admin_faculty_screen.dart';
import 'admin_timetable_faculty_list_screen.dart';
import 'admin_locations_screen.dart';

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Student Dashboard',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.darkCardBg,
                title: const Text('Return to Student Dashboard'),
                content: const Text('Are you sure you want to exit the admin area? You will stay logged in.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Return', style: TextStyle(color: AppTheme.darkAccent)),
                  ),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
              context.read<UiProvider>().setTabIndex(0);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeShell()),
                (route) => false,
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.darkCardBg,
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out of the admin panel?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Log out', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  context.read<UiProvider>().setTabIndex(4);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeShell()),
                    (route) => false,
                  );
                }
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
          _buildAdminTile(context, 'Timetables & Exceptions', Icons.calendar_month_rounded),
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
          Widget destination;
          if (title == 'Faculty') {
            destination = const AdminFacultyScreen();
          } else if (title == 'Departments') {
            destination = const AdminDepartmentsScreen();
          } else if (title == 'Designations') {
            destination = const AdminDesignationsScreen();
          } else if (title == 'Locations') {
            destination = const AdminLocationsScreen();
          } else if (title == 'Timetables & Exceptions') {
            destination = const AdminTimetableFacultyListScreen();
          } else {
            destination = AdminPlaceholderScreen(title: title);
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => destination,
            ),
          );
        },
      ),
    );
  }
}
