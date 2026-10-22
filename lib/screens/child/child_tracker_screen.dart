import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/location_service.dart';
import '../../services/pairing_service.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';

class ChildTrackerScreen extends StatefulWidget {
  const ChildTrackerScreen({super.key});

  @override
  State<ChildTrackerScreen> createState() => _ChildTrackerScreenState();
}

class _ChildTrackerScreenState extends State<ChildTrackerScreen> {
  String _deviceId = '';
  String _childName = '';
  bool _isAutoSharing = false;
  Timer? _autoShareTimer;

  double _currentLat = 10.7769;
  double _currentLng = 106.7009;
  DateTime? _lastReportedTime;
  bool _isSending = false;
  String _statusMessage = 'Sẵn sàng chia sẻ vị trí';
  bool _lastAlertTriggered = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceSession();
  }

  @override
  void dispose() {
    _autoShareTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeviceSession() async {
    final session = await PairingService.getChildDeviceSession();
    setState(() {
      _deviceId = session['deviceId'] ?? '';
      _childName = session['childName'] ?? 'Bé';
    });
    // Gửi vị trí lần đầu
    if (_deviceId.isNotEmpty) {
      _sendLocation();
    }
  }

  Future<void> _sendLocation() async {
    if (_deviceId.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Thử lấy tọa độ GPS thực tế nếu có
      final pos = await LocationService.getCurrentDevicePosition();
      if (pos != null) {
        _currentLat = pos.latitude;
        _currentLng = pos.longitude;
      }

      final res = await LocationService.reportLocation(
        deviceId: _deviceId,
        latitude: _currentLat,
        longitude: _currentLng,
        accuracy: 10,
        speed: 0,
      );

      final alertTriggered = res['alertTriggered'] == true;

      setState(() {
        _lastReportedTime = DateTime.now();
        _lastAlertTriggered = alertTriggered;
        if (alertTriggered) {
          _statusMessage = '⚠️ Cảnh báo: Vị trí hiện tại đang nằm ngoài Vùng an toàn!';
        } else {
          _statusMessage = '✓ Đã đồng bộ vị trí an toàn với Phụ huynh';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi gửi vị trí: ${e.toString().replaceAll('Exception: ', '')}';
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _toggleAutoShare(bool enable) {
    setState(() => _isAutoSharing = enable);
    _autoShareTimer?.cancel();
    if (enable) {
      _sendLocation();
      _autoShareTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        _sendLocation();
      });
    }
  }

  Future<void> _handleUnpair() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy ghép nối thiết bị?'),
        content: const Text('Ứng dụng sẽ ngưng chia sẻ vị trí và thoát về màn hình đăng nhập.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _autoShareTimer?.cancel();
      await PairingService.unpairChildDevice();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chế độ thiết bị Trẻ em'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.link_off),
            tooltip: 'Hủy ghép nối',
            onPressed: _handleUnpair,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.security, size: 56, color: Colors.teal),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Đang bảo vệ: $_childName',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thiết bị đã kết nối an toàn với máy Phụ huynh',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tự động gửi vị trí (25s)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Switch(
                            value: _isAutoSharing,
                            activeThumbColor: Colors.teal,
                            onChanged: _toggleAutoShare,
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.my_location, size: 20, color: Colors.teal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vĩ độ: ${_currentLat.toStringAsFixed(6)} | Kinh độ: ${_currentLng.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_lastReportedTime != null)
                        Text(
                          'Cập nhật lần cuối: ${_lastReportedTime!.hour.toString().padLeft(2, '0')}:${_lastReportedTime!.minute.toString().padLeft(2, '0')}:${_lastReportedTime!.second.toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _lastAlertTriggered ? Colors.red.shade50 : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _lastAlertTriggered ? Colors.red.shade200 : Colors.teal.shade200,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _lastAlertTriggered ? Colors.red.shade800 : Colors.teal.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Gửi vị trí GPS ngay',
                backgroundColor: Colors.teal,
                isLoading: _isSending,
                icon: Icons.send_rounded,
                onPressed: _sendLocation,
              ),
              const SizedBox(height: 24),
              // Công cụ mô phỏng dành cho báo cáo / demo đồ án
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
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
                          'Mô phỏng vị trí (Dùng demo đồ án)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Thử nghiệm kích hoạt Cảnh báo rời vùng an toàn ngay trên máy mà không cần di chuyển thật:',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
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
      ),
    );
  }
}
