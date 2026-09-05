import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/department.dart';
import '../../models/faculty.dart';
import '../../models/designation.dart';
import '../../providers/faculty_provider.dart';
import '../../utils/theme.dart';
import 'faculty_detail_screen.dart';

class FacultyListScreen extends StatefulWidget {
  final Department department;

  const FacultyListScreen({super.key, required this.department});

  @override
  State<FacultyListScreen> createState() => _FacultyListScreenState();
}

class _FacultyListScreenState extends State<FacultyListScreen> {
  String? _selectedDesignationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.department.name} Faculty',
          maxLines: 2,
        ),
      ),
      body: Consumer<FacultyProvider>(
        builder: (context, provider, child) {
          final rawFacultyList = provider.getFacultyForDepartment(widget.department.id);
          
          final facultyList = _selectedDesignationId == null 
              ? rawFacultyList 
              : rawFacultyList.where((f) => f.designationId == _selectedDesignationId).toList();
          
          final designations = List<Designation>.from(provider.designations)
            ..sort((a, b) => a.rank.compareTo(b.rank));

          return Column(
            children: [
              if (designations.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _buildChip(
                        label: 'All',
                        isSelected: _selectedDesignationId == null,
                        onTap: () => setState(() => _selectedDesignationId = null),
                      ),
                      ...designations.map((d) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: _buildChip(
                            label: d.title,
                            isSelected: _selectedDesignationId == d.id,
                            onTap: () => setState(() => _selectedDesignationId = d.id),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              
              Expanded(
                child: facultyList.isEmpty
                    ? Center(
                        child: Text(
                          _selectedDesignationId == null 
                            ? 'No faculty found for this department.'
                            : 'No faculty with this designation in this department.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadAll(),
                        color: AppTheme.darkAccent,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: facultyList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final faculty = facultyList[index];
                            return _buildFacultyCard(context, faculty, provider);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.darkAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.darkAccent : Colors.grey.shade700,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
    final initial = faculty.canShowName && faculty.name.isNotEmpty 
        ? faculty.name[0].toUpperCase() 
        : '?';

    Widget fallbackAvatar = CircleAvatar(
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

    if (faculty.canShowPhoto && faculty.photoUrl != null && faculty.photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: CachedNetworkImage(
          imageUrl: faculty.photoUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (context, url) => fallbackAvatar,
          errorWidget: (context, url, error) => fallbackAvatar,
        ),
      );
    } else {
      return fallbackAvatar;
    }
  }
}
