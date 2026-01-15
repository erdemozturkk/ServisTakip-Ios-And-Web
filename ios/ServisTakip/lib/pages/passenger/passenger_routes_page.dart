import 'package:flutter/material.dart';
import 'package:servis_takip/models/daily_route_model.dart';
import 'package:servis_takip/services/route_service.dart';
import 'package:servis_takip/pages/map_page.dart';
import 'package:servis_takip/services/auth_service.dart';

class PassengerRoutesPage extends StatefulWidget {
  const PassengerRoutesPage({super.key});

  @override
  State<PassengerRoutesPage> createState() => _PassengerRoutesPageState();
}

class _PassengerRoutesPageState extends State<PassengerRoutesPage> {
  final RouteService _routeService = RouteService();
  final AuthService _authService = AuthService();
  List<DailyRouteModel> _routes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔵 Yolcu - Tüm aktif rotalar yükleniyor...');
      // TÜM aktif rotaları getir (yolcu herhangi birini takip edebilir)
      final routes = await _routeService.getAllActiveRoutes();
      print('✅ ${routes.length} rota yüklendi');
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Rota yükleme hatası: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rotalar yüklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktif Rotalar'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Bugün için aktif rota bulunamadı',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRoutes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _routes.length,
                    itemBuilder: (context, index) {
                      final route = _routes[index];
                      return _buildRouteCard(route);
                    },
                  ),
                ),
    );
  }

  Widget _buildRouteCard(DailyRouteModel route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapPage(route: route),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(route.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: _getStatusColor(route.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          route.vehiclePlate ?? 'Araç atanmamış',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(route.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(route.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Başlangıç: ${_formatTime(route.startTime)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    route.driverName ?? 'Şoför atanmamış',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  const Text(
                    'Haritada görüntülemek için tıklayın',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: // Beklemede
        return Colors.orange;
      case 1: // Başladı
        return Colors.green;
      case 2: // Tamamlandı
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'Beklemede';
      case 1:
        return 'Aktif';
      case 2:
        return 'Tamamlandı';
      default:
        return 'Bilinmiyor';
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Belirtilmemiş';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
