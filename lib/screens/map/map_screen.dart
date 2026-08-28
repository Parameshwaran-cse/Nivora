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
  Location? _selectedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.highlightLocationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<FacultyProvider>();
        final loc = provider.getLocation(widget.highlightLocationId!);
        if (loc != null) {
          setState(() {
            _selectedLocation = loc;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FacultyProvider>();
    final locations = provider.locations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Map'),
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0, // Assuming a square map for now
                  child: Stack(
                    children: [
                      // Placeholder map image
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.darkCardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.map_outlined,
                            size: 100,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                      // Pins
                      ...locations.map((loc) {
                        final isHighlighted = loc.id == widget.highlightLocationId || 
                                              loc.id == _selectedLocation?.id;
                        return Align(
                          alignment: Alignment(-1 + 2 * loc.mapX, -1 + 2 * loc.mapY),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedLocation = loc;
                              });
                            },
                            child: FractionalTranslation(
                              translation: const Offset(-0.5, -1.0), // center bottom of pin at mapX/mapY
                              child: Icon(
                                Icons.location_on_rounded,
                                size: isHighlighted ? 40 : 32,
                                color: isHighlighted ? AppTheme.darkAccent : Colors.white54,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_selectedLocation != null)
            _buildLocationInfoCard(_selectedLocation!),
        ],
      ),
    );
  }

  Widget _buildLocationInfoCard(Location loc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.darkCardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                onPressed: () {
                  setState(() {
                    _selectedLocation = null;
                  });
                },
              ),
            ],
          ),
          if (loc.description != null && loc.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              loc.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}