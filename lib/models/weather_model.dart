class WeatherModel {
  final double latitude;
  final double longitude;
  final double temperature;
  final double apparentTemperature;
  final double humidity;
  final double windSpeed;
  final double windDirection;
  final double precipitation;
  final double cloudCover;
  final double pressure;
  final String timezone;
  final DateTime time;
  final String weatherCode;
  final String locationName;
  
  // Additional current weather data
  final bool? isDay;
  final double? rain;
  final double? showers;
  final double? snowfall;
  final double? pressureMsl;
  final double? windGusts;
  final double? dewPoint;
  final double? precipitationProbability;
  final double? visibility;
  final double? cloudCoverLow;
  final double? cloudCoverMid;
  final double? cloudCoverHigh;
  final double? evapotranspiration;
  final double? vapourPressureDeficit;

  WeatherModel({
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.precipitation,
    required this.cloudCover,
    required this.pressure,
    required this.timezone,
    required this.time,
    required this.weatherCode,
    required this.locationName,
    this.isDay,
    this.rain,
    this.showers,
    this.snowfall,
    this.pressureMsl,
    this.windGusts,
    this.dewPoint,
    this.precipitationProbability,
    this.visibility,
    this.cloudCoverLow,
    this.cloudCoverMid,
    this.cloudCoverHigh,
    this.evapotranspiration,
    this.vapourPressureDeficit,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json, String locationName) {
    final current = json['current'] ?? {};
    
    return WeatherModel(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      temperature: (current['temperature_2m'] ?? 0.0).toDouble(),
      apparentTemperature: (current['apparent_temperature'] ?? 0.0).toDouble(),
      humidity: (current['relative_humidity_2m'] ?? 0.0).toDouble(),
      windSpeed: (current['wind_speed_10m'] ?? 0.0).toDouble(),
      windDirection: (current['wind_direction_10m'] ?? 0.0).toDouble(),
      precipitation: (current['precipitation'] ?? 0.0).toDouble(),
      cloudCover: (current['cloud_cover'] ?? 0.0).toDouble(),
      pressure: (current['surface_pressure'] ?? 0.0).toDouble(),
      timezone: json['timezone'] ?? 'UTC',
      time: DateTime.parse(current['time'] ?? DateTime.now().toIso8601String()),
      weatherCode: (current['weather_code'] ?? 0).toString(),
      locationName: locationName,
      isDay: current['is_day'] == 1,
      rain: current['rain'] != null ? (current['rain'] as num).toDouble() : null,
      showers: current['showers'] != null ? (current['showers'] as num).toDouble() : null,
      snowfall: current['snowfall'] != null ? (current['snowfall'] as num).toDouble() : null,
      pressureMsl: current['pressure_msl'] != null ? (current['pressure_msl'] as num).toDouble() : null,
      windGusts: current['wind_gusts_10m'] != null ? (current['wind_gusts_10m'] as num).toDouble() : null,
    );
  }

  String getWeatherDescription() {
    final code = int.tryParse(weatherCode) ?? 0;
    if (code == 0) return 'Clear sky';
    if (code <= 3) return 'Mainly clear';
    if (code <= 48) return 'Fog';
    if (code <= 49) return 'Depositing rime fog';
    if (code <= 51) return 'Light drizzle';
    if (code <= 53) return 'Moderate drizzle';
    if (code <= 55) return 'Dense drizzle';
    if (code <= 56) return 'Light freezing drizzle';
    if (code <= 57) return 'Dense freezing drizzle';
    if (code <= 61) return 'Slight rain';
    if (code <= 63) return 'Moderate rain';
    if (code <= 65) return 'Heavy rain';
    if (code <= 66) return 'Light freezing rain';
    if (code <= 67) return 'Heavy freezing rain';
    if (code <= 71) return 'Slight snow fall';
    if (code <= 73) return 'Moderate snow fall';
    if (code <= 75) return 'Heavy snow fall';
    if (code <= 77) return 'Snow grains';
    if (code <= 82) return 'Slight rain showers';
    if (code <= 86) return 'Moderate/heavy rain showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }
}

