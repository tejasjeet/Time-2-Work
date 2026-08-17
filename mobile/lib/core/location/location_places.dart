class LocationPlace {
  final String label;
  final double lat;
  final double lng;

  const LocationPlace(this.label, this.lat, this.lng);
}

const locationPlaces = [
  LocationPlace('Patna, Bihar', 25.5941, 85.1376),
  LocationPlace('Mumbai, Maharashtra', 19.0760, 72.8777),
  LocationPlace('Delhi, NCR', 28.6139, 77.2090),
  LocationPlace('Bangalore, Karnataka', 12.9716, 77.5946),
  LocationPlace('Kolkata, West Bengal', 22.5726, 88.3639),
  LocationPlace('Hyderabad, Telangana', 17.3850, 78.4867),
  LocationPlace('Chennai, Tamil Nadu', 13.0827, 80.2707),
  LocationPlace('Pune, Maharashtra', 18.5204, 73.8567),
  LocationPlace('Ahmedabad, Gujarat', 23.0225, 72.5714),
  LocationPlace('Lucknow, Uttar Pradesh', 26.8467, 80.9462),
];

String cityLabelFor(double lat, double lng) {
  LocationPlace? nearest;
  var best = double.infinity;
  for (final place in locationPlaces) {
    final d = (place.lat - lat).abs() + (place.lng - lng).abs();
    if (d < best) {
      best = d;
      nearest = place;
    }
  }
  if (nearest != null && best < 1.2) return nearest.label;
  return 'Lat ${lat.toStringAsFixed(2)}, Lng ${lng.toStringAsFixed(2)}';
}

List<LocationPlace> searchPlaces(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return locationPlaces;
  return locationPlaces.where((p) => p.label.toLowerCase().contains(q)).toList();
}
