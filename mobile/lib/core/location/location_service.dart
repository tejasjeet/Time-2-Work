import 'package:geolocator/geolocator.dart';

class AppLocation {
  final double lat;
  final double lng;
  const AppLocation(this.lat, this.lng);
}

class LocationService {
  Future<bool> ensurePermission({bool request = true}) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && request) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<bool> openSettings() => Geolocator.openLocationSettings();

  Future<AppLocation?> current({bool precise = true}) async {
    final ok = await ensurePermission();
    if (!ok) return null;
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: precise ? LocationAccuracy.high : LocationAccuracy.low,
      ),
    );
    return AppLocation(pos.latitude, pos.longitude);
  }

  /// Approximate area label only — never expose exact coords in UI for others.
  String approximateArea({double? lat, double? lng}) {
    if (lat == null || lng == null) return 'Nearby area';
    return 'Approx. ${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)} area';
  }
}
