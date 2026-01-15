import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:servis_takip/models/notification_model.dart';
import 'package:servis_takip/services/auth_service.dart';
import 'package:servis_takip/utils/constants.dart';

class NotificationService {
  final AuthService _authService = AuthService();

  // Bildirimleri getir
  Future<List<NotificationModel>> getNotifications({bool? isRead}) async {
    try {
      String url = '${AppConstants.apiBaseUrl}/notifications';
      if (isRead != null) {
        url += '?isRead=$isRead';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Bildirimler yüklenirken hata: $e');
      return [];
    }
  }

  // Bildirimi okundu olarak işaretle
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/notifications/$notificationId/read'),
        headers: _authService.getAuthHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Bildirim güncellenirken hata: $e');
      return false;
    }
  }

  // Tüm bildirimleri okundu olarak işaretle
  Future<bool> markAllAsRead() async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/notifications/read-all'),
        headers: _authService.getAuthHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Bildirimler güncellenirken hata: $e');
      return false;
    }
  }

  // Okunmamış bildirim sayısı
  Future<int> getUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/notifications/unread-count'),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Okunmamış bildirim sayısı alınırken hata: $e');
      return 0;
    }
  }

  // Bildirim sil
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/notifications/$notificationId'),
        headers: _authService.getAuthHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Bildirim silinirken hata: $e');
      return false;
    }
  }
}
