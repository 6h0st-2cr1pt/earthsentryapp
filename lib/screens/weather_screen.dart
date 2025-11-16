import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  late TabController _tabController;

  WeatherModel? _gpsWeather;
  WeatherModel? _inputWeather;
  Map<String, dynamic>? _gpsForecast;
  Map<String, dynamic>? _inputForecast;
  bool _isLoadingGPS = true;
  bool _isLoadingInput = false;
  String _errorMessage = '';
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGPSWeather();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadGPSWeather() async {
    setState(() {
      _isLoadingGPS = true;
      _errorMessage = '';
    });

    try {
      final location = await _locationService.getCurrentLocation();
      final weather = await _weatherService.getWeatherByCoordinates(
        location.latitude,
        location.longitude,
        location.name ?? 'Current Location',
      );
      final forecast = await _weatherService.getForecast(
        location.latitude,
        location.longitude,
      );

      setState(() {
        _gpsWeather = weather;
        _gpsForecast = forecast;
        _isLoadingGPS = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingGPS = false;
      });
    }
  }

  Future<void> _loadInputWeather() async {
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location')),
      );
      return;
    }

    setState(() {
      _isLoadingInput = true;
      _errorMessage = '';
    });

    try {
      final location = await _locationService.getLocationFromAddress(
        _locationController.text.trim(),
      );
      final weather = await _weatherService.getWeatherByCoordinates(
        location.latitude,
        location.longitude,
        location.name ?? _locationController.text.trim(),
      );
      final forecast = await _weatherService.getForecast(
        location.latitude,
        location.longitude,
      );

      setState(() {
        _inputWeather = weather;
        _inputForecast = forecast;
        _isLoadingInput = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingInput = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $_errorMessage')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: AppTheme.claymorphismDecoration(),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.accentDark,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.accentDark,
              tabs: const [
                Tab(text: 'GPS Location'),
                Tab(text: 'Input Location'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGPSWeatherTab(),
                _buildInputWeatherTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGPSWeatherTab() {
    if (_isLoadingGPS) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty && _gpsWeather == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGPSWeather,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_gpsWeather == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: _loadGPSWeather,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildWeatherDetails(_gpsWeather!, _gpsForecast),
          ],
        ),
      ),
    );
  }

  Widget _buildInputWeatherTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            decoration: AppTheme.claymorphismDecoration(),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: 'Enter location (e.g., Manila, Philippines)',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    onSubmitted: (_) => _loadInputWeather(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoadingInput ? null : _loadInputWeather,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: _isLoadingInput
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Search'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoadingInput)
            const Center(child: CircularProgressIndicator())
          else if (_inputWeather != null)
            _buildWeatherDetails(_inputWeather!, _inputForecast)
          else
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search for weather by location',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails(
    WeatherModel weather,
    Map<String, dynamic>? forecast,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Weather Card
        Container(
          decoration: AppTheme.gradientDecoration(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weather.locationName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                weather.getWeatherDescription(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${weather.temperature.toStringAsFixed(1)}°C',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Feels like ${weather.apparentTemperature.toStringAsFixed(1)}°C',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Weather Details Grid
        _buildDetailsGrid(weather),
        if (forecast != null) ...[
          const SizedBox(height: 20),
          _buildForecastSection(forecast),
        ],
      ],
    );
  }

  Widget _buildDetailsGrid(WeatherModel weather) {
    return Container(
      decoration: AppTheme.claymorphismDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather Details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildDetailCard(
                Icons.water_drop,
                'Humidity',
                '${weather.humidity.toStringAsFixed(0)}%',
              ),
              _buildDetailCard(
                Icons.air,
                'Wind Speed',
                '${weather.windSpeed.toStringAsFixed(1)} km/h',
              ),
              _buildDetailCard(
                Icons.explore,
                'Wind Direction',
                '${weather.windDirection.toStringAsFixed(0)}°',
              ),
              _buildDetailCard(
                Icons.cloud,
                'Cloud Cover',
                '${weather.cloudCover.toStringAsFixed(0)}%',
              ),
              _buildDetailCard(
                Icons.water,
                'Precipitation',
                '${weather.precipitation.toStringAsFixed(1)} mm',
              ),
              _buildDetailCard(
                Icons.compress,
                'Pressure',
                '${weather.pressure.toStringAsFixed(0)} hPa',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentDark, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection(Map<String, dynamic> forecast) {
    final daily = forecast['daily'] ?? {};
    final times = (daily['time'] as List?) ?? [];
    final maxTemps = (daily['temperature_2m_max'] as List?) ?? [];
    final minTemps = (daily['temperature_2m_min'] as List?) ?? [];
    final weatherCodes = (daily['weather_code'] as List?) ?? [];

    return Container(
      decoration: AppTheme.claymorphismDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-Day Forecast',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...List.generate(
            times.length > 7 ? 7 : times.length,
            (index) => _buildForecastItem(
              times[index],
              maxTemps[index],
              minTemps[index],
              weatherCodes[index],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastItem(
    dynamic dateStr,
    dynamic maxTemp,
    dynamic minTemp,
    dynamic weatherCode,
  ) {
    final date = DateTime.tryParse(dateStr.toString()) ?? DateTime.now();
    final dayName = _getDayName(date.weekday);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              dayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: Text(
              _getWeatherCodeDescription(int.tryParse(weatherCode.toString()) ?? 0),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            '${(maxTemp ?? 0).toStringAsFixed(0)}° / ${(minTemp ?? 0).toStringAsFixed(0)}°',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getWeatherCodeDescription(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Clear';
    if (code <= 48) return 'Fog';
    if (code <= 55) return 'Drizzle';
    if (code <= 65) return 'Rain';
    if (code <= 67) return 'Freezing Rain';
    if (code <= 77) return 'Snow';
    if (code <= 86) return 'Rain Showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }
}

