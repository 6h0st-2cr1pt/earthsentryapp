import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../models/earthquake_model.dart';
import '../services/earthquake_service.dart';
import '../theme/app_theme.dart';

class EarthquakeMapScreen extends StatefulWidget {
  const EarthquakeMapScreen({super.key});

  @override
  State<EarthquakeMapScreen> createState() => _EarthquakeMapScreenState();
}

class _EarthquakeMapScreenState extends State<EarthquakeMapScreen> {
  final EarthquakeService _earthquakeService = EarthquakeService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<EarthquakeModel> _earthquakes = [];
  bool _isLoading = true;
  EarthquakeModel? _selectedEarthquake;

  // Philippines bounds
  static const double phMinLat = 4.0;
  static const double phMaxLat = 21.0;
  static const double phMinLon = 116.0;
  static const double phMaxLon = 127.0;
  static const LatLng phCenter = LatLng(14.5995, 120.9842);

  @override
  void initState() {
    super.initState();
    _loadEarthquakes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEarthquakes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final earthquakes = await _earthquakeService.getAllEarthquakes();
      // Filter for Philippines only
      final phEarthquakes = earthquakes.where((eq) =>
          eq.latitude >= phMinLat &&
          eq.latitude <= phMaxLat &&
          eq.longitude >= phMinLon &&
          eq.longitude <= phMaxLon).toList();

      setState(() {
        _earthquakes = phEarthquakes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading earthquakes: $e')),
        );
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedEarthquake = null;
    });
  }

  void _onMarkerTap(EarthquakeModel earthquake) {
    setState(() {
      _selectedEarthquake = earthquake;
    });
    _mapController.move(
      LatLng(earthquake.latitude, earthquake.longitude),
      _mapController.camera.zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: phCenter,
              initialZoom: 6.0,
              minZoom: 5.0,
              maxZoom: 15.0,
              onTap: _onMapTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.earthsentry',
                tileProvider: CancellableNetworkTileProvider(),
              ),
              MarkerLayer(
                markers: _earthquakes.map((eq) {
                  return Marker(
                    point: LatLng(eq.latitude, eq.longitude),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _onMarkerTap(eq),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(eq.getMagnitudeColor()),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            eq.magnitude.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          // Search bar
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Container(
              decoration: AppTheme.claymorphismDecoration(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppTheme.textPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search location (Philippines only)',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      onSubmitted: (value) {
                        // Filter earthquakes by location
                        if (value.isEmpty) {
                          _loadEarthquakes();
                        } else {
                          setState(() {
                            _earthquakes = _earthquakes.where((eq) =>
                                eq.locationName
                                    .toLowerCase()
                                    .contains(value.toLowerCase())).toList();
                          });
                        }
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.textPrimary),
                      onPressed: () {
                        _searchController.clear();
                        _loadEarthquakes();
                      },
                    ),
                ],
              ),
            ),
          ),
          // Selected earthquake info card
          if (_selectedEarthquake != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _buildEarthquakeInfoCard(_selectedEarthquake!),
            ),
          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          // Legend
          Positioned(
            bottom: _selectedEarthquake != null ? 200 : 20,
            right: 16,
            child: _buildLegend(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController.move(phCenter, 6.0);
          setState(() {
            _selectedEarthquake = null;
          });
        },
        backgroundColor: AppTheme.accentDark,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildEarthquakeInfoCard(EarthquakeModel eq) {
    final color = Color(eq.getMagnitudeColor());

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eq.locationName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${eq.getSeverityLevel()} • ${_formatDateTime(eq.time)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedEarthquake = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('Magnitude', eq.magnitude.toStringAsFixed(1)),
              _buildInfoItem('Depth', '${eq.depth.toStringAsFixed(1)} km'),
              if (eq.intensity != null)
                _buildInfoItem('Intensity', eq.intensity!.toStringAsFixed(1)),
            ],
          ),
          if (eq.tsunamiWarning != null && eq.tsunamiWarning!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tsunami Warning: ${eq.tsunamiWarning}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      decoration: AppTheme.claymorphismDecoration(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Magnitude',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _buildLegendItem('1-1.9', 0xFF1B2A30),
          _buildLegendItem('2-2.9', 0xFF305853),
          _buildLegendItem('3-3.9', 0xFF4CAF50),
          _buildLegendItem('4-4.9', 0xFFB06821),
          _buildLegendItem('5-5.9', 0xFFFFD53D),
          _buildLegendItem('6-6.9', 0xFFFF8C00),
          _buildLegendItem('7-7.9', 0xFF9E2C21),
          _buildLegendItem('8+', 0xFFD00000),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Color(color),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

