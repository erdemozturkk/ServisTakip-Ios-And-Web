import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:servis_takip/utils/constants.dart';
import 'package:servis_takip/services/auth_service.dart';

class AddStopPage extends StatefulWidget {
  const AddStopPage({Key? key}) : super(key: key);

  @override
  _AddStopPageState createState() => _AddStopPageState();
}

class _AddStopPageState extends State<AddStopPage> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  final TextEditingController _nameController = TextEditingController();
  final Location _locationController = Location();
  LatLng _initialPosition = const LatLng(41.0082, 28.9784); // İstanbul
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await _locationController.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _initialPosition = LatLng(locationData.latitude!, locationData.longitude!);
        });
      }
    } catch (e) {
      print('Konum alınamadı: $e');
    }
  }

  Future<void> _saveStop() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen haritadan bir nokta seçin')),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen durak için bir isim girin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await AuthService().getToken();
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/stops'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Durak başarıyla eklendi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Geri dön ve başarı durumunu bildir
        }
      } else {
        throw Exception('Durak eklenirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Durak Ekle'),
        actions: [
          if (_isLoading)
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
              icon: const Icon(Icons.check),
              onPressed: _saveStop,
              tooltip: 'Kaydet',
            ),
        ],
      ),
      body: Column(
        children: [
          // Durak ismi giriş alanı
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Durak İsmi',
                hintText: 'Örn: Evim, İş Yerim',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // Seçili konum bilgisi
          if (_selectedLocation != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seçili konum: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: Colors.blue.shade50,
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Haritadan durağınızı seçmek için bir noktaya dokunun',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Harita
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: (LatLng location) {
                setState(() {
                  _selectedLocation = location;
                });
              },
              markers: _selectedLocation != null
                  ? {
                      Marker(
                        markerId: const MarkerId('selected_stop'),
                        position: _selectedLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                        infoWindow: InfoWindow(
                          title: _nameController.text.isEmpty
                              ? 'Seçili Durak'
                              : _nameController.text,
                        ),
                      ),
                    }
                  : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
