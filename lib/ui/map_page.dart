import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  late LatLng _initialCenter;
  final Set<Marker> _markers = {};

  // Application-specific env (dart-define) takes precedence
  String _envOrDotenv(String key, String defaultValue) {
    // For application-specific envs passed via --dart-define we can only read
    // compile-time constants. Check the known keys explicitly.
    String fromDefine = '';
    if (key == 'HOME_LAT') {
      fromDefine = const String.fromEnvironment('HOME_LAT');
    }
    if (key == 'HOME_LNG') {
      fromDefine = const String.fromEnvironment('HOME_LNG');
    }
    if (key == 'WORK_LAT') {
      fromDefine = const String.fromEnvironment('WORK_LAT');
    }
    if (key == 'WORK_LNG') {
      fromDefine = const String.fromEnvironment('WORK_LNG');
    }

    if (fromDefine.isNotEmpty) return fromDefine;

    // fallback to dotenv if loaded
    final d = dotenv.env[key];
    if (d != null && d.isNotEmpty) return d;

    return defaultValue;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialCoordinates();
  }

  void _loadInitialCoordinates() {
    final homeLat = double.tryParse(_envOrDotenv('HOME_LAT', '0.0')) ?? 0.0;
    final homeLng = double.tryParse(_envOrDotenv('HOME_LNG', '0.0')) ?? 0.0;
    final workLat = double.tryParse(_envOrDotenv('WORK_LAT', '0.0')) ?? 0.0;
    final workLng = double.tryParse(_envOrDotenv('WORK_LNG', '0.0')) ?? 0.0;

    setState(() {
      _initialCenter = LatLng(homeLat, homeLng);
      _markers.clear();

      _markers.add(
        Marker(
          markerId: const MarkerId('home'),
          position: _initialCenter,
          infoWindow: const InfoWindow(title: 'Casa'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      if (workLat != 0.0 || workLng != 0.0) {
        _markers.add(
          Marker(
            markerId: const MarkerId('work'),
            position: LatLng(workLat, workLng),
            infoWindow: const InfoWindow(title: 'Trabajo'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
        );
      }

      for (final m in _markers) {
        // ignore: avoid_print
        print(
          'Marker loaded: ${m.markerId.value} @ ${m.position.latitude}, ${m.position.longitude}',
        );
      }
    });
  }

  void _addMarker(LatLng point, String title) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId(point.toString()),
          position: point,
          infoWindow: InfoWindow(title: title),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  void _updateMapPosition() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    if (lat != null && lng != null) {
      final newPoint = LatLng(lat, lng);
      _addMarker(newPoint, 'Ubicación');
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPoint, 15.0));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Latitud o Longitud inválida.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa con Google Maps'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _markers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latController,
                          decoration: const InputDecoration(
                            labelText: 'Latitud',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _lngController,
                          decoration: const InputDecoration(
                            labelText: 'Longitud',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: _updateMapPosition,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: const Text('Mostrar en el Mapa'),
                  ),
                ),
                Expanded(
                  child: GoogleMap(
                    onMapCreated: (controller) async {
                      _mapController = controller;
                      if (_markers.isNotEmpty) {
                        final lats = _markers
                            .map((m) => m.position.latitude)
                            .toList();
                        final lngs = _markers
                            .map((m) => m.position.longitude)
                            .toList();
                        final south = lats.reduce((a, b) => a < b ? a : b);
                        final north = lats.reduce((a, b) => a > b ? a : b);
                        final west = lngs.reduce((a, b) => a < b ? a : b);
                        final east = lngs.reduce((a, b) => a > b ? a : b);
                        final bounds = LatLngBounds(
                          southwest: LatLng(south, west),
                          northeast: LatLng(north, east),
                        );
                        await Future.delayed(const Duration(milliseconds: 300));
                        controller.animateCamera(
                          CameraUpdate.newLatLngBounds(bounds, 100),
                        );
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: _initialCenter,
                      zoom: 15.0,
                    ),
                    markers: _markers,
                  ),
                ),
              ],
            ),
    );
  }
}
