import 'package:flutter/material.dart';
import '../../models/department.dart';
import '../../utils/theme.dart';
import '../directory/faculty_list_screen.dart';

class DepartmentDetailScreen extends StatelessWidget {
  final Department department;

  const DepartmentDetailScreen({super.key, required this.department});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          department.name,
          maxLines: 2,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildOptionCard(
              context: context,
              title: 'Faculty',
              isPrimary: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FacultyListScreen(department: department),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context: context,
              title: 'Time Table',
              isPrimary: false,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Department timetables coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final bgColor = AppTheme.darkCardBg;
    final textColor = Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(28, 28, 30, 0.08),
              blurRadius: 4,
              offset: Offset(0, 1),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textColor,
                    fontSize: 20,
                  ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.darkAccent,
            ),
          ],
        ),
      ),
    );
  }
}
