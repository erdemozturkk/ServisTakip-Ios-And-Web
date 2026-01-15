import 'package:flutter/material.dart';
import 'package:servis_takip/services/auth_service.dart';
import 'package:servis_takip/pages/auth/login_page.dart';
import 'package:servis_takip/pages/map_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardPage();
      case 1:
        return const MapPage();
      case 2:
        return _buildUsersPage();
      case 3:
        return _buildVehiclesPage();
      default:
        return _buildDashboardPage();
    }
  }

  Widget _buildDashboardPage() {
    final user = _authService.currentUser;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.admin_panel_settings, size: 80, color: Colors.red),
          const SizedBox(height: 24),
          Text(
            'Hoş Geldiniz, ${user?.name ?? "Yönetici"}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Yönetici Dashboard',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersPage() {
    return const Center(
      child: Text('Kullanıcılar Sayfası - Yakında',
          style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildVehiclesPage() {
    return const Center(
      child: Text('Araçlar Sayfası - Yakında',
          style: TextStyle(fontSize: 18)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetici Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Harita',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Kullanıcılar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Araçlar',
          ),
        ],
      ),
    );
  }
}
