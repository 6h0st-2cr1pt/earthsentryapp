import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../models/earthquake_model.dart';
import '../services/weather_service.dart';
import '../services/earthquake_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final EarthquakeService _earthquakeService = EarthquakeService();
  final LocationService _locationService = LocationService();

  WeatherModel? _currentWeather;
  List<EarthquakeModel> _recentEarthquakes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final location = await _locationService.getCurrentLocation();
      final weather = await _weatherService.getWeatherByCoordinates(
        location.latitude,
        location.longitude,
        location.name ?? 'Current Location',
      );

      // Get all earthquakes for home screen summary
      final earthquakes = await _earthquakeService.getAllEarthquakes(philippinesOnly: false);
      final recent = earthquakes.take(5).toList();

      setState(() {
        _currentWeather = weather;
        _recentEarthquakes = recent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildHeader(),
                        const SizedBox(height: 30),
                        if (_currentWeather != null) _buildWeatherCard(_currentWeather!),
                        const SizedBox(height: 20),
                        _buildEarthquakeSummary(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GeoSentry',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Weather & Earthquake Monitoring',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildWeatherCard(WeatherModel weather) {
    return Container(
      decoration: AppTheme.gradientDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.locationName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weather.getWeatherDescription(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text(
                '${weather.temperature.toStringAsFixed(1)}°C',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherInfo(
                Icons.water_drop,
                '${weather.humidity.toStringAsFixed(0)}%',
                'Humidity',
              ),
              _buildWeatherInfo(
                Icons.air,
                '${weather.windSpeed.toStringAsFixed(1)} km/h',
                'Wind',
              ),
              _buildWeatherInfo(
                Icons.compress,
                '${weather.pressure.toStringAsFixed(0)} hPa',
                'Pressure',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textPrimary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildEarthquakeSummary() {
    return Container(
      decoration: AppTheme.claymorphismDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Earthquakes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '${_recentEarthquakes.length} today',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentEarthquakes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Text('No recent earthquakes'),
              ),
            )
          else
            ..._recentEarthquakes.map((eq) => _buildEarthquakeItem(eq)),
        ],
      ),
    );
  }

  Widget _buildEarthquakeItem(EarthquakeModel eq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(eq.getMagnitudeColor()).withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Color(eq.getMagnitudeColor()).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(eq.getMagnitudeColor()),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                eq.magnitude.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eq.locationName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${eq.depth.toStringAsFixed(1)} km depth • ${_formatTime(eq.time)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

