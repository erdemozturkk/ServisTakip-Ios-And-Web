import 'package:flutter/material.dart';
import 'package:servis_takip/models/daily_route_model.dart';
import 'package:servis_takip/services/route_service.dart';
import 'package:servis_takip/services/auth_service.dart';
import 'package:servis_takip/pages/map_page.dart';

class DriverRoutesPage extends StatefulWidget {
  final Function(DailyRouteModel)? onRouteStarted;
  
  const DriverRoutesPage({super.key, this.onRouteStarted});

  @override
  State<DriverRoutesPage> createState() => _DriverRoutesPageState();
}

class _DriverRoutesPageState extends State<DriverRoutesPage> {
  final RouteService _routeService = RouteService();
  final AuthService _authService = AuthService();
  List<DailyRouteModel> _routes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      print('👤 Current User: ${user.name} (ID: ${user.id}, Role: ${user.role})');
      print('🔑 Token exists: ${_authService.authToken != null}');
      
      final routes = await _routeService.getDriverRoutes(int.parse(user.id));
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Load routes error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startRoute(DailyRouteModel route) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rotayı Başlat'),
        content: Text('${route.name} rotasını başlatmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Başlat'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _routeService.startRoute(route.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rota başlatıldı'),
              backgroundColor: Colors.green,
            ),
          );
          // Callback ile parent dashboard'a bildir
          widget.onRouteStarted?.call(route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rota başlatılamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _completeRoute(DailyRouteModel route) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rotayı Tamamla'),
        content: Text('${route.name} rotasını tamamlamak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tamamla'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _routeService.completeRoute(route.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rota tamamlandı'),
              backgroundColor: Colors.green,
            ),
          );
          _loadRoutes();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rota tamamlanamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 0:
        return Icons.schedule;
      case 1:
        return Icons.play_circle;
      case 2:
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotalarım'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadRoutes,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _routes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.route,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Henüz size atanmış rota bulunmuyor',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadRoutes,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Yenile'),
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
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          route.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(route.status)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getStatusIcon(route.status),
                                              size: 16,
                                              color:
                                                  _getStatusColor(route.status),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              route.statusText,
                                              style: TextStyle(
                                                color: _getStatusColor(
                                                    route.status),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    Icons.directions_car,
                                    'Araç',
                                    route.vehiclePlate ?? 'Atanmadı',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.calendar_today,
                                    'Tarih',
                                    route.formattedDate,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.access_time,
                                    'Başlangıç',
                                    route.formattedStartTime ?? 'Belirlenmedi',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.location_on,
                                    'Durak Sayısı',
                                    '${route.stopCount} durak',
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      if (route.status == 0) ...[
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _startRoute(route),
                                            icon: const Icon(Icons.play_arrow),
                                            label: const Text('Rotayı Başlat'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (route.status == 1) ...[
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _completeRoute(route),
                                            icon: const Icon(Icons.check),
                                            label: const Text('Rotayı Tamamla'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (route.status == 2) ...[
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.green.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.check_circle,
                                                    color: Colors.green),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Rota Tamamlandı',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
