import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

Future<void> main() async {
  // Cargar las variables de entorno
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trabajo 1 - OSM',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  // Coordenadas iniciales (se cargan desde .env)
  late LatLng _initialCenter;
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _loadInitialCoordinates();
  }

  void _loadInitialCoordinates() {
    final homeLat = double.tryParse(dotenv.env['HOME_LAT'] ?? '0.0') ?? 0.0;
    final homeLng = double.tryParse(dotenv.env['HOME_LNG'] ?? '0.0') ?? 0.0;
    
    setState(() {
      _initialCenter = LatLng(homeLat, homeLng);
      _addMarker(_initialCenter, 'Casa');
    });
  }

  void _addMarker(LatLng point, String title) {
    _markers.clear(); // Limpiar marcadores anteriores
    _markers.add(
      Marker(
        width: 80.0,
        height: 80.0,
        point: point,
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            const Icon(Icons.location_pin, color: Colors.red, size: 40.0),
          ],
        ),
      ),
    );
  }

  void _updateMapPosition() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    if (lat != null && lng != null) {
      final newPoint = LatLng(lat, lng);
      setState(() {
        _addMarker(newPoint, 'Ubicación');
        _mapController.move(newPoint, 15.0);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Latitud o Longitud inválida.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Evita construir el mapa hasta que las coordenadas iniciales estén listas.
    if (_markers.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa con OpenStreetMap'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),
        ],
      ),
    );
  }
}