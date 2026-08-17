import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/location/location_places.dart';
import '../../core/utils/friendly_error.dart';
import '../../providers/providers.dart';
import '../../repositories/places_repository.dart';
import '../../shared/widgets/widgets.dart';

class ChangeLocationScreen extends ConsumerStatefulWidget {
  const ChangeLocationScreen({super.key});

  @override
  ConsumerState<ChangeLocationScreen> createState() => _ChangeLocationScreenState();
}

class _ChangeLocationScreenState extends ConsumerState<ChangeLocationScreen> {
  final _search = TextEditingController();
  final _mapController = MapController();
  late double _lat;
  late double _lng;
  String _label = 'Select on map';
  bool _busy = false;
  bool _resolvingAddress = false;
  bool _showSuggestions = false;
  String? _error;
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _lat = user?.lat ?? 19.0760;
    _lng = user?.lng ?? 72.8777;
    _label = user?.areaLabel ?? cityLabelFor(_lat, _lng);
    _search.text = _label.split(',').first;
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _search.text.trim();
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetchSuggestions(query));
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final repo = ref.read(placesRepositoryProvider);
      final results = await repo.autocomplete(query, lat: _lat, lng: _lng);
      if (!mounted || _search.text.trim() != query) return;
      setState(() {
        _suggestions = results;
        _showSuggestions = results.isNotEmpty;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    }
  }

  void _moveTo(double lat, double lng, {String? label}) {
    setState(() {
      _lat = lat;
      _lng = lng;
      if (label != null && label.isNotEmpty) {
        _label = label;
      }
      _showSuggestions = false;
      _error = null;
    });
    _mapController.move(LatLng(lat, lng), 13);
    if (label == null || label.isEmpty) {
      _resolveAddress(lat, lng);
    }
  }

  Future<void> _resolveAddress(double lat, double lng) async {
    setState(() => _resolvingAddress = true);
    try {
      final place = await ref.read(placesRepositoryProvider).reverseGeocode(lat, lng);
      if (!mounted) return;
      setState(() {
        _label = place.label;
        _search.text = place.label.split(',').first;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _label = cityLabelFor(lat, lng);
        _error = friendlyError(e);
      });
    } finally {
      if (mounted) setState(() => _resolvingAddress = false);
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion place) async {
    _search.text = place.label.split(',').first;
    setState(() {
      _showSuggestions = false;
      _busy = true;
      _error = null;
    });

    try {
      if (place.lat != null && place.lng != null) {
        _moveTo(place.lat!, place.lng!, label: place.label);
        return;
      }
      if (place.placeId != null) {
        final resolved = await ref.read(placesRepositoryProvider).resolvePlace(place.placeId!);
        if (!mounted) return;
        _moveTo(resolved.lat!, resolved.lng!, label: resolved.label);
        _search.text = resolved.label.split(',').first;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _usePreciseLocation() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = ref.read(locationServiceProvider);
      final granted = await service.ensurePermission(request: true);
      if (!granted) {
        setState(() => _error = 'Location permission is required. Enable it in Settings.');
        return;
      }
      final loc = await service.current(precise: true);
      if (loc == null) {
        setState(() => _error = 'Could not detect your location. Try again or pick on the map.');
        return;
      }
      _moveTo(loc.lat, loc.lng);
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).saveLocation(lat: _lat, lng: _lng, areaLabel: _label);
      ref.invalidate(nearbyJobsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location set to ${_label.split(',').first}')));
        context.pop();
      }
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.hint(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose location'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  onTap: () => setState(() => _showSuggestions = _search.text.trim().length >= 2 && _suggestions.isNotEmpty),
                  decoration: InputDecoration(
                    hintText: 'Search area, city, landmark',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _search.clear();
                              setState(() {
                                _showSuggestions = false;
                                _suggestions = [];
                              });
                            },
                          ),
                  ),
                ),
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: AppColors.panel(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).dividerColor),
                      itemBuilder: (_, i) {
                        final place = _suggestions[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined, color: AppColors.accent),
                          title: Text(place.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          onTap: () => _selectSuggestion(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_lat, _lng),
                    initialZoom: 13,
                    onTap: (_, point) => _moveTo(point.latitude, point.longitude),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.time2work.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_lat, _lng),
                          width: 44,
                          height: 44,
                          child: const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 44),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Material(
                    color: AppColors.panel(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.place_outlined, color: AppColors.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Selected area', style: TextStyle(color: muted, fontSize: 11)),
                                if (_resolvingAddress)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: muted),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Fetching address…', style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
                                    ],
                                  )
                                else
                                  Text(_label, style: const TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.canvas(context),
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.6))),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _usePreciseLocation,
                    icon: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location_rounded),
                    label: const Text('Use precise location'),
                  ),
                  const SizedBox(height: 10),
                  AppButton(label: 'Confirm location', loading: _busy, onPressed: _confirm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
