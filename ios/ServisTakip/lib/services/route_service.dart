import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:servis_takip/utils/constants.dart';
import 'package:servis_takip/models/daily_route_model.dart';
import 'package:servis_takip/models/route_stop_model.dart';
import 'package:servis_takip/services/auth_service.dart';

class RouteService {
  final AuthService _authService = AuthService();

  Future<List<DailyRouteModel>> getDriverRoutes(int driverId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      print('🔵 GET DRIVER ROUTES: ${AppConstants.apiBaseUrl}/routes/driver/$driverId');
      print('🔑 Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/routes/driver/$driverId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📨 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DailyRouteModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Yetkilendirme hatası. Lütfen tekrar giriş yapın.');
      } else {
        throw Exception('Rotalar yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Rota yükleme hatası: $e');
      rethrow;
    }
  }

  Future<bool> startRoute(int routeId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/routes/$routeId/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Rota başlatma hatası: $e');
      return false;
    }
  }

  Future<bool> completeRoute(int routeId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/routes/$routeId/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Rota tamamlama hatası: $e');
      return false;
    }
  }

  Future<List<RouteStopModel>> getRouteStops(int routeId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/routes/$routeId/stops'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => RouteStopModel.fromJson(json)).toList();
      } else {
        throw Exception('Duraklar yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('Durak yükleme hatası: $e');
      rethrow;
    }
  }

  // Tüm aktif rotaları getir (Yolcular için)
  Future<List<DailyRouteModel>> getAllActiveRoutes() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      print('🔵 GET ACTIVE ROUTES: ${AppConstants.apiBaseUrl}/routes/active');
      print('🔑 Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/routes/active'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📨 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ ${data.length} aktif rota bulundu');
        return data.map((json) => DailyRouteModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Yetkilendirme hatası. Lütfen tekrar giriş yapın.');
      } else {
        throw Exception('Aktif rotalar yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Aktif rota yükleme hatası: $e');
      rethrow;
    }
  }

  // Yolcunun rezervasyon yaptığı rotaları getir
  Future<List<DailyRouteModel>> getPassengerRoutes(int passengerId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      print('🔵 GET PASSENGER ROUTES: ${AppConstants.apiBaseUrl}/routes/passenger/$passengerId');
      print('🔑 Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/routes/passenger/$passengerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📨 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ ${data.length} yolcu rotası bulundu');
        return data.map((json) => DailyRouteModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Yetkilendirme hatası. Lütfen tekrar giriş yapın.');
      } else {
        throw Exception('Yolcu rotaları yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Yolcu rotası yükleme hatası: $e');
      rethrow;
    }
  }
}
