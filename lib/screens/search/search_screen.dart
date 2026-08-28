import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/faculty_provider.dart';
import '../../models/faculty.dart';
import '../../utils/theme.dart';
import '../directory/faculty_detail_screen.dart'; // We'll create this next

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clear search on init to ensure fresh state when opening tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FacultyProvider>().setSearchQuery('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Search',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 24),
              _buildSearchBar(context),
              const SizedBox(height: 24),
              Expanded(
                child: Consumer<FacultyProvider>(
                  builder: (context, provider, child) {
                    final query = _searchController.text.trim();
                    if (query.isEmpty) {
                      return const Center(
                        child: Text(
                          'Type a name to search',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    // We use the filteredFaculty from the provider.
                    // Note: If you have active department filters, they apply too.
                    // For global search, we might want to bypass department filter 
                    // or clear it when coming to this tab.
                    
                    final results = provider.filteredFaculty;

                    if (results.isEmpty) {
                      return const Center(
                        child: Text(
                          'No faculty found matching your search.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildResultCard(context, results[index], provider);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E), // Match the dark grey from mockup
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<FacultyProvider>().setSearchQuery(value);
        },
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search by name',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, Faculty faculty, FacultyProvider provider) {
    // If faculty doesn't consent, they shouldn't even be in the results,
    // but we can double check. Also handled by the backend query usually.
    if (!faculty.consent.given) return const SizedBox.shrink();

    final deptName = provider.getDepartmentName(faculty.departmentId) ?? 'Unknown Dept';
    final designationTitle = provider.getDesignationTitle(faculty.designationId) ?? 'Unknown';

    // Disambiguation formatting: "Department • Designation"
    // Wait, the mockup says "CSE • HOD". We might want the short code if available,
    // but the Department model has `shortCode`. Let's assume we can fetch it, 
    // or just use deptName if we can't.
    final department = provider.departments.firstWhere(
      (d) => d.id == faculty.departmentId, 
      orElse: () => provider.departments.first, // fallback
    );
    final shortDept = (department.id == faculty.departmentId) ? department.shortCode : deptName;

    final subtitleText = '$shortDept • $designationTitle';

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
          color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, Faculty faculty) {
    if (faculty.canShowPhoto && faculty.photoUrl != null && faculty.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(faculty.photoUrl!),
        backgroundColor: AppTheme.accentFill,
      );
    } else {
      final initial = faculty.canShowName && faculty.name.isNotEmpty 
          ? faculty.name[0].toUpperCase() 
          : '?';
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.accentFill,
        child: Text(
          initial,
          style: const TextStyle(
            color: AppTheme.accentText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}
