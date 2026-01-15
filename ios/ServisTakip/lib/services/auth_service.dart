import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:servis_takip/utils/constants.dart';
import 'package:servis_takip/models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _authToken;
  UserModel? _currentUser;

  String? get authToken => _authToken;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _authToken != null && _currentUser != null;

  // Giriş yap - Gerçek API
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔵 LOGIN REQUEST: ${AppConstants.apiBaseUrl}/auth/login');
      print('📧 Email: $email');
      
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📨 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        print('✅ LOGIN SUCCESS - User ID: ${data['user']['id']}');
        print('👤 User Name: ${data['user']['name']}');
        print('📧 User Email: ${data['user']['email']}');
        print('🎭 User Role: ${data['user']['role']}');
        
        _authToken = data['token'];
        _currentUser = UserModel(
          id: data['user']['id'].toString(),
          name: data['user']['name'],
          email: data['user']['email'],
          phone: data['user']['phoneNumber'] ?? '',
          role: UserRole.values[data['user']['role']],
        );

        await _saveAuthData();
        
        return {'success': true, 'user': _currentUser};
      } else {
        if (response.body.isEmpty) {
          return {
            'success': false,
            'message': 'API boş yanıt döndü (Status: ${response.statusCode})',
          };
        }
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Giriş başarısız',
        };
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {
        'success': false,
        'message': 'Bağlantı hatası. API çalışıyor mu kontrol edin.\n$e',
      };
    }
  }

  // Kayıt ol - Gerçek API
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    try {
      print('🔵 REGISTER REQUEST: ${AppConstants.apiBaseUrl}/auth/register');
      print('👤 Name: $name, Email: $email, Phone: $phone');
      
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phoneNumber': phone,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📨 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        _authToken = data['token'];
        _currentUser = UserModel(
          id: data['user']['id'].toString(),
          name: data['user']['name'],
          email: data['user']['email'],
          phone: data['user']['phoneNumber'] ?? '',
          role: UserRole.values[data['user']['role']],
        );

        await _saveAuthData();
        
        return {'success': true, 'user': _currentUser};
      } else {
        if (response.body.isEmpty) {
          return {
            'success': false,
            'message': 'API boş yanıt döndü (Status: ${response.statusCode})',
          };
        }
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Kayıt başarısız',
        };
      }
    } catch (e) {
      print('❌ Register error: $e');
      return {
        'success': false,
        'message': 'Bağlantı hatası. API çalışıyor mu kontrol edin.\n$e',
      };
    }
  }

  // Çıkış yap
  Future<void> logout() async {
    _authToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Auth verilerini kaydet
  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAuthToken, _authToken ?? '');
    if (_currentUser != null) {
      await prefs.setString(AppConstants.keyUserId, _currentUser!.id);
      await prefs.setString('user_name', _currentUser!.name);
      await prefs.setString('user_email', _currentUser!.email);
      await prefs.setString('user_phone', _currentUser!.phone);
      await prefs.setInt(AppConstants.keyUserRole, _currentUser!.role.index);
    }
  }

  // Auth verilerini yükle (uygulama başlangıcında)
  Future<bool> loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(AppConstants.keyAuthToken);
    
    if (_authToken != null && _authToken!.isNotEmpty) {
      final userId = prefs.getString(AppConstants.keyUserId);
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      final userPhone = prefs.getString('user_phone');
      final userRole = prefs.getInt(AppConstants.keyUserRole);

      if (userId != null && userName != null && userEmail != null && userRole != null) {
        _currentUser = UserModel(
          id: userId,
          name: userName,
          email: userEmail,
          phone: userPhone ?? '',
          role: UserRole.values[userRole],
        );
        return true;
      }
    }
    
    return false;
  }

  // HTTP istekleri için header
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_authToken',
    };
  }

  // Token'ı döndür
  Future<String?> getToken() async {
    if (_authToken != null && _authToken!.isNotEmpty) {
      return _authToken;
    }
    
    // Token yoksa shared preferences'tan yükle
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(AppConstants.keyAuthToken);
    return _authToken;
  }
}
