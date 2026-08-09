import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/widgets/cards.dart';
import 'package:airsentine1/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

enum MapLayerType { aqi, pm25, thermal }
enum MapViewMode { map, list }

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  MapLayerType _selectedLayer = MapLayerType.aqi;
  MapViewMode _viewMode = MapViewMode.map;
  String _searchQuery = '';
  bool _showPopup = true;

  // Central India default location (never 0,0)
  static const LatLng _indiaCenter = LatLng(20.5937, 78.9629);

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _centerMapOnStation(MonitoringStation station) {
    try {
      _mapController.move(station.location, 11.0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final allStations = ref.watch(stationsListProvider);
    final selectedStation = ref.watch(selectedStationProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58);

    // Filter stations based on search query
    final filteredStations = allStations.where((station) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return station.name.toLowerCase().contains(q) ||
          station.area.toLowerCase().contains(q) ||
          station.primaryPollutant.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.map_outlined, color: primaryColor),
            const SizedBox(width: 8),
            const Text('CPCB INTERACTIVE AQI MAP'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Controls Bar: Search Field, Layer Toggles, and Accessible List Mode Switcher
          _buildControlsBar(context, isDark, primaryColor),

          // 2. Main Content Area (Map View or Accessible List View)
          Expanded(
            child: _viewMode == MapViewMode.list
                ? _buildAccessibleListView(filteredStations, selectedStation, isDark, primaryColor)
                : isDesktop
                    ? _buildDesktopMapLayout(filteredStations, selectedStation, isDark, primaryColor)
                    : _buildMobileMapLayout(filteredStations, selectedStation, isDark, primaryColor),
          ),
        ],
      ),
    );
  }

  /// Top Controls Bar containing Search Field, Layer Toggles, and View Mode Toggle
  Widget _buildControlsBar(BuildContext context, bool isDark, Color primaryColor) {
    final barBg = isDark ? const Color(0xFF1E1B18) : Colors.white;
    final barBorder = isDark ? const Color(0xFF2E2924) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(bottom: BorderSide(color: barBorder)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Accessible Search Input Field
              Expanded(
                child: Semantics(
                  label: 'Search CPCB Stations by Name, City, or Area',
                  hint: 'Type a city name like Delhi, Mumbai, or Bengaluru',
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search stations (e.g. Anand Vihar, BKC)...',
                      labelText: 'SEARCH CPCB STATIONS',
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF28231E) : const Color(0xFFF1F5F9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Mode Toggle (Map View vs Accessible List View)
              Semantics(
                button: true,
                label: _viewMode == MapViewMode.map
                    ? 'Switch to Accessible Station List View'
                    : 'Switch to Interactive Map View',
                child: SegmentedButton<MapViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: MapViewMode.map,
                      icon: Icon(Icons.map, size: 18),
                      label: Text('MAP'),
                      tooltip: 'Interactive Map View',
                    ),
                    ButtonSegment(
                      value: MapViewMode.list,
                      icon: Icon(Icons.format_list_bulleted, size: 18),
                      label: Text('LIST (A11Y)'),
                      tooltip: 'Accessible Station List View',
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (set) {
                    setState(() {
                      _viewMode = set.first;
                    });
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return primaryColor.withValues(alpha: 0.2);
                      }
                      return isDark ? const Color(0xFF28231E) : Colors.white;
                    }),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Connected Pill Buttons for Map Layers (AQI Layer / PM2.5 / Thermal)
          Row(
            children: [
              const Text(
                'LAYER:',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF78716C)),
              ),
              const SizedBox(width: 8),
              _buildLayerPill('AQI SCALE', MapLayerType.aqi, Icons.filter_tilt_shift, isDark, primaryColor),
              const SizedBox(width: 6),
              _buildLayerPill('PM2.5 DENSITY', MapLayerType.pm25, Icons.grain, isDark, primaryColor),
              const SizedBox(width: 6),
              _buildLayerPill('THERMAL INTENSITY', MapLayerType.thermal, Icons.thermostat, isDark, primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  /// Layer Selector Pill Button
  Widget _buildLayerPill(String label, MapLayerType type, IconData icon, bool isDark, Color primaryColor) {
    final bool isSelected = _selectedLayer == type;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Switch map layer to $label',
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLayer = type;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : (isDark ? const Color(0xFF28231E) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isSelected ? Colors.white : (isDark ? const Color(0xFFF5F2EB) : const Color(0xFF334155)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Desktop Map Layout (Map Canvas + Side Panel)
  Widget _buildDesktopMapLayout(List<MonitoringStation> filteredStations, MonitoringStation selectedStation, bool isDark, Color primaryColor) {
    return Row(
      children: [
        // Interactive Map
        Expanded(
          flex: 3,
          child: _buildFlutterMapWidget(filteredStations, selectedStation, isDark),
        ),
        // Side Panel Details
        SizedBox(
          width: 340,
          child: _buildStationSidePanel(selectedStation, isDark, primaryColor),
        ),
      ],
    );
  }

  /// Mobile Map Layout (Map Canvas with Bottom Sheet Overlay)
  Widget _buildMobileMapLayout(List<MonitoringStation> filteredStations, MonitoringStation selectedStation, bool isDark, Color primaryColor) {
    return Stack(
      children: [
        _buildFlutterMapWidget(filteredStations, selectedStation, isDark),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: _buildStationBottomCard(selectedStation, isDark, primaryColor),
        ),
      ],
    );
  }

  /// Main flutter_map Widget centered on India
  Widget _buildFlutterMapWidget(List<MonitoringStation> filteredStations, MonitoringStation selectedStation, bool isDark) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _indiaCenter,
            initialZoom: 7.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // Standard OpenStreetMap Tile Layer
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.airsentinel.app',
            ),

            // Optional Thermal / Heatmap Layer Overlay Simulation
            if (_selectedLayer == MapLayerType.thermal)
              CircleLayer(
                circles: filteredStations.map((st) {
                  final meta = st.aqiMeta;
                  return CircleMarker(
                    point: st.location,
                    radius: st.aqi * 0.15 + 20,
                    useRadiusInMeter: false,
                    color: meta.color.withValues(alpha: 0.25),
                    borderColor: meta.color.withValues(alpha: 0.6),
                    borderStrokeWidth: 2,
                  );
                }).toList(),
              ),

            // CPCB Station Markers Layer
            MarkerLayer(
              markers: filteredStations.map((station) {
                final isSelected = station.id == selectedStation.id;
                final meta = station.aqiMeta;

                // Determine display value based on selected layer
                String markerText = '${station.aqi}';
                if (_selectedLayer == MapLayerType.pm25) {
                  final pm25 = station.pollutants.firstWhere(
                    (p) => p.code == 'PM2.5',
                    orElse: () => station.pollutants.first,
                  );
                  markerText = '${pm25.value.round()}';
                }

                return Marker(
                  width: isSelected ? 64 : 50,
                  height: isSelected ? 64 : 50,
                  point: station.location,
                  child: Semantics(
                    button: true,
                    label: 'Map pin for ${station.name} in ${station.area}. AQI ${station.aqi}, ${meta.label}',
                    child: GestureDetector(
                      onTap: () {
                        ref.read(selectedStationIdProvider.notifier).setStation(station.id);
                        setState(() {
                          _showPopup = true;
                        });
                        _centerMapOnStation(station);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: meta.color,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.black26,
                                width: isSelected ? 2.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: meta.color.withValues(alpha: isSelected ? 0.6 : 0.3),
                                  blurRadius: isSelected ? 12 : 6,
                                  spreadRadius: isSelected ? 2 : 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  const PulsingDot(color: Colors.white, size: 6),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  markerText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: meta.color,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Floating Interactive Map Zoom & Motion Control Buttons
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              Semantics(
                button: true,
                label: 'Zoom In Map',
                child: FloatingActionButton.small(
                  heroTag: 'map_zoom_in',
                  backgroundColor: isDark ? const Color(0xFF1E1B18) : Colors.white,
                  foregroundColor: isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58),
                  onPressed: () {
                    try {
                      _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
                    } catch (_) {}
                  },
                  child: const Icon(Icons.add),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                button: true,
                label: 'Zoom Out Map',
                child: FloatingActionButton.small(
                  heroTag: 'map_zoom_out',
                  backgroundColor: isDark ? const Color(0xFF1E1B18) : Colors.white,
                  foregroundColor: isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58),
                  onPressed: () {
                    try {
                      _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
                    } catch (_) {}
                  },
                  child: const Icon(Icons.remove),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                button: true,
                label: 'Center Map on India',
                child: FloatingActionButton.small(
                  heroTag: 'map_center_india',
                  backgroundColor: isDark ? const Color(0xFF1E1B18) : Colors.white,
                  foregroundColor: isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58),
                  onPressed: () {
                    try {
                      _mapController.move(_indiaCenter, 7.0);
                    } catch (_) {}
                  },
                  child: const Icon(Icons.center_focus_strong),
                ),
              ),
            ],
          ),
        ),

        // Marker Popup Callout Card
        if (_showPopup)
          Positioned(
            top: 20,
            left: 20,
            child: _buildMarkerPopupCallout(context, selectedStation, isDark),
          ),

        // Bottom Left Coordinates Overlay Card (Non-blocking)
        Positioned(
          left: 16,
          bottom: 20,
          child: _buildCoordinatesOverlay(selectedStation),
        ),
      ],
    );
  }

  /// Marker Callout Popup displaying Station Details and Hardware CTA
  Widget _buildMarkerPopupCallout(BuildContext context, MonitoringStation station, bool isDark) {
    final meta = station.aqiMeta;

    return Semantics(
      container: true,
      label: 'Station Map Popup for ${station.name}, AQI ${station.aqi}',
      child: FadeScaleModal(
        child: AppCard(
          padding: const EdgeInsets.all(14),
          backgroundColor: (isDark ? const Color(0xFF1E1B18) : Colors.white).withValues(alpha: 0.95),
          border: Border.all(color: meta.color, width: 1.5),
          child: SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        station.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _showPopup = false;
                        });
                      },
                    ),
                  ],
                ),
                Text(
                  station.area,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF78716C)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: meta.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'AQI ${station.aqi} • ${meta.label.toUpperCase()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: meta.badgeTextColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/station/${station.id}'),
                    icon: const Icon(Icons.developer_board, size: 14),
                    label: const Text('VIEW HARDWARE INFO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact "Selected Coordinates" Overlay Card
  Widget _buildCoordinatesOverlay(MonitoringStation station) {
    return IgnorePointer(
      ignoring: false,
      child: Semantics(
        label: 'Selected Station GPS Coordinates: Latitude ${station.location.latitude.toStringAsFixed(4)}, Longitude ${station.location.longitude.toStringAsFixed(4)}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xEC0F172A),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.my_location, color: Colors.cyanAccent, size: 14),
              const SizedBox(width: 8),
              Text(
                '${station.name.toUpperCase()} (${station.area.toUpperCase()}) • GPS: ${station.location.latitude.toStringAsFixed(4)} N, ${station.location.longitude.toStringAsFixed(4)} E',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Desktop Station Side Panel Details
  Widget _buildStationSidePanel(MonitoringStation station, bool isDark, Color primaryColor) {
    final meta = station.aqiMeta;
    final panelBg = isDark ? const Color(0xFF1E1B18) : Colors.white;
    final panelBorder = isDark ? const Color(0xFF2E2924) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panelBg,
        border: Border(left: BorderSide(color: panelBorder)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PulsingDot(color: meta.dotColor, size: 10),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    station.name.toUpperCase(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(station.area, style: const TextStyle(color: Color(0xFF78716C))),
            const SizedBox(height: 16),

            // Large AQI Callout Box
            AppCard(
              backgroundColor: meta.backgroundColor,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${station.aqi}',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: meta.badgeTextColor,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meta.label.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold, color: meta.badgeTextColor, fontSize: 11, letterSpacing: 0.6),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.air, color: meta.color, size: 40),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Key Pollutant Chips
            const Text('POLLUTANT SUB-INDICES:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: station.pollutants.map((p) {
                return Chip(
                  backgroundColor: isDark ? const Color(0xFF28231E) : const Color(0xFFF1F5F9),
                  label: Text('${p.code}: ${p.value.round()} ${p.unit}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Hardware Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/station/${station.id}'),
                icon: const Icon(Icons.developer_board),
                label: const Text('OPEN HARDWARE TELEMETRY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mobile Bottom Card for Selected Station
  Widget _buildStationBottomCard(MonitoringStation station, bool isDark, Color primaryColor) {
    final meta = station.aqiMeta;

    return AppCardLg(
      backgroundColor: (isDark ? const Color(0xFF1E1B18) : Colors.white).withValues(alpha: 0.95),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    PulsingDot(color: meta.dotColor, size: 8),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        station.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${station.area.toUpperCase()} • PRIMARY: ${station.primaryPollutant}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF78716C)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: meta.backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: meta.color),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${station.aqi}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: meta.badgeTextColor),
                ),
                Text(
                  meta.label.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: meta.badgeTextColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.chevron_right, color: primaryColor),
            onPressed: () => context.push('/station/${station.id}'),
          ),
        ],
      ),
    );
  }

  /// Mandatory Accessible Station List View Fallback
  Widget _buildAccessibleListView(List<MonitoringStation> stationsList, MonitoringStation selectedStation, bool isDark, Color primaryColor) {
    if (stationsList.isEmpty) {
      return const Center(
        child: Text('No matching stations found for your search query.'),
      );
    }

    return Semantics(
      label: 'Accessible Station List Fallback View. ${stationsList.length} stations available.',
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stationsList.length,
        itemBuilder: (context, index) {
          final station = stationsList[index];
          final isSelected = station.id == selectedStation.id;
          final meta = station.aqiMeta;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: 'Station ${station.name} in ${station.area}. AQI ${station.aqi}, CPCB Category: ${meta.label}. Primary pollutant: ${station.primaryPollutant}. Tap to select.',
              child: AppCard(
                onTap: () {
                  ref.read(selectedStationIdProvider.notifier).setStation(station.id);
                  _centerMapOnStation(station);
                },
                backgroundColor: isSelected ? meta.backgroundColor : (isDark ? const Color(0xFF1E1B18) : Colors.white),
                border: Border.all(
                  color: isSelected ? meta.color : (isDark ? const Color(0xFF2E2924) : const Color(0xFFE2E8F0)),
                  width: isSelected ? 2.0 : 1.0,
                ),
                child: Row(
                  children: [
                    // CPCB AQI Badge Box
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: meta.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${station.aqi}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            meta.label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Station Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                station.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: isSelected ? meta.badgeTextColor : (isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A)),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: meta.color,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${station.area.toUpperCase()} • PRIMARY: ${station.primaryPollutant}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF78716C)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            meta.healthAdvisory,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? meta.badgeTextColor : (isDark ? const Color(0xFFD6D3D1) : const Color(0xFF334155)),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Hardware Action Link
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: primaryColor),
                      tooltip: 'View Hardware Info',
                      onPressed: () => context.push('/station/${station.id}'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
