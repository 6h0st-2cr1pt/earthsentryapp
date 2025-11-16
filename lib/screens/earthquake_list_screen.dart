import 'package:flutter/material.dart';
import '../models/earthquake_model.dart';
import '../services/earthquake_service.dart';
import '../theme/app_theme.dart';

class EarthquakeListScreen extends StatefulWidget {
  const EarthquakeListScreen({super.key});

  @override
  State<EarthquakeListScreen> createState() => _EarthquakeListScreenState();
}

class _EarthquakeListScreenState extends State<EarthquakeListScreen> {
  final EarthquakeService _earthquakeService = EarthquakeService();
  final TextEditingController _searchController = TextEditingController();

  List<EarthquakeModel> _allEarthquakes = [];
  List<EarthquakeModel> _filteredEarthquakes = [];
  Map<DateTime, List<EarthquakeModel>> _groupedEarthquakes = {};
  bool _isLoading = true;
  String _selectedSeverity = 'All';
  bool _groupByDay = true; // Toggle for grouping by day
  bool _philippinesOnly = false; // Toggle for Philippines-only filter
  Set<String> _expandedIds = {};

  final List<String> _severityOptions = [
    'All',
    'Low',
    'Moderate',
    'High',
    'Extreme',
  ];

  @override
  void initState() {
    super.initState();
    _loadEarthquakes();
    _searchController.addListener(_filterEarthquakes);
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
      final earthquakes = await _earthquakeService.getAllEarthquakes(
        philippinesOnly: _philippinesOnly,
      );
      setState(() {
        _allEarthquakes = earthquakes;
        _filteredEarthquakes = earthquakes;
        _groupedEarthquakes = _earthquakeService.getEarthquakesGroupedByDay(earthquakes);
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

  void _filterEarthquakes() {
    final query = _searchController.text.toLowerCase();
    final severity = _selectedSeverity;

    setState(() {
      _filteredEarthquakes = _allEarthquakes.where((eq) {
        final matchesLocation = eq.locationName.toLowerCase().contains(query);
        final matchesSeverity = severity == 'All' || eq.getSeverityLevel() == severity;
        return matchesLocation && matchesSeverity;
      }).toList();
      
      // Update grouped earthquakes after filtering
      _groupedEarthquakes = _earthquakeService.getEarthquakesGroupedByDay(_filteredEarthquakes);
    });
  }

  void _onSeverityChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedSeverity = value;
      });
      _filterEarthquakes();
    }
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEarthquakes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No earthquakes found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEarthquakes,
                        child: _groupByDay
                            ? _buildGroupedListView()
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredEarthquakes.length,
                                itemBuilder: (context, index) {
                                  final eq = _filteredEarthquakes[index];
                                  final isExpanded = _expandedIds.contains(eq.id);
                                  return _buildEarthquakeCard(eq, isExpanded);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      decoration: AppTheme.claymorphismDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by location name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterEarthquakes();
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Severity:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSeverity,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: _severityOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: _onSeverityChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Philippines Only:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Switch(
                value: _philippinesOnly,
                onChanged: (value) {
                  setState(() {
                    _philippinesOnly = value;
                  });
                  _loadEarthquakes();
                },
                activeColor: AppTheme.accentDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Group by Day:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Switch(
                value: _groupByDay,
                onChanged: (value) {
                  setState(() {
                    _groupByDay = value;
                  });
                },
                activeColor: AppTheme.accentDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarthquakeCard(EarthquakeModel eq, bool isExpanded) {
    final color = Color(eq.getMagnitudeColor());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleExpand(eq.id),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          eq.magnitude.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: isExpanded ? null : 1,
                            overflow: isExpanded ? null : TextOverflow.ellipsis,
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
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white30),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Magnitude',
                    eq.magnitude.toStringAsFixed(1),
                    Icons.speed,
                  ),
                  if (eq.intensity != null)
                    _buildDetailRow(
                      'Intensity',
                      eq.intensity!.toStringAsFixed(1),
                      Icons.show_chart,
                    ),
                  _buildDetailRow(
                    'Depth',
                    '${eq.depth.toStringAsFixed(1)} km',
                    Icons.vertical_align_bottom,
                  ),
                  _buildDetailRow(
                    'Time',
                    _formatFullDateTime(eq.time),
                    Icons.access_time,
                  ),
                  if (eq.tsunamiWarning != null && eq.tsunamiWarning!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
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
                  if (eq.source != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Source: ${eq.source}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
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
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  String _formatFullDateTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildGroupedListView() {
    if (_groupedEarthquakes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text('No earthquakes found'),
        ),
      );
    }

    // Sort dates in descending order (most recent first)
    final sortedDates = _groupedEarthquakes.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final date = sortedDates[dateIndex];
        final earthquakes = _groupedEarthquakes[date]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(date, earthquakes.length),
            const SizedBox(height: 12),
            ...earthquakes.map((eq) {
              final isExpanded = _expandedIds.contains(eq.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEarthquakeCard(eq, isExpanded),
              );
            }),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date, int count) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (dateOnly == today) {
      dateText = 'Today';
    } else if (dateOnly == yesterday) {
      dateText = 'Yesterday';
    } else {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final weekday = weekdays[date.weekday - 1];
      dateText = '$weekday, ${date.day}/${date.month}/${date.year}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.accentDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentDark.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: AppTheme.accentDark,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            dateText,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count ${count == 1 ? 'earthquake' : 'earthquakes'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

