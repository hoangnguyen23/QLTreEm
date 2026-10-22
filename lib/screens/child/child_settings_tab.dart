import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ChildSettingsTab extends StatefulWidget {
  const ChildSettingsTab({super.key});

  @override
  State<ChildSettingsTab> createState() => _ChildSettingsTabState();
}

class _ChildSettingsTabState extends State<ChildSettingsTab> {
  UserModel? _user;
  bool _isLoading = true;
  LocationPermission _locationPermission = LocationPermission.denied;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfileAndPermissions();
  }

  Future<void> _loadProfileAndPermissions() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getProfile();
      final perm = await Geolocator.checkPermission();
      if (mounted) {
        setState(() {
          _user = user;
          _locationPermission = perm;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestLocationPermission() async {
    final perm = await Geolocator.requestPermission();
    if (mounted) {
      setState(() => _locationPermission = perm);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            perm == LocationPermission.always || perm == LocationPermission.whileInUse
                ? 'Đã cấp quyền truy cập vị trí thành công!'
                : 'Quyền vị trí chưa được cấp',
          ),
          backgroundColor:
              perm == LocationPermission.always || perm == LocationPermission.whileInUse ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Trẻ em này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isLocationGranted = _locationPermission == LocationPermission.always ||
        _locationPermission == LocationPermission.whileInUse;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt & Hồ sơ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thẻ hồ sơ
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.teal.shade100,
                      child: Text(
                        _user?.name.isNotEmpty == true ? _user!.name[0].toUpperCase() : 'C',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user?.name ?? 'Trẻ em',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _user?.email ?? '',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.teal),
                            ),
                            child: const Text(
                              'Vai trò: Trẻ em (CHILD)',
                              style: TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nhóm Cài đặt Quyền hệ thống
            const Text(
              'Quyền & Hệ thống',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: isLocationGranted ? Colors.green : Colors.orange,
                    ),
                    title: const Text('Quyền truy cập Vị trí (GPS)', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      isLocationGranted ? 'Đã cấp quyền vị trí chính xác' : 'Chưa cấp quyền hoặc bị từ chối',
                      style: TextStyle(color: isLocationGranted ? Colors.green : Colors.red, fontSize: 12),
                    ),
                    trailing: isLocationGranted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                            onPressed: _requestLocationPermission,
                            child: const Text('Cấp quyền'),
                          ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active, color: Colors.blueAccent),
                    title: const Text('Nhận cảnh báo & Thông báo', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Nhận thông báo khi phụ huynh gửi lời nhắc', style: TextStyle(fontSize: 12)),
                    value: _notificationsEnabled,
                    // ignore: deprecated_member_use
                    activeColor: Colors.teal,
                    onChanged: (val) {
                      setState(() => _notificationsEnabled = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Nhóm Thông tin thiết bị & Ứng dụng
            const Text(
              'Thông tin ứng dụng',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.security, color: Colors.teal),
                    title: Text('Phiên bản ứng dụng'),
                    trailing: Text('v1.0.0 (Bảo vệ trẻ em)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.teal),
                    title: const Text('Trạng thái kết nối máy chủ'),
                    subtitle: const Text('Đã kết nối trực tiếp với Phụ huynh'),
                    trailing: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nút Đăng xuất
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }
}
