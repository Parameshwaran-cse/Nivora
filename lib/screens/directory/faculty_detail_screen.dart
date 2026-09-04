import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/faculty.dart';
import '../../providers/faculty_provider.dart';
import '../../utils/theme.dart';
import '../../providers/timetable_provider.dart';
import '../map/map_screen.dart';
import '../timetable/faculty_timetable_screen.dart';

class FacultyDetailScreen extends StatefulWidget {
  final Faculty faculty;

  const FacultyDetailScreen({super.key, required this.faculty});

  @override
  State<FacultyDetailScreen> createState() => _FacultyDetailScreenState();
}

class _FacultyDetailScreenState extends State<FacultyDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.faculty.consent.allowLiveStatus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TimetableProvider>().fetchTimetableData(widget.faculty.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Faculty'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 32),
            _buildInfoSection(context),
            const SizedBox(height: 24),
            _buildTimetableButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final provider = context.watch<FacultyProvider>();
    final deptName = provider.getDepartmentName(widget.faculty.departmentId) ?? 'Unknown Dept';
    final designationTitle = provider.getDesignationTitle(widget.faculty.designationId) ?? 'Unknown Designation';
    final subtitleText = '$deptName • $designationTitle';

    return Column(
      children: [
        if (widget.faculty.canShowPhoto && widget.faculty.photoUrl != null && widget.faculty.photoUrl!.isNotEmpty)
          CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(widget.faculty.photoUrl!),
            backgroundColor: AppTheme.darkAccent,
          )
        else
          CircleAvatar(
            radius: 60,
            backgroundColor: AppTheme.darkAccent,
            child: Text(
              widget.faculty.canShowName && widget.faculty.name.isNotEmpty 
                  ? widget.faculty.name[0].toUpperCase() 
                  : '?',
              style: const TextStyle(
                color: AppTheme.darkEmphasizedText,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          widget.faculty.canShowName ? widget.faculty.name : 'Name Hidden',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          subtitleText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.darkTextSecondary,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    if (!widget.faculty.consent.allowLiveStatus) {
      return const SizedBox.shrink();
    }

    return Consumer<TimetableProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final statusText = provider.getCurrentStatus(widget.faculty);
        Color bgColor = AppTheme.statusUnknownBg;
        Color textColor = AppTheme.statusUnknownText;

        if (statusText == 'Available') {
          bgColor = AppTheme.statusAvailableBg;
          textColor = AppTheme.statusAvailableText;
        } else if (statusText == 'In Class') {
          bgColor = AppTheme.statusInClassBg;
          textColor = AppTheme.statusInClassText;
        } else if (statusText != 'Unknown') {
          // It's an exception reason like "On Leave"
          bgColor = AppTheme.statusInClassBg; // Mapping to same severity tier
          textColor = AppTheme.statusWarning;
        }

        String displayStatus = statusText;
        if (statusText == 'Unknown' && DateTime.now().weekday == DateTime.sunday) {
          displayStatus = 'No classes today';
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                displayStatus,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (provider.isUsingCachedData) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'May be outdated',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (widget.faculty.canShowCabinNo) ...[
            _buildInteractiveInfoRow(
              context,
              icon: Icons.door_front_door_outlined,
              label: 'Cabin No.',
              value: widget.faculty.cabinNo.isEmpty ? 'Not Assigned' : widget.faculty.cabinNo,
              showChevron: true,
              onTap: () {
                if (widget.faculty.locationId != null && widget.faculty.locationId!.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(
                        highlightLocationId: widget.faculty.locationId,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No map location mapped for this cabin.')),
                  );
                }
              },
            ),
            const Divider(color: Colors.white12, height: 32),
          ],
          if (widget.faculty.canShowEmail) ...[
            _buildInteractiveInfoRow(
              context,
              icon: Icons.email_outlined,
              label: 'Email',
              value: widget.faculty.email ?? 'Not Available',
              onTap: () async {
                if (widget.faculty.email != null && widget.faculty.email!.isNotEmpty) {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: widget.faculty.email,
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  }
                }
              },
            ),
            const Divider(color: Colors.white12, height: 32),
          ],
          if (widget.faculty.canShowPhone && widget.faculty.phone != null && widget.faculty.phone!.isNotEmpty) ...[
            _buildInteractiveInfoRow(
              context,
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: widget.faculty.phone!,
              onTap: () async {
                final Uri phoneUri = Uri(
                  scheme: 'tel',
                  path: widget.faculty.phone,
                );
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                }
              },
            ),
          ] else ...[
            _buildMutedInfoRow(
              context,
              icon: Icons.phone_outlined,
              label: 'Phone number not shared by this faculty member',
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildInteractiveInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool showChevron = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.darkAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: AppTheme.darkTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (showChevron)
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white24,
            ),
        ],
      ),
    );
  }

  Widget _buildMutedInfoRow(BuildContext context, {required IconData icon, required String label}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(13),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white24, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.darkTextSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimetableButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FacultyTimetableScreen(faculty: widget.faculty),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.darkAccent,
          foregroundColor: AppTheme.darkEmphasizedText,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'View Timetable',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
