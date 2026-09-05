import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/location.dart';
import '../../providers/faculty_provider.dart';
import '../../utils/theme.dart';

class MapScreen extends StatefulWidget {
  final String? highlightLocationId;

  const MapScreen({super.key, this.highlightLocationId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.highlightLocationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<FacultyProvider>();
        final loc = provider.getLocation(widget.highlightLocationId!);
        if (loc != null) {
          _showLocationDetails(loc);
        }
      });
    }
  }

  void _showLocationDetails(Location loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.darkAccent.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.place_rounded, color: AppTheme.darkAccent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.type.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.darkAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.business_rounded, color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  Text(loc.building, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 24),
                  const Icon(Icons.layers_rounded, color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  Text(loc.floor, style: const TextStyle(fontSize: 16)),
                ],
              ),
              if (loc.description != null && loc.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 16),
                Text(
                  loc.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FacultyProvider>();
    final locations = List<Location>.from(provider.locations);

    // Grouping by Building -> Floor -> List<Location>
    // To present a sectioned list, we first sort all locations correctly
    locations.sort((a, b) {
      int cmp = a.building.compareTo(b.building);
      if (cmp != 0) return cmp;
      cmp = a.floor.compareTo(b.floor);
      if (cmp != 0) return cmp;
      return a.name.compareTo(b.name);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations'),
      ),
      body: locations.isEmpty
          ? const Center(
              child: Text(
                'No locations available',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final loc = locations[index];
                final bool showBuildingHeader = index == 0 || locations[index - 1].building != loc.building;
                final bool showFloorHeader = showBuildingHeader || locations[index - 1].floor != loc.floor;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showBuildingHeader)
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 8, left: 8),
                        child: Text(
                          loc.building,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkAccent,
                          ),
                        ),
                      ),
                    if (showFloorHeader)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 12, left: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.layers_rounded, color: Colors.white54, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              loc.floor,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Card(
                      color: AppTheme.darkCardBg,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(13),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.place_rounded, color: AppTheme.darkAccent, size: 20),
                        ),
                        title: Text(
                          loc.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            loc.type.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                        onTap: () => _showLocationDetails(loc),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}