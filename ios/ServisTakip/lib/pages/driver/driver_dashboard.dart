import 'package:flutter/material.dart';
import 'package:servis_takip/services/auth_service.dart';
import 'package:servis_takip/services/location_tracking_service.dart';
import 'package:servis_takip/pages/auth/login_page.dart';
import 'package:servis_takip/pages/map_page.dart';
import 'package:servis_takip/pages/driver/driver_routes_page.dart';
import 'package:servis_takip/models/daily_route_model.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final AuthService _authService = AuthService();
  final LocationTrackingService _locationService = LocationTrackingService();
  int _selectedIndex = 0;
  bool _isTrackingActive = false;
  DailyRouteModel? _activeRoute;

  Future<void> _handleLogout() async {
    // Konum takibini durdur
    if (_isTrackingActive) {
      await _locationService.stopTracking();
    }
    
    await _authService.logout();
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    // Sayfa kapanırken konum takibini durdur
    if (_isTrackingActive) {
      _locationService.stopTracking();
    }
    super.dispose();
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildRoutePage();
      case 2:
        return MapPage(route: _activeRoute);
      case 3:
        return _buildProfilePage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    final user = _authService.currentUser;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_shipping, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              'Hoş Geldiniz, ${user?.name ?? "Şoför"}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Şoför Dashboard',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            
            // Konum Takibi Kartı
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      _isTrackingActive ? Icons.gps_fixed : Icons.gps_off,
                      size: 48,
                      color: _isTrackingActive ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isTrackingActive ? 'Konum Takibi Aktif' : 'Konum Takibi Kapalı',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isTrackingActive 
                          ? 'Konumunuz canlı haritada görüntüleniyor'
                          : 'Servise başlamak için konum takibini açın',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggleLocationTracking,
                        icon: Icon(_isTrackingActive ? Icons.stop : Icons.play_arrow),
                        label: Text(
                          _isTrackingActive ? 'Takibi Durdur' : 'Takibi Başlat',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTrackingActive ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLocationTracking() async {
    if (_isTrackingActive) {
      // Takibi durdur
      await _locationService.stopTracking();
      setState(() {
        _isTrackingActive = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konum takibi durduruldu'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Takibi başlat - Giriş yapmış şoförün userId'sini kullan
      final user = _authService.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı bilgisi alınamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final success = await _locationService.startTracking(userId: int.parse(user.id));
      
      if (success) {
        setState(() {
          _isTrackingActive = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum takibi başlatıldı'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum takibi başlatılamadı. İzinleri kontrol edin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildRoutePage() {
    return DriverRoutesPage(
      onRouteStarted: (route) {
        setState(() {
          _activeRoute = route;
          _selectedIndex = 2; // Harita sekmesine geç
        });
      },
    );
  }

  Widget _buildProfilePage() {
    final user = _authService.currentUser;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              user?.name ?? 'Şoför',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ayarlar'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Ayarlar sayfası - yakında
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şoför Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Rotalarım',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Harita',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
