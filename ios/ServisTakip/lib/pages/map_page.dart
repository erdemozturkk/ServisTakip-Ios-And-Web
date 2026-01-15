import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:servis_takip/models/daily_route_model.dart';
import 'package:servis_takip/models/route_stop_model.dart';
import 'package:servis_takip/services/route_service.dart';
import 'package:servis_takip/services/passenger_location_service.dart';
import 'package:servis_takip/utils/constants.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapPage extends StatefulWidget {
  final DailyRouteModel? route;
  
  const MapPage({super.key, this.route});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Location _locationController = Location();
  final RouteService _routeService = RouteService();
  final PassengerLocationService _passengerLocationService = PassengerLocationService();
  GoogleMapController? _mapController;

  static const LatLng _ankaraCenter = LatLng(39.9334, 32.8597);
  LatLng? _currentPosition;
  LatLng? _driverPosition; // Şoför konumu
  final double _panelMinHeight = 120.0;
  final double _panelMaxHeight = 450.0;
  
  List<RouteStopModel> _routeStops = [];
  bool _isLoadingStops = false;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final Map<int, BitmapDescriptor> _markerIconCache = {};
  StreamSubscription<DriverLocationUpdate>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    getLocationUpdate();
    if (widget.route != null) {
      _loadRouteStops();
      _connectToLocationHub();
    }
  }

  // SignalR ile şoför konumunu dinle
  Future<void> _connectToLocationHub() async {
    if (widget.route == null) return;
    
    final connected = await _passengerLocationService.connectToLocationHub(
      routeId: widget.route!.id,
    );
    
    if (connected) {
      // Rota grubuna katıl
      await _passengerLocationService.joinRouteGroup(widget.route!.id);
      
      // Konum güncellemelerini dinle
      _locationSubscription = _passengerLocationService.locationStream.listen(
        (update) {
          print('📍 Şoför konumu güncellendi: ${update.latitude}, ${update.longitude}');
          setState(() {
            _driverPosition = LatLng(update.latitude, update.longitude);
            _updateMarkersAndPolylines();
          });
        },
        onError: (error) {
          print('❌ Konum akışı hatası: $error');
        },
      );
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    if (widget.route != null) {
      _passengerLocationService.leaveRouteGroup(widget.route!.id);
    }
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadRouteStops() async {
    if (widget.route == null) return;
    
    setState(() {
      _isLoadingStops = true;
    });

    try {
      final stops = await _routeService.getRouteStops(widget.route!.id);
      setState(() {
        _routeStops = stops;
        _isLoadingStops = false;
        _updateMarkersAndPolylines();
      });
      
      // İlk durağa kamerayı odakla
      if (_routeStops.isNotEmpty) {
        _fitMapToBounds();
      }
    } catch (e) {
      setState(() {
        _isLoadingStops = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duraklar yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateMarkersAndPolylines() async {
    Set<Marker> markers = {};

    // Durak marker'larını ekle
    for (int i = 0; i < _routeStops.length; i++) {
      final stop = _routeStops[i];
      final position = LatLng(stop.latitude, stop.longitude);
      
      // Numaralı marker icon oluştur
      final markerIcon = await _getMarkerIcon(
        i + 1,
        stop.isCompleted ? Colors.green : 
        stop.isArrived ? Colors.orange :
        Colors.red,
      );

      markers.add(
        Marker(
          markerId: MarkerId('stop_${stop.id}'),
          position: position,
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: '${i + 1}. ${stop.stopName}',
            snippet: stop.statusText,
          ),
        ),
      );
    }

    // Şoför konumu marker'ı (araç ikonu)
    if (_driverPosition != null) {
      final carIcon = await _getCarIcon();
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverPosition!,
          icon: carIcon,
          anchor: const Offset(0.5, 0.5),
          infoWindow: const InfoWindow(
            title: '🚌 Servis Aracı',
            snippet: 'Anlık konum',
          ),
        ),
      );
    }

    // Mevcut konum marker'ı
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
          infoWindow: const InfoWindow(
            title: 'Konumunuz',
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });

    // Directions API ile gerçek yolu çiz
    if (_routeStops.length > 1) {
      await _drawRouteWithDirections();
    }
  }

  // Araç ikonu oluştur
  Future<BitmapDescriptor> _getCarIcon() async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const double size = 140.0;
    const double radius = size / 2;

    // Mavi daire
    final circlePaint = Paint()..color = Colors.blue;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius,
      circlePaint,
    );

    // Beyaz kenarlık
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 5,
      borderPaint,
    );

    // Araç emoji
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '🚌',
        style: TextStyle(
          fontSize: 70,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<void> _drawRouteWithDirections() async {
    try {
      if (_routeStops.length < 2) return;

      // Origin ve destination
      final origin = '${_routeStops.first.latitude},${_routeStops.first.longitude}';
      final destination = '${_routeStops.last.latitude},${_routeStops.last.longitude}';
      
      // Waypoints (ara duraklar)
      List<String> waypoints = [];
      for (int i = 1; i < _routeStops.length - 1; i++) {
        waypoints.add('${_routeStops[i].latitude},${_routeStops[i].longitude}');
      }
      
      final waypointsStr = waypoints.isNotEmpty ? waypoints.join('|') : '';

      // Directions API çağrısı
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=$origin'
        '&destination=$destination'
        '${waypointsStr.isNotEmpty ? '&waypoints=$waypointsStr' : ''}'
        '&key=${AppConstants.googleMapsApiKey}'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = route['overview_polyline']['points'];
          
          // Polyline decode et
          PolylinePoints polylinePointsDecoder = PolylinePoints();
          List<PointLatLng> decodedPoints = polylinePointsDecoder.decodePolyline(polylinePoints);
          
          List<LatLng> polylineCoordinates = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylineCoordinates,
                color: Colors.blue,
                width: 5,
              ),
            };
          });
        } else {
          print('Directions API hatası: ${data['status']}');
          _drawSimplePolyline(); // Hata durumunda basit çizgi çiz
        }
      } else {
        print('HTTP hatası: ${response.statusCode}');
        _drawSimplePolyline();
      }
    } catch (e) {
      print('Directions API çağrı hatası: $e');
      _drawSimplePolyline();
    }
  }

  void _drawSimplePolyline() {
    // Basit polyline (durakları düz çizgilerle birleştir)
    List<LatLng> polylineCoordinates = _routeStops
        .map((stop) => LatLng(stop.latitude, stop.longitude))
        .toList();

    if (polylineCoordinates.length > 1) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        };
      });
    }
  }

  Future<BitmapDescriptor> _getMarkerIcon(int number, Color color) async {
    // Cache kontrolü
    final cacheKey = number * 1000 + color.value;
    if (_markerIconCache.containsKey(cacheKey)) {
      return _markerIconCache[cacheKey]!;
    }

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;
    const double size = 120.0;
    const double radius = size / 2;

    // Daire çiz
    canvas.drawCircle(
      const Offset(radius, radius),
      radius,
      paint,
    );

    // Beyaz kenarlık
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 4,
      borderPaint,
    );

    // Numara yaz
    final textPainter = TextPainter(
      text: TextSpan(
        text: number.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 60,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final icon = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    
    // Cache'e kaydet
    _markerIconCache[cacheKey] = icon;
    
    return icon;
  }

  void _fitMapToBounds() {
    if (_routeStops.isEmpty) return;

    double minLat = _routeStops.first.latitude;
    double maxLat = _routeStops.first.latitude;
    double minLng = _routeStops.first.longitude;
    double maxLng = _routeStops.first.longitude;

    for (var stop in _routeStops) {
      if (stop.latitude < minLat) minLat = stop.latitude;
      if (stop.latitude > maxLat) maxLat = stop.latitude;
      if (stop.longitude < minLng) minLng = stop.longitude;
      if (stop.longitude > maxLng) maxLng = stop.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.01, minLng - 0.01),
          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
        ),
        50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.route != null ? AppBar(
        title: Text(widget.route!.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ) : null,
      body: SafeArea(
        child: SlidingUpPanel(
          minHeight: _panelMinHeight,
          maxHeight: _panelMaxHeight,
          panel: _buildPanel(),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
          body: GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              print('🗺️ Google Maps yüklendi!');
              if (_routeStops.isNotEmpty) {
                _fitMapToBounds();
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            padding: EdgeInsets.only(bottom: _panelMinHeight),
            initialCameraPosition: CameraPosition(
              target: _routeStops.isNotEmpty 
                ? LatLng(_routeStops.first.latitude, _routeStops.first.longitude)
                : _ankaraCenter,
              zoom: 13.0,
            ),
            markers: _markers,
            polylines: _polylines,
            circles: {
              if (_currentPosition != null)
                Circle(
                  circleId: const CircleId('currentLocationRadius'),
                  center: _currentPosition!,
                  radius: 50,
                  fillColor: Colors.blue.withValues(alpha: 0.1),
                  strokeColor: Colors.blue.withValues(alpha: 0.3),
                  strokeWidth: 2,
                ),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    if (widget.route == null) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
        ),
        child: const Center(
          child: Text(
            'Harita görünümü',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Kaydırma çubuğu
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.route!.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.route!.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.route!.statusText,
              style: TextStyle(
                color: _getStatusColor(widget.route!.status),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingStops
                ? const Center(child: CircularProgressIndicator())
                : _routeStops.isEmpty
                    ? const Center(
                        child: Text('Bu rotada durak bulunmuyor'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _routeStops.length,
                        itemBuilder: (context, index) {
                          final stop = _routeStops[index];
                          return _buildStopCard(stop, index + 1);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStopCard(RouteStopModel stop, int index) {
    Color statusColor = stop.isCompleted
        ? Colors.green
        : stop.isArrived
            ? Colors.orange
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.stopName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stop.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              stop.isCompleted
                  ? Icons.check_circle
                  : stop.isArrived
                      ? Icons.location_on
                      : Icons.radio_button_unchecked,
              color: statusColor,
            ),
          ],
        ),
      ),
    );
  }
  Future<void> getLocationUpdate() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    print('📍 Konum servisi kontrol ediliyor...');
    serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) {
        print('❌ Konum servisi kapalı');
        return;
      }
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
    }
    if (permissionGranted != PermissionStatus.granted) {
      print('❌ Konum izni verilmedi');
      return;
    }
    print('✅ Konum izni alındı');

    _locationController.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        final lat = currentLocation.latitude!;
        final lng = currentLocation.longitude!;
        print('📍 Konum güncellendi: $lat, $lng');
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(lat, lng);
          });
          _updateMarkersAndPolylines();
        }
      }
    });
  }
}