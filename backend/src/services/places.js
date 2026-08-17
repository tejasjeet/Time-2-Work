const { env } = require('../config/env');

const NOMINATIM = 'https://nominatim.openstreetmap.org';
const UA = 'Time2Work/1.0 (support@time2work.app)';

function formatNominatimAddress(item) {
  if (item.display_name) return item.display_name;
  const a = item.address || {};
  const parts = [
    a.neighbourhood,
    a.suburb,
    a.road,
    a.city || a.town || a.village,
    a.state,
    a.country,
  ].filter(Boolean);
  return parts.join(', ') || 'Selected location';
}

async function nominatimSearch(q, { lat, lng } = {}) {
  const params = new URLSearchParams({
    q,
    format: 'json',
    addressdetails: '1',
    limit: '6',
  });
  if (lat != null && lng != null) {
    params.set('viewbox', `${Number(lng) - 0.5},${Number(lat) + 0.5},${Number(lng) + 0.5},${Number(lat) - 0.5}`);
  }
  const res = await fetch(`${NOMINATIM}/search?${params}`, {
    headers: { 'User-Agent': UA, Accept: 'application/json' },
  });
  if (!res.ok) throw new Error('Place search failed');
  const data = await res.json();
  return (Array.isArray(data) ? data : []).map((item) => ({
    label: formatNominatimAddress(item),
    lat: Number(item.lat),
    lng: Number(item.lon),
    placeId: item.place_id != null ? String(item.place_id) : undefined,
  }));
}

async function nominatimReverse(lat, lng) {
  const params = new URLSearchParams({
    lat: String(lat),
    lon: String(lng),
    format: 'json',
    addressdetails: '1',
  });
  const res = await fetch(`${NOMINATIM}/reverse?${params}`, {
    headers: { 'User-Agent': UA, Accept: 'application/json' },
  });
  if (!res.ok) throw new Error('Reverse geocode failed');
  const data = await res.json();
  return { label: formatNominatimAddress(data), lat: Number(lat), lng: Number(lng) };
}

async function googleAutocomplete(q, { lat, lng } = {}) {
  const params = new URLSearchParams({
    input: q,
    key: env.googleMapsApiKey,
  });
  if (lat != null && lng != null) {
    params.set('location', `${lat},${lng}`);
    params.set('radius', '50000');
  }
  params.set('components', 'country:in');
  const res = await fetch(`https://maps.googleapis.com/maps/api/place/autocomplete/json?${params}`);
  const data = await res.json();
  if (data.status !== 'OK' && data.status !== 'ZERO_RESULTS') {
    throw new Error(data.error_message || data.status);
  }
  return (data.predictions || []).slice(0, 6).map((p) => ({
    label: p.description,
    placeId: p.place_id,
  }));
}

async function googlePlaceDetails(placeId) {
  const params = new URLSearchParams({
    place_id: placeId,
    key: env.googleMapsApiKey,
    fields: 'formatted_address,geometry,name',
  });
  const res = await fetch(`https://maps.googleapis.com/maps/api/place/details/json?${params}`);
  const data = await res.json();
  if (data.status !== 'OK') {
    throw new Error(data.error_message || data.status);
  }
  const r = data.result;
  const loc = r.geometry?.location;
  if (!loc) throw new Error('Place has no coordinates');
  return {
    label: r.formatted_address || r.name || 'Selected location',
    lat: Number(loc.lat),
    lng: Number(loc.lng),
    placeId,
  };
}

async function googleReverse(lat, lng) {
  const params = new URLSearchParams({
    latlng: `${lat},${lng}`,
    key: env.googleMapsApiKey,
  });
  const res = await fetch(`https://maps.googleapis.com/maps/api/geocode/json?${params}`);
  const data = await res.json();
  if (data.status !== 'OK' || !data.results?.length) {
    throw new Error(data.error_message || 'No address found');
  }
  const r = data.results[0];
  const loc = r.geometry?.location;
  return {
    label: r.formatted_address,
    lat: Number(loc?.lat ?? lat),
    lng: Number(loc?.lng ?? lng),
  };
}

async function searchPlaces(q, opts = {}) {
  const query = String(q || '').trim();
  if (query.length < 2) return [];

  if (env.googleMapsApiKey) {
    try {
      return await googleAutocomplete(query, opts);
    } catch (_) {
      /* fall through to Nominatim */
    }
  }
  return nominatimSearch(query, opts);
}

async function resolvePlace(placeId) {
  if (!placeId) throw new Error('placeId is required');
  if (env.googleMapsApiKey) {
    try {
      return await googlePlaceDetails(placeId);
    } catch (_) {
      /* fall through */
    }
  }
  throw new Error('Could not resolve place');
}

async function reverseGeocode(lat, lng) {
  const la = Number(lat);
  const ln = Number(lng);
  if (!Number.isFinite(la) || !Number.isFinite(ln)) {
    throw new Error('Invalid coordinates');
  }

  if (env.googleMapsApiKey) {
    try {
      return await googleReverse(la, ln);
    } catch (_) {
      /* fall through to Nominatim */
    }
  }
  return nominatimReverse(la, ln);
}

module.exports = { searchPlaces, resolvePlace, reverseGeocode };
