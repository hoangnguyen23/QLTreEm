import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/pairing_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'child_tracker_screen.dart';

class ChildPairingScreen extends StatefulWidget {
  const ChildPairingScreen({super.key});

  @override
  State<ChildPairingScreen> createState() => _ChildPairingScreenState();
}

class _ChildPairingScreenState extends State<ChildPairingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _deviceNameController = TextEditingController(text: 'Điện thoại của Bé');
  final _deviceIdController = TextEditingController(
    text: 'DEV_${DateTime.now().millisecondsSinceEpoch}',
  );
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final paired = await PairingService.isChildDevicePaired();
    if (paired && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChildTrackerScreen()),
      );
    }
  }

  Future<void> _handleConfirmPairing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await PairingService.confirmPairing(
        token: _tokenController.text.trim(),
        deviceIdentifier: _deviceIdController.text.trim(),
        deviceName: _deviceNameController.text.trim(),
        platform: 'ANDROID',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ghép nối thiết bị với phụ huynh thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      final role = await ApiService.getSavedRole();

      if (mounted) {
        if (role == 'CHILD' && Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ChildTrackerScreen()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghép nối thiết bị Trẻ em'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.phonelink_setup, size: 72, color: Colors.teal),
                const SizedBox(height: 16),
                Text(
                  'Cài đặt ứng dụng trên máy của Trẻ',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhập mã bí mật từ mã QR trên máy phụ huynh để kết nối và chia sẻ vị trí',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _tokenController,
                  label: 'Mã token ghép nối (hoặc quét QR)',
                  hint: 'Nhập chuỗi mã hiển thị dưới QR',
                  prefixIcon: Icons.vpn_key_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mã ghép nối' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _deviceNameController,
                  label: 'Tên thiết bị này',
                  prefixIcon: Icons.smartphone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng đặt tên thiết bị' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _deviceIdController,
                  label: 'Mã định danh phần cứng (Hardware ID)',
                  prefixIcon: Icons.fingerprint,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập định danh máy' : null,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Hoàn tất ghép nối',
                  backgroundColor: Colors.teal,
                  isLoading: _isLoading,
                  onPressed: _handleConfirmPairing,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
