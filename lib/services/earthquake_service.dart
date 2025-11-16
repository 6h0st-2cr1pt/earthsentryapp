import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/earthquake_model.dart';

class EarthquakeService {
  static const String usgsUrl =
      'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson';
  static const String usgsQueryUrl =
      'https://earthquake.usgs.gov/fdsnws/event/1/query';
  static const String phivolcsUrl = 'https://earthquake.phivolcs.dost.gov.ph/';

  Future<List<EarthquakeModel>> getUSGSEarthquakes() async {
    try {
      final response = await http.get(Uri.parse(usgsUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final features = jsonData['features'] as List? ?? [];

        // Filter for Philippines region (approximately)
        final philippinesEarthquakes = features
            .map((feature) => EarthquakeModel.fromUSGSJson(feature))
            .where((eq) =>
                eq.latitude >= 4.0 &&
                eq.latitude <= 21.0 &&
                eq.longitude >= 116.0 &&
                eq.longitude <= 127.0)
            .toList();

        return philippinesEarthquakes;
      } else {
        throw Exception('Failed to load USGS earthquake data');
      }
    } catch (e) {
      throw Exception('Error fetching USGS earthquakes: $e');
    }
  }

  Future<List<EarthquakeModel>> getPHIVOLCSEarthquakes() async {
    try {
      final response = await http.get(Uri.parse(phivolcsUrl));

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final earthquakes = <EarthquakeModel>[];

        // Try to find earthquake data in the HTML
        // This is a simplified parser - you may need to adjust based on actual HTML structure
        final tables = document.querySelectorAll('table');
        
        for (var table in tables) {
          final rows = table.querySelectorAll('tr');
          
          for (var i = 1; i < rows.length; i++) {
            final cells = rows[i].querySelectorAll('td');
            
            if (cells.length >= 5) {
              try {
                final dateStr = cells[0].text.trim();
                final timeStr = cells[1].text.trim();
                final location = cells[2].text.trim();
                final magnitudeStr = cells[3].text.trim();
                final depthStr = cells[4].text.trim();
                final intensityStr = cells.length > 5 ? cells[5].text.trim() : null;
                final tsunamiStr = cells.length > 6 ? cells[6].text.trim() : null;

                final magnitude = double.tryParse(
                  magnitudeStr.replaceAll(RegExp(r'[^\d.]'), ''),
                ) ?? 0.0;

                final depth = double.tryParse(
                  depthStr.replaceAll(RegExp(r'[^\d.]'), ''),
                ) ?? 0.0;

                final intensity = intensityStr != null
                    ? double.tryParse(intensityStr.replaceAll(RegExp(r'[^\d.]'), ''))
                    : null;

                // Parse date and time
                DateTime? time;
                try {
                  final dateTimeStr = '$dateStr $timeStr';
                  time = DateTime.parse(dateTimeStr);
                } catch (e) {
                  time = DateTime.now();
                }

                // Try to extract coordinates from location or use approximate
                // For now, we'll use a placeholder - you may need geocoding
                final lat = 14.5995; // Approximate Philippines center
                final lon = 120.9842;

                earthquakes.add(
                  EarthquakeModel.fromPHIVOLCS(
                    locationName: location,
                    magnitude: magnitude,
                    intensity: intensity,
                    depth: depth,
                    time: time,
                    latitude: lat,
                    longitude: lon,
                    tsunamiWarning: tsunamiStr,
                  ),
                );
              } catch (e) {
                // Skip invalid rows
                continue;
              }
            }
          }
        }

        return earthquakes;
      } else {
        throw Exception('Failed to load PHIVOLCS earthquake data');
      }
    } catch (e) {
      // If scraping fails, return empty list or fallback to USGS
      return [];
    }
  }

  Future<List<EarthquakeModel>> getAllEarthquakes() async {
    try {
      final usgsEarthquakes = await getUSGSEarthquakes();
      final phivolcsEarthquakes = await getPHIVOLCSEarthquakes();

      // Combine and remove duplicates
      final allEarthquakes = <EarthquakeModel>[];
      final seenIds = <String>{};

      for (var eq in [...usgsEarthquakes, ...phivolcsEarthquakes]) {
        if (!seenIds.contains(eq.id)) {
          allEarthquakes.add(eq);
          seenIds.add(eq.id);
        }
      }

      // Sort by time (most recent first)
      allEarthquakes.sort((a, b) => b.time.compareTo(a.time));

      return allEarthquakes;
    } catch (e) {
      throw Exception('Error fetching all earthquakes: $e');
    }
  }

  /// Get earthquakes for a specific date
  Future<List<EarthquakeModel>> getEarthquakesByDate(DateTime date) async {
    try {
      final allEarthquakes = await getAllEarthquakes();
      
      // Filter earthquakes for the specified date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      return allEarthquakes.where((eq) {
        return eq.time.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) &&
               eq.time.isBefore(endOfDay);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching earthquakes by date: $e');
    }
  }

  /// Get earthquakes grouped by day
  Map<DateTime, List<EarthquakeModel>> getEarthquakesGroupedByDay(
    List<EarthquakeModel> earthquakes,
  ) {
    final grouped = <DateTime, List<EarthquakeModel>>{};
    
    for (var eq in earthquakes) {
      // Get the date without time component
      final date = DateTime(eq.time.year, eq.time.month, eq.time.day);
      
      if (grouped.containsKey(date)) {
        grouped[date]!.add(eq);
      } else {
        grouped[date] = [eq];
      }
    }
    
    // Sort earthquakes within each day (most recent first)
    grouped.forEach((date, eqList) {
      eqList.sort((a, b) => b.time.compareTo(a.time));
    });
    
    return grouped;
  }

  /// Get earthquakes for today
  Future<List<EarthquakeModel>> getTodayEarthquakes() async {
    return getEarthquakesByDate(DateTime.now());
  }

  /// Get earthquakes for the last N days
  Future<Map<DateTime, List<EarthquakeModel>>> getEarthquakesForLastDays(
    int days,
  ) async {
    try {
      final allEarthquakes = await getAllEarthquakes();
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      // Filter earthquakes from the last N days
      final recentEarthquakes = allEarthquakes.where((eq) {
        return eq.time.isAfter(cutoffDate);
      }).toList();
      
      return getEarthquakesGroupedByDay(recentEarthquakes);
    } catch (e) {
      throw Exception('Error fetching earthquakes for last days: $e');
    }
  }
}

