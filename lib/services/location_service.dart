import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/location_model.dart';

class LocationService {
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<LocationModel> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String locationName = 'Unknown';
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        locationName = [
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        name: locationName,
      );
    } catch (e) {
      throw Exception('Error getting location: $e');
    }
  }

  Future<LocationModel> getLocationFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isEmpty) {
        throw Exception('Location not found');
      }

      final location = locations.first;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      String locationName = address;
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        locationName = [
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }

      return LocationModel(
        latitude: location.latitude,
        longitude: location.longitude,
        name: locationName,
        address: address,
      );
    } catch (e) {
      throw Exception('Error getting location from address: $e');
    }
  }
}

