import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:servis_takip/utils/constants.dart';

class PassengerLocationService {
  static final PassengerLocationService _instance = PassengerLocationService._internal();
  factory PassengerLocationService() => _instance;
  PassengerLocationService._internal();

  HubConnection? _hubConnection;
  bool _isConnected = false;
  
  // Konum güncellemeleri için stream controller
  final StreamController<DriverLocationUpdate> _locationStreamController = 
      StreamController<DriverLocationUpdate>.broadcast();
  
  Stream<DriverLocationUpdate> get locationStream => _locationStreamController.stream;
  
  bool get isConnected => _isConnected;

  // SignalR bağlantısını başlat ve şoför konumlarını dinle
  Future<bool> connectToLocationHub({int? vehicleId, int? routeId}) async {
    try {
      final hubUrl = AppConstants.signalRHubUrl;
      print('🔵 Yolcu - SignalR bağlantısı kuruluyor: $hubUrl');

      _hubConnection = HubConnectionBuilder()
          .withUrl(hubUrl, options: HttpConnectionOptions(
            skipNegotiation: false,
            logMessageContent: true,
            requestTimeout: 30000,
          ))
          .withAutomaticReconnect()
          .build();

      // Şoför konum güncellemelerini dinle
      _hubConnection?.on('ReceiveLocationUpdate', _handleLocationUpdate);

      _hubConnection?.onclose(({error}) {
        print('❌ Yolcu - SignalR bağlantısı kapandı: $error');
        _isConnected = false;
      });

      _hubConnection?.onreconnecting(({error}) {
        print('🔄 Yolcu - SignalR yeniden bağlanıyor...');
        _isConnected = false;
      });

      _hubConnection?.onreconnected(({connectionId}) {
        print('✅ Yolcu - SignalR yeniden bağlandı: $connectionId');
        _isConnected = true;
        // Yeniden bağlandıktan sonra gruba katıl
        if (vehicleId != null) {
          joinVehicleGroup(vehicleId);
        }
        if (routeId != null) {
          joinRouteGroup(routeId);
        }
      });

      await _hubConnection?.start();
      _isConnected = true;
      print('✅ Yolcu - SignalR bağlantısı kuruldu');
      
      return true;
    } catch (e) {
      print('❌ Yolcu - SignalR bağlantı hatası: $e');
      _isConnected = false;
      return false;
    }
  }

  // Konum güncellemelerini işle
  void _handleLocationUpdate(List<Object?>? arguments) {
    try {
      if (arguments == null || arguments.isEmpty) return;
      
      final data = arguments[0] as Map<String, dynamic>;
      print('📍 Yolcu - Konum güncellemesi alındı: $data');
      
      final update = DriverLocationUpdate(
        vehicleId: data['vehicleId'] as int,
        latitude: (data['latitude'] as num).toDouble(),
        longitude: (data['longitude'] as num).toDouble(),
        status: data['status'] as String? ?? 'moving',
        timestamp: DateTime.parse(data['timestamp'] as String),
      );
      
      _locationStreamController.add(update);
    } catch (e) {
      print('❌ Konum güncellemesi işlenemedi: $e');
    }
  }

  // Belirli bir aracın konumunu takip et
  Future<void> joinVehicleGroup(int vehicleId) async {
    try {
      if (_hubConnection?.state == HubConnectionState.Connected) {
        await _hubConnection?.invoke('JoinVehicleGroup', args: [vehicleId]);
        print('✅ Araç grubuna katıldı: Vehicle $vehicleId');
      }
    } catch (e) {
      print('❌ Araç grubuna katılma hatası: $e');
    }
  }

  // Belirli bir rotayı takip et
  Future<void> joinRouteGroup(int routeId) async {
    try {
      if (_hubConnection?.state == HubConnectionState.Connected) {
        await _hubConnection?.invoke('JoinRouteGroup', args: [routeId]);
        print('✅ Rota grubuna katıldı: Route $routeId');
      }
    } catch (e) {
      print('❌ Rota grubuna katılma hatası: $e');
    }
  }

  // Araç grubundan ayrıl
  Future<void> leaveVehicleGroup(int vehicleId) async {
    try {
      if (_hubConnection?.state == HubConnectionState.Connected) {
        await _hubConnection?.invoke('LeaveVehicleGroup', args: [vehicleId]);
        print('🚪 Araç grubundan ayrıldı: Vehicle $vehicleId');
      }
    } catch (e) {
      print('❌ Araç grubundan ayrılma hatası: $e');
    }
  }

  // Rota grubundan ayrıl
  Future<void> leaveRouteGroup(int routeId) async {
    try {
      if (_hubConnection?.state == HubConnectionState.Connected) {
        await _hubConnection?.invoke('LeaveRouteGroup', args: [routeId]);
        print('🚪 Rota grubundan ayrıldı: Route $routeId');
      }
    } catch (e) {
      print('❌ Rota grubundan ayrılma hatası: $e');
    }
  }

  // Bağlantıyı kapat
  Future<void> disconnect() async {
    try {
      await _hubConnection?.stop();
      _isConnected = false;
      print('🔴 Yolcu - SignalR bağlantısı kapatıldı');
    } catch (e) {
      print('❌ Bağlantı kapatma hatası: $e');
    }
  }

  // Temizle
  void dispose() {
    disconnect();
    _locationStreamController.close();
  }
}

// Şoför konum güncellemesi modeli
class DriverLocationUpdate {
  final int vehicleId;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime timestamp;

  DriverLocationUpdate({
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.timestamp,
  });
}
