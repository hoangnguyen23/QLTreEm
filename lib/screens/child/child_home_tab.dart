import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/alert_service.dart';
import '../../services/auth_service.dart';
import 'child_pairing_screen.dart';

class ChildHomeTab extends StatefulWidget {
  final VoidCallback onNavigateToGps;

  const ChildHomeTab({super.key, required this.onNavigateToGps});

  @override
  State<ChildHomeTab> createState() => _ChildHomeTabState();
}

class _ChildHomeTabState extends State<ChildHomeTab> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isSendingSos = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.getProfile();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSosButton() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
        title: const Text('KÍCH HOẠT BÁO ĐỘNG SOS?'),
        content: const Text(
          'Một cảnh báo khẩn cấp và vị trí hiện tại sẽ được gửi ngay lập tức tới máy của Phụ huynh để yêu cầu hỗ trợ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy bỏ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('GỬI SOS NGAY'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSendingSos = true);

    try {
      final devices = (_user?.childProfile?['devices'] as List?) ?? [];
      final deviceId = devices.isNotEmpty ? devices.first['id'] as String? : null;

      await AlertService.triggerSos(deviceId: deviceId);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 54),
          title: const Text('ĐÃ GỬI TÍN HIỆU SOS'),
          content: const Text(
            'Phụ huynh đã nhận được thông báo khẩn cấp! Con hãy giữ bình tĩnh và ở yên vị trí an toàn.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi SOS: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingSos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final parent = _user?.childProfile?['parent'] as Map<String, dynamic>?;
    final parentName = parent?['name'] as String? ?? 'Chưa liên kết phụ huynh';
    final parentPhone = parent?['phone'] as String? ?? 'Chưa có SĐT';
    final isConnected = parent != null;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              // Thẻ chào mừng & Trạng thái an toàn
              Card(
                elevation: 2,
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.green.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user, color: Colors.green, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào, ${_user?.name ?? "Con"}!',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Trạng thái: Đang được bảo vệ an toàn',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Thẻ kết nối với Parent
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.family_restroom, color: Colors.teal),
                              SizedBox(width: 8),
                              Text(
                                'Kết nối với Phụ huynh',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isConnected ? Colors.teal.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isConnected ? Colors.teal : Colors.amber.shade800,
                              ),
                            ),
                            child: Text(
                              isConnected ? 'Đã liên kết' : 'Chưa liên kết',
                              style: TextStyle(
                                color: isConnected ? Colors.teal : Colors.amber.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (isConnected) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade100,
                            child: const Icon(Icons.person, color: Colors.teal),
                          ),
                          title: Text(
                            parentName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Text('Số điện thoại: $parentPhone'),
                          trailing: IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            tooltip: 'Số liên hệ',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Liên hệ $parentName'),
                                  content: Text('Số điện thoại: $parentPhone\nEmail: ${parent['email'] ?? ""}'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'Tài khoản này chưa được liên kết với hồ sơ phụ huynh.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Ghép nối thiết bị qua mã QR'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ChildPairingScreen()),
                            ).then((_) => _loadProfile());
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Nút SOS khẩn cấp
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.sos, size: 72, color: Colors.white),
                    const SizedBox(height: 8),
                    const Text(
                      'BÁO ĐỘNG KHẨN CẤP (SOS)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bấm vào nút bên dưới khi con cần giúp đỡ khẩn cấp',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 4,
                      ),
                      icon: _isSendingSos
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                            )
                          : const Icon(Icons.notifications_active, color: Colors.red),
                      label: Text(
                        _isSendingSos ? 'Đang gửi SOS...' : 'GỬI TÍN HIỆU SOS NGAY',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: _isSendingSos ? null : _handleSosButton,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Thẻ chuyển nhanh sang tab GPS
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.location_on, color: Colors.white),
                  ),
                  title: const Text('Định vị & Chia sẻ vị trí GPS', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Xem tọa độ hiện tại và gửi vị trí cho phụ huynh'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: widget.onNavigateToGps,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
