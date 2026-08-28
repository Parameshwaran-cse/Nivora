import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/department.dart';
import '../../models/faculty.dart';
import '../../providers/faculty_provider.dart';
import '../../utils/theme.dart';
import 'faculty_detail_screen.dart';

class FacultyListScreen extends StatelessWidget {
  final Department department;

  const FacultyListScreen({super.key, required this.department});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${department.name} Faculty',
          maxLines: 2,
        ),
      ),
      body: Consumer<FacultyProvider>(
        builder: (context, provider, child) {
          final facultyList = provider.getFacultyForDepartment(department.id);
          
          if (facultyList.isEmpty) {
            return const Center(child: Text('No faculty found for this department.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: facultyList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final faculty = facultyList[index];
              return _buildFacultyCard(context, faculty, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildFacultyCard(BuildContext context, Faculty faculty, FacultyProvider provider) {
    // Determine designation text
    final designationTitle = provider.getDesignationTitle(faculty.designationId) ?? 'Unknown Designation';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FacultyDetailScreen(faculty: faculty),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(28, 28, 30, 0.08),
              blurRadius: 4,
              offset: Offset(0, 1),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildAvatar(context, faculty),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faculty.canShowName ? faculty.name : 'Unknown Faculty',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    designationTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, Faculty faculty) {
    if (faculty.canShowPhoto && faculty.photoUrl != null && faculty.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(faculty.photoUrl!),
        backgroundColor: AppTheme.accentFill,
      );
    } else {
      // Placeholder
      final initial = faculty.canShowName && faculty.name.isNotEmpty 
          ? faculty.name[0].toUpperCase() 
          : '?';
      return CircleAvatar(
        radius: 28,
        backgroundColor: AppTheme.accentFill,
        child: Text(
          initial,
          style: const TextStyle(
            color: AppTheme.accentText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}
