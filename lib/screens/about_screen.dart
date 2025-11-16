import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildHeader(context),
            const SizedBox(height: 30),
            _buildSection(
              context,
              'App Description',
              'GeoSentry is a comprehensive weather and earthquake monitoring application designed specifically for the Philippines. The app provides real-time weather information and earthquake data to help users stay informed and safe.',
              Icons.info_outline,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Features',
              '• Real-time weather monitoring based on GPS location\n• Weather forecast for any location in the Philippines\n• Comprehensive earthquake data from USGS and PHIVOLCS\n• Interactive earthquake map with magnitude visualization\n• Detailed earthquake information with severity levels\n• Dark claymorphism UI design',
              Icons.star_outline,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Developer Information',
              'Developed for University Weather and Earthquakes Monitoring\n\nThis app is designed to provide accurate and timely information about weather conditions and seismic activity in the Philippines.',
              Icons.person_outline,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Tech Stack',
              '• Flutter & Dart\n• SQLite Database\n• Open-Meteo API (Weather)\n• USGS Earthquake API\n• PHIVOLCS Web Scraping\n• Geolocator (GPS)\n• Flutter Map\n• Provider (State Management)',
              Icons.code_outlined,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Data Sources',
              '• Weather Data: Open-Meteo API\n• Earthquake Data: USGS Earthquake Hazards Program\n• Earthquake Data: PHIVOLCS (Philippine Institute of Volcanology and Seismology)',
              Icons.data_usage_outlined,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Version',
              '1.0.0',
              Icons.phone_android_outlined,
            ),
            const SizedBox(height: 40),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.claymorphismDecoration(),
                child: Column(
                  children: [
                    Icon(
                      Icons.public,
                      size: 48,
                      color: AppTheme.accentDark,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Stay Safe, Stay Informed',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientDecoration(),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.public,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'GeoSentry',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Weather & Earthquake Monitoring App',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.claymorphismDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentDark, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

