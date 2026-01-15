import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:servis_takip/models/reservation_model.dart';
import 'package:servis_takip/services/auth_service.dart';
import 'package:servis_takip/utils/constants.dart';

class ReservationService {
  final AuthService _authService = AuthService();

  // Kullanıcının rezervasyonlarını getir
  Future<List<ReservationModel>> getMyReservations({DateTime? startDate, DateTime? endDate}) async {
    try {
      String url = '${AppConstants.apiBaseUrl}/reservations/my';
      List<String> queryParams = [];
      
      if (startDate != null) {
        queryParams.add('startDate=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        queryParams.add('endDate=${endDate.toIso8601String()}');
      }
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ReservationModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Rezervasyonlar yüklenirken hata: $e');
      return [];
    }
  }

  // Rezervasyon oluştur
  Future<Map<String, dynamic>> createReservation({
    required String serviceId,
    required DateTime date,
    bool willAttend = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/reservations'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({
          'serviceId': serviceId,
          'date': date.toIso8601String(),
          'willAttend': willAttend,
        }),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'reservation': ReservationModel.fromJson(jsonDecode(response.body))
        };
      }
      return {'success': false, 'message': 'Rezervasyon oluşturulamadı'};
    } catch (e) {
      return {'success': false, 'message': 'Hata: $e'};
    }
  }

  // Rezervasyon güncelle (Servise binmeyeceğim)
  Future<bool> updateReservation(String reservationId, bool willAttend) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/reservations/$reservationId'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({
          'willAttend': willAttend,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Rezervasyon güncellenirken hata: $e');
      return false;
    }
  }

  // Rezervasyon iptal et
  Future<bool> cancelReservation(String reservationId, String reason) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/reservations/$reservationId'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({
          'reason': reason,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Rezervasyon iptal edilirken hata: $e');
      return false;
    }
  }

  // Haftalık rezervasyon oluştur
  Future<Map<String, dynamic>> createWeeklyReservations({
    required String serviceId,
    required DateTime startDate,
    required List<int> weekDays, // 1-7 (Pazartesi-Pazar)
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/reservations/weekly'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({
          'serviceId': serviceId,
          'startDate': startDate.toIso8601String(),
          'weekDays': weekDays,
        }),
      );

      if (response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'reservations': data.map((json) => ReservationModel.fromJson(json)).toList()
        };
      }
      return {'success': false, 'message': 'Haftalık rezervasyon oluşturulamadı'};
    } catch (e) {
      return {'success': false, 'message': 'Hata: $e'};
    }
  }
}
