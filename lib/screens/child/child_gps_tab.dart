import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/pairing_service.dart';
import '../../widgets/custom_button.dart';

class ChildGpsTab extends StatefulWidget {
  const ChildGpsTab({super.key});

  @override
  State<ChildGpsTab> createState() => _ChildGpsTabState();
}

class _ChildGpsTabState extends State<ChildGpsTab> {
  final MapController _mapController = MapController();

  double _currentLat = 10.7769;
  double _currentLng = 106.7009;
  DateTime? _lastReportedTime;
  bool _isAutoSharing = false;
  Timer? _autoShareTimer;
  bool _isSending = false;
  String _statusMessage = 'Sẵn sàng chia sẻ vị trí GPS';
  bool _isAlertTriggered = false;
  String _deviceId = '';

  @override
  void initState() {
    super.initState();
    _initDeviceAndLocation();
  }

  @override
  void dispose() {
    _autoShareTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDeviceAndLocation() async {
    // 1. Lấy device session nếu đã ghép nối thiết bị hoặc từ profile
    await _resolveDeviceId();

    // 2. Lấy vị trí thực tế
    await _fetchCurrentGpsPosition();

    // 3. Gửi vị trí lần đầu nếu có deviceId
    if (_deviceId.isNotEmpty) {
      _sendLocation();
    }
  }

  Future<void> _resolveDeviceId() async {
    final session = await PairingService.getChildDeviceSession();
    final sessionDeviceId = session['deviceId'] ?? '';
    if (sessionDeviceId.isNotEmpty) {
      _deviceId = sessionDeviceId;
      return;
    }

    try {
      final profile = await AuthService.getProfile();
      final devices = (profile.childProfile?['devices'] as List?) ?? [];
      if (devices.isNotEmpty) {
        _deviceId = devices.first['id'] ?? '';
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrentGpsPosition() async {
    try {
      final pos = await LocationService.getCurrentDevicePosition();
      if (pos != null && mounted) {
        setState(() {
          _currentLat = pos.latitude;
          _currentLng = pos.longitude;
        });
        try {
          _mapController.move(LatLng(_currentLat, _currentLng), 15.0);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _sendLocation({bool forceFetchGps = false}) async {
    if (_deviceId.isEmpty) {
      await _resolveDeviceId();
    }

    if (_deviceId.isEmpty) {
      setState(() {
        _statusMessage = 'Chưa có ID thiết bị liên kết để đồng bộ GPS. Hãy kiểm tra liên kết phụ huynh ở Trang chủ.';
      });
      return;
    }

    setState(() => _isSending = true);

    try {
      if (forceFetchGps) {
        await _fetchCurrentGpsPosition();
      }

      final res = await LocationService.reportLocation(
        deviceId: _deviceId,
        latitude: _currentLat,
        longitude: _currentLng,
        accuracy: 10,
        speed: 0,
      );

      final alertTriggered = res['alertTriggered'] == true;

      if (mounted) {
        setState(() {
          _lastReportedTime = DateTime.now();
          _isAlertTriggered = alertTriggered;
          if (alertTriggered) {
            _statusMessage = '⚠️ Cảnh báo: Vị trí hiện tại đang nằm ngoài Vùng an toàn!';
          } else {
            _statusMessage = '✓ Đã cập nhật vị trí lên máy chủ thành công!';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_statusMessage),
            backgroundColor: alertTriggered ? Colors.orange : Colors.teal,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Lỗi gửi vị trí: ${e.toString().replaceAll('Exception: ', '')}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_statusMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _toggleAutoShare(bool enable) {
    setState(() => _isAutoSharing = enable);
    _autoShareTimer?.cancel();
    if (enable) {
      _sendLocation(forceFetchGps: true);
      _autoShareTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        _sendLocation(forceFetchGps: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final latLng = LatLng(_currentLat, _currentLng);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thẻ trạng thái GPS
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.gps_fixed, color: Colors.teal),
                            SizedBox(width: 8),
                            Text(
                              'Trạng thái GPS của con',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Text(
                            'Sẵn sàng / Đang bật',
                            style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vĩ độ (Lat): ${_currentLat.toStringAsFixed(6)}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kinh độ (Lng): ${_currentLng.toStringAsFixed(6)}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (_lastReportedTime != null)
                          Text(
                            'Cập nhật: ${_lastReportedTime!.hour.toString().padLeft(2, '0')}:${_lastReportedTime!.minute.toString().padLeft(2, '0')}:${_lastReportedTime!.second.toString().padLeft(2, '0')}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bản đồ thực tế OpenStreetMap
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: latLng,
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.qltreem',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: latLng,
                            width: 60,
                            height: 60,
                            child: const Column(
                              children: [
                                Icon(Icons.location_on, color: Colors.red, size: 38),
                                Text(
                                  'Con đang ở đây',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    backgroundColor: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FloatingActionButton.small(
                      heroTag: 'recenter_gps',
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal,
                      onPressed: () {
                        _fetchCurrentGpsPosition();
                        _mapController.move(LatLng(_currentLat, _currentLng), 15.0);
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Banner trạng thái
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isAlertTriggered ? Colors.red.shade50 : Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isAlertTriggered ? Colors.red.shade200 : Colors.teal.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isAlertTriggered ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: _isAlertTriggered ? Colors.red : Colors.teal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _isAlertTriggered ? Colors.red.shade800 : Colors.teal.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tự động gửi vị trí Toggle
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                title: const Text('Tự động chia sẻ vị trí (mỗi 25s)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Đồng bộ tọa độ định kỳ với ứng dụng của Phụ huynh', style: TextStyle(fontSize: 12)),
                value: _isAutoSharing,
                // ignore: deprecated_member_use
                activeColor: Colors.teal,
                onChanged: _toggleAutoShare,
              ),
            ),
            const SizedBox(height: 12),

            // Nút gửi vị trí thủ công
            CustomButton(
              text: 'Gửi vị trí GPS ngay',
              backgroundColor: Colors.teal,
              isLoading: _isSending,
              icon: Icons.send_rounded,
              onPressed: () => _sendLocation(forceFetchGps: true),
            ),
            const SizedBox(height: 16),

            // Mô phỏng tọa độ dành cho Demo đồ án
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.science_outlined, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Mô phỏng vị trí (Dành cho Demo)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.green),
                          ),
                          onPressed: () {
                            setState(() {
                              _currentLat = 10.7769; // Trong trường
                              _currentLng = 106.7009;
                            });
                            _mapController.move(LatLng(10.7769, 106.7009), 15.0);
                            _sendLocation();
                          },
                          child: const Text('Ở trong trường', style: TextStyle(color: Colors.green, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.red),
                          ),
                          onPressed: () {
                            setState(() {
                              _currentLat = 10.7500; // Ra ngoài ~3km
                              _currentLng = 106.6800;
                            });
                            _mapController.move(LatLng(10.7500, 106.6800), 15.0);
                            _sendLocation();
                          },
                          child: const Text('Ra ngoài 3km', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
