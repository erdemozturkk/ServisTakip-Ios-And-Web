import 'dart:async';
import 'dart:math';
import 'package:location/location.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:servis_takip/utils/constants.dart';

class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  final Location _locationController = Location();
  
  HubConnection? _hubConnection;
  StreamSubscription<LocationData>? _locationSubscription;
  bool _isTracking = false;
  int? _userId; // Şoför userId'si
  
  // Hareketsizlik kontrolü için
  double? _lastLatitude;
  double? _lastLongitude;
  DateTime? _lastMovementTime;
  Timer? _movementCheckTimer;
  static const int _movementThresholdMeters = 10; // 10 metre hareket = hareketli
  static const int _stoppedThresholdSeconds = 60; // 1 dakika hareketsizlik

  bool get isTracking => _isTracking;

  // SignalR bağlantısını başlat
  Future<bool> initializeSignalR() async {
    try {
      final hubUrl = AppConstants.signalRHubUrl;
      print('🔵 SignalR bağlantısı kuruluyor: $hubUrl');

      _hubConnection = HubConnectionBuilder()
          .withUrl(hubUrl, options: HttpConnectionOptions(
            skipNegotiation: false,
            logMessageContent: true,
            requestTimeout: 30000, // 30 saniye timeout
          ))
          .withAutomaticReconnect()
          .build();

      _hubConnection?.onclose(({error}) {
        print('❌ SignalR bağlantısı kapandı: $error');
      });

      _hubConnection?.onreconnecting(({error}) {
        print('🔄 SignalR yeniden bağlanıyor...');
      });

      _hubConnection?.onreconnected(({connectionId}) {
        print('✅ SignalR yeniden bağlandı: $connectionId');
      });

      await _hubConnection?.start();
      print('✅ SignalR bağlantısı kuruldu');
      return true;
    } catch (e) {
      print('❌ SignalR bağlantı hatası: $e');
      return false;
    }
  }

  // Konum takibini başlat (Şoför için - userId ile)
  Future<bool> startTracking({required int userId}) async {
    if (_isTracking) {
      print('⚠️ Konum takibi zaten aktif');
      return true;
    }

    _userId = userId;

    // Konum iznini kontrol et
    bool serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) {
        print('❌ Konum servisi kapalı');
        return false;
      }
    }

    PermissionStatus permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
    }
    if (permissionGranted != PermissionStatus.granted) {
      print('❌ Konum izni verilmedi');
      return false;
    }

    // SignalR bağlantısını başlat
    if (_hubConnection == null || _hubConnection!.state != HubConnectionState.Connected) {
      final connected = await initializeSignalR();
      if (!connected) {
        print('❌ SignalR bağlantısı kurulamadı');
        return false;
      }
    }

    // Konum güncellemelerini dinle
    _locationSubscription = _locationController.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        _checkMovement(
          userId,
          currentLocation.latitude!,
          currentLocation.longitude!,
        );
      }
    });

    _isTracking = true;
    _lastMovementTime = DateTime.now();
    print('✅ Konum takibi başlatıldı (Şoför ID: $userId)');
    return true;
  }
  
  // Hareket kontrolü yap
  void _checkMovement(int userId, double latitude, double longitude) {
    bool hasMoved = false;
    
    if (_lastLatitude != null && _lastLongitude != null) {
      // Basit mesafe hesaplama (yaklaşık, metre cinsinden)
      final distance = _calculateDistance(
        _lastLatitude!, _lastLongitude!, 
        latitude, longitude
      );
      
      if (distance > _movementThresholdMeters) {
        hasMoved = true;
        _lastMovementTime = DateTime.now();
      }
    } else {
      // İlk konum
      _lastMovementTime = DateTime.now();
    }
    
    _lastLatitude = latitude;
    _lastLongitude = longitude;
    
    // Konum gönder (hareket durumu ile birlikte)
    _sendLocationUpdate(userId, latitude, longitude, hasMoved);
  }
  
  // İki nokta arası mesafe hesaplama (Haversine yaklaşık)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Dünya yarıçapı (metre)
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return R * c;
  }
  
  double _toRadians(double degrees) => degrees * pi / 180;

  // Konum güncellemesini SignalR ile gönder (userId ile - API aracı bulacak)
  Future<void> _sendLocationUpdate(int userId, double latitude, double longitude, bool isMoving) async {
    try {
      if (_hubConnection?.state == HubConnectionState.Connected) {
        // Hareketsizlik süresi kontrolü
        final now = DateTime.now();
        final secondsSinceMovement = _lastMovementTime != null 
            ? now.difference(_lastMovementTime!).inSeconds 
            : 0;
        
        final status = (isMoving || secondsSinceMovement < _stoppedThresholdSeconds) 
            ? 'moving' 
            : 'stopped';
        
        // YENİ: UpdateDriverLocation metodu - userId ile konum gönder
        await _hubConnection?.invoke('UpdateDriverLocation', args: [userId, latitude, longitude, status]);
        
        final statusEmoji = status == 'moving' ? '🚗' : '🛑';
        print('$statusEmoji Konum gönderildi: Şoför=$userId, Lat=$latitude, Lng=$longitude, Status=$status');
      } else {
        print('⚠️ SignalR bağlantısı yok, konum gönderilemedi');
      }
    } catch (e) {
      print('❌ Konum gönderme hatası: $e');
    }
  }

  // Konum takibini durdur
  Future<void> stopTracking() async {
    // SignalR ile araç offline olduğunu bildir
    if (_userId != null && _hubConnection?.state == HubConnectionState.Connected) {
      try {
        final userId = _userId!; // null-safety assertion
        // NOT: VehicleOffline için vehicleId gerekiyor, ama biz artık userId kullanıyoruz
        // Bu metodu çağırmayalım veya API'de userId kabul eden bir metod ekleyelim
        print('📴 Şoför offline durumuna alındı: $userId');
      } catch (e) {
        print('⚠️ Offline bildirimi hatası: $e');
      }
    }
    
    _movementCheckTimer?.cancel();
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _movementCheckTimer = null;
    _isTracking = false;
    _userId = null;
    _lastLatitude = null;
    _lastLongitude = null;
    _lastMovementTime = null;
    print('⏹️ Konum takibi durduruldu');
  }

  // SignalR bağlantısını kapat
  Future<void> closeConnection() async {
    await stopTracking();
    await _hubConnection?.stop();
    _hubConnection = null;
    print('🔴 SignalR bağlantısı kapatıldı');
  }

  // Rota durumu güncelle
  Future<void> updateRouteStatus(int routeId, int status) async {
    try {
      if (_hubConnection?.state == HubConnectionState.Connected) {
        await _hubConnection?.invoke('UpdateRouteStatus', args: [routeId, status]);
        print('🚦 Rota durumu güncellendi: Route=$routeId, Status=$status');
      }
    } catch (e) {
      print('❌ Rota durumu güncelleme hatası: $e');
    }
  }

  // Durak varışını bildir
  Future<void> notifyStopArrival(int routeId, int stopId) async {
    try {
      if (_hubConnection?.state == HubConnectionState.Connected) {
        await _hubConnection?.invoke('NotifyStopArrival', args: [routeId, stopId]);
        print('🏁 Durak varışı bildirildi: Route=$routeId, Stop=$stopId');
      }
    } catch (e) {
      print('❌ Durak varış bildirimi hatası: $e');
    }
  }
}
