import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoRefreshEnabled = true;
  int _refreshInterval = 15; // minutes
  String _temperatureUnit = 'Celsius';
  String _distanceUnit = 'Kilometers';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Settings',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 30),
            _buildSection(
              'Notifications',
              [
                _buildSwitchTile(
                  'Enable Notifications',
                  'Receive alerts for earthquakes and weather updates',
                  _notificationsEnabled,
                  (value) => setState(() => _notificationsEnabled = value),
                  Icons.notifications_outlined,
                ),
                _buildSwitchTile(
                  'Auto Refresh',
                  'Automatically refresh data in the background',
                  _autoRefreshEnabled,
                  (value) => setState(() => _autoRefreshEnabled = value),
                  Icons.refresh_outlined,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              'Data Refresh',
              [
                _buildListTile(
                  'Refresh Interval',
                  '$_refreshInterval minutes',
                  Icons.timer_outlined,
                  () => _showRefreshIntervalDialog(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              'Units',
              [
                _buildListTile(
                  'Temperature Unit',
                  _temperatureUnit,
                  Icons.thermostat_outlined,
                  () => _showTemperatureUnitDialog(),
                ),
                _buildListTile(
                  'Distance Unit',
                  _distanceUnit,
                  Icons.straighten_outlined,
                  () => _showDistanceUnitDialog(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              'Data Management',
              [
                _buildListTile(
                  'Clear Cache',
                  'Clear cached weather and earthquake data',
                  Icons.delete_outline,
                  () => _showClearCacheDialog(),
                ),
                _buildListTile(
                  'Export Data',
                  'Export earthquake and weather data',
                  Icons.download_outlined,
                  () => _exportData(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              'About',
              [
                _buildListTile(
                  'App Version',
                  '1.0.0',
                  Icons.info_outline,
                  null,
                ),
                _buildListTile(
                  'Privacy Policy',
                  'View privacy policy',
                  Icons.privacy_tip_outlined,
                  () => _showPrivacyPolicy(),
                ),
                _buildListTile(
                  'Terms of Service',
                  'View terms of service',
                  Icons.description_outlined,
                  () => _showTermsOfService(),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: AppTheme.claymorphismDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentDark),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accentDark,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentDark),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: AppTheme.textSecondary)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    );
  }

  void _showRefreshIntervalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Refresh Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int interval in [5, 10, 15, 30, 60])
              RadioListTile<int>(
                title: Text('$interval minutes'),
                value: interval,
                groupValue: _refreshInterval,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _refreshInterval = value);
                    Navigator.pop(context);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showTemperatureUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Temperature Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Celsius'),
              value: 'Celsius',
              groupValue: _temperatureUnit,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _temperatureUnit = value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Fahrenheit'),
              value: 'Fahrenheit',
              groupValue: _temperatureUnit,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _temperatureUnit = value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDistanceUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Distance Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Kilometers'),
              value: 'Kilometers',
              groupValue: _distanceUnit,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _distanceUnit = value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Miles'),
              value: 'Miles',
              groupValue: _distanceUnit,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _distanceUnit = value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear all cached data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement cache clearing
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export feature coming soon')),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'GeoSentry respects your privacy. We only collect location data when you use the app to provide weather and earthquake information. All data is stored locally on your device and is not shared with third parties.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using GeoSentry, you agree to use the app responsibly. The weather and earthquake data provided is for informational purposes only and should not be used as the sole basis for safety decisions. Always follow official advisories from government agencies.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

