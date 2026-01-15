import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:servis_takip/utils/constants.dart';
import 'package:servis_takip/services/auth_service.dart';

class CreateRoutePage extends StatefulWidget {
  const CreateRoutePage({Key? key}) : super(key: key);

  @override
  _CreateRoutePageState createState() => _CreateRoutePageState();
}

class _CreateRoutePageState extends State<CreateRoutePage> {
  GoogleMapController? _mapController;
  List<dynamic> _availableStops = [];
  List<dynamic> _selectedStops = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final TextEditingController _routeNameController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  Future<void> _loadStops() async {
    setState(() => _isLoading = true);

    try {
      final token = await AuthService().getToken();
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/stops/my'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _availableStops = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Hata: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addStopToRoute(dynamic stop) {
    setState(() {
      _selectedStops.add(stop);
      _updateMapMarkers();
      _drawRouteLine();
    });
  }

  void _removeStopFromRoute(int index) {
    setState(() {
      _selectedStops.removeAt(index);
      _updateMapMarkers();
      _drawRouteLine();
    });
  }

  void _reorderStops(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _selectedStops.removeAt(oldIndex);
      _selectedStops.insert(newIndex, item);
      _updateMapMarkers();
      _drawRouteLine();
    });
  }

  void _updateMapMarkers() {
    _markers.clear();
    
    for (int i = 0; i < _selectedStops.length; i++) {
      final stop = _selectedStops[i];
      _markers.add(
        Marker(
          markerId: MarkerId('stop_${stop['id']}'),
          position: LatLng(stop['latitude'], stop['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0 ? BitmapDescriptor.hueGreen : // Başlangıç
            i == _selectedStops.length - 1 ? BitmapDescriptor.hueRed : // Bitiş
            BitmapDescriptor.hueBlue, // Ara duraklar
          ),
          infoWindow: InfoWindow(
            title: '${i + 1}. ${stop['name']}',
          ),
        ),
      );
    }
  }

  void _drawRouteLine() {
    _polylines.clear();
    
    if (_selectedStops.length < 2) return;

    List<LatLng> routeCoordinates = _selectedStops
        .map((stop) => LatLng(stop['latitude'], stop['longitude']))
        .toList();

    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: routeCoordinates,
        color: Colors.blue,
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );

    // Haritayı tüm durakları gösterecek şekilde ayarla
    if (_mapController != null && routeCoordinates.isNotEmpty) {
      _fitBounds(routeCoordinates);
    }
  }

  void _fitBounds(List<LatLng> coordinates) {
    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;
    double minLng = coordinates.first.longitude;
    double maxLng = coordinates.first.longitude;

    for (var coord in coordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }

  Future<void> _saveRoute() async {
    if (_selectedStops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir durak seçin')),
      );
      return;
    }

    if (_routeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen rota için bir isim girin')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final token = await AuthService().getToken();
      final stopIds = _selectedStops.map((stop) => stop['id']).toList();

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/routes/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': _routeNameController.text.trim(),
          'stopIds': stopIds,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Rota başarıyla oluşturuldu'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Rota oluşturulurken hata: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rota Oluştur'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveRoute,
              tooltip: 'Rotayı Kaydet',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Rota ismi
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _routeNameController,
                    decoration: const InputDecoration(
                      labelText: 'Rota İsmi',
                      hintText: 'Örn: Sabah Rotası',
                      prefixIcon: Icon(Icons.route),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // Harita
                Expanded(
                  flex: 2,
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(41.0082, 28.9784),
                      zoom: 12,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),

                // Seçili duraklar listesi
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Seçili Duraklar (${_selectedStops.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showStopPicker(),
                              icon: const Icon(Icons.add),
                              label: const Text('Durak Ekle'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _selectedStops.isEmpty
                            ? const Center(
                                child: Text(
                                  'Henüz durak eklenmedi\nDurak eklemek için yukarıdaki butona tıklayın',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ReorderableListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                itemCount: _selectedStops.length,
                                onReorder: _reorderStops,
                                itemBuilder: (context, index) {
                                  final stop = _selectedStops[index];
                                  return Card(
                                    key: ValueKey(stop['id']),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: index == 0
                                            ? Colors.green
                                            : index == _selectedStops.length - 1
                                                ? Colors.red
                                                : Colors.blue,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      title: Text(stop['name']),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => _removeStopFromRoute(index),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showStopPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Durak Seç',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _availableStops.length,
                itemBuilder: (context, index) {
                  final stop = _availableStops[index];
                  final isSelected = _selectedStops.any((s) => s['id'] == stop['id']);
                  
                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: isSelected ? Colors.grey : Colors.blue,
                    ),
                    title: Text(stop['name']),
                    subtitle: Text(
                      'Lat: ${stop['latitude'].toStringAsFixed(6)}, '
                      'Lng: ${stop['longitude'].toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.add_circle_outline),
                    enabled: !isSelected,
                    onTap: () {
                      if (!isSelected) {
                        _addStopToRoute(stop);
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
