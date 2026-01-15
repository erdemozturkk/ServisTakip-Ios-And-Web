import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:servis_takip/utils/constants.dart';
import 'package:servis_takip/services/auth_service.dart';
import 'package:servis_takip/pages/add_stop_page.dart';

class MyStopsPage extends StatefulWidget {
  const MyStopsPage({Key? key}) : super(key: key);

  @override
  _MyStopsPageState createState() => _MyStopsPageState();
}

class _MyStopsPageState extends State<MyStopsPage> {
  List<dynamic> _stops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  Future<void> _loadStops() async {
    setState(() => _isLoading = true);

    try {
      final token = await AuthService().getToken();
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/stops/my'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _stops = data;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Duraklar yüklenirken hata: ${response.statusCode}');
      }
    } catch (e) {
      print('Hata: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Duraklar yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _deleteStop(int stopId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durağı Sil'),
        content: const Text('Bu durağı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await AuthService().getToken();
      final response = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/stops/$stopId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Durak silindi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadStops(); // Listeyi yenile
        }
      } else {
        throw Exception('Durak silinirken hata: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Hata: $e')),
        );
      }
    }
  }

  Future<void> _addNewStop() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddStopPage()),
    );

    if (result == true) {
      _loadStops(); // Yeni durak eklendiyse listeyi yenile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duraklarım'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stops.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz durak eklememişsiniz',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addNewStop,
                        icon: const Icon(Icons.add),
                        label: const Text('Durak Ekle'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStops,
                  child: ListView.builder(
                    itemCount: _stops.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final stop = _stops[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.blue,
                            ),
                          ),
                          title: Text(
                            stop['name'] ?? 'İsimsiz Durak',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Lat: ${stop['latitude'].toStringAsFixed(6)}\n'
                            'Lng: ${stop['longitude'].toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteStop(stop['id']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _stops.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addNewStop,
              child: const Icon(Icons.add),
              tooltip: 'Yeni Durak Ekle',
            )
          : null,
    );
  }
}
