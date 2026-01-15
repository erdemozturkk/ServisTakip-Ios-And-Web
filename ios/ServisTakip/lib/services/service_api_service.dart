import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:servis_takip/models/service_model.dart';
import 'package:servis_takip/models/route_model.dart';
import 'package:servis_takip/services/auth_service.dart';
import 'package:servis_takip/utils/constants.dart';

class ServiceApiService {
  final AuthService _authService = AuthService();

  // Günlük servisleri getir
  Future<List<ServiceModel>> getTodayServices() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/services/today'),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ServiceModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Servisler yüklenirken hata: $e');
      return [];
    }
  }

  // Kullanıcının servisini getir
  Future<ServiceModel?> getMyService(DateTime date) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/services/my?date=${date.toIso8601String()}'),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return ServiceModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Servis yüklenirken hata: $e');
      return null;
    }
  }

  // Servis rotasını getir
  Future<RouteModel?> getServiceRoute(String serviceId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/services/$serviceId/route'),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return RouteModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Rota yüklenirken hata: $e');
      return null;
    }
  }

  // Servis durumunu güncelle (Şoför)
  Future<bool> updateServiceStatus(String serviceId, ServiceStatus status) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/services/$serviceId/status'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({
          'status': status.toString().split('.').last,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Durum güncellenirken hata: $e');
      return false;
    }
  }

  // Durağı tamamla (Şoför)
  Future<bool> completeStop(String stopId) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/stops/$stopId/complete'),
        headers: _authService.getAuthHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Durak tamamlanırken hata: $e');
      return false;
    }
  }

  // Tüm servisleri getir (Yönetici)
  Future<List<ServiceModel>> getAllServices({DateTime? date}) async {
    try {
      String url = '${AppConstants.apiBaseUrl}/services';
      if (date != null) {
        url += '?date=${date.toIso8601String()}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ServiceModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Servisler yüklenirken hata: $e');
      return [];
    }
  }

  // Servis oluştur (Yönetici)
  Future<Map<String, dynamic>> createService(ServiceModel service) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/services'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode(service.toJson()),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'service': ServiceModel.fromJson(jsonDecode(response.body))
        };
      }
      return {'success': false, 'message': 'Servis oluşturulamadı'};
    } catch (e) {
      return {'success': false, 'message': 'Hata: $e'};
    }
  }
}
