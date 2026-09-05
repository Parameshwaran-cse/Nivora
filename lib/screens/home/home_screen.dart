import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../models/department.dart';
import '../../providers/faculty_provider.dart';
import '../department/department_detail_screen.dart';
import '../../utils/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: Consumer<FacultyProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (provider.error != null) {
                    return Center(child: Text(provider.error!));
                  }

                  if (provider.departments.isEmpty) {
                    return const Center(child: Text('No departments found.'));
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadAll(),
                    color: AppTheme.darkAccent,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: provider.departments.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final department = provider.departments[index];
                        return _buildDepartmentCard(context, department);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo2.png',
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 12),
          Text(
            'YATA',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(BuildContext context, Department department) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DepartmentDetailScreen(department: department),
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
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                department.name,
                style: Theme.of(context).textTheme.titleLarge,
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
}
