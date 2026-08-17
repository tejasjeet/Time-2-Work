function point([lng, lat]) {
  return { type: 'Point', coordinates: [Number(lng), Number(lat)] };
}

function fromLatLng(lat, lng) {
  if (lat === undefined || lng === undefined || lat === null || lng === null) return undefined;
  return point([Number(lng), Number(lat)]);
}

function toLatLng(location) {
  if (!location || !Array.isArray(location.coordinates) || location.coordinates.length < 2) {
    return null;
  }
  const [lng, lat] = location.coordinates;
  return { lat, lng };
}

function allowedRadiusKm(requested, settings) {
  const primary = settings.primaryRadiusKm || 5;
  const secondary = settings.secondaryRadiusKm || 10;
  const n = Number(requested);
  if (n === secondary) return secondary;
  if (n === primary) return primary;
  return primary;
}

module.exports = { point, fromLatLng, toLatLng, allowedRadiusKm };
