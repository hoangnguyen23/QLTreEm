import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../parent/parent_main_screen.dart';
import '../admin/admin_users_screen.dart';
import '../child/child_main_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final bool isLogin;

  const OtpScreen({
    super.key,
    required this.email,
    required this.isLogin,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Vui lòng nhập đủ 6 chữ số OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isLogin) {
        final user = await AuthService.verifyLoginOtp(
          email: widget.email,
          otp: otp,
        );

        if (!mounted) return;

        if (user.role == 'ADMIN') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
            (route) => false,
          );
        } else if (user.role == 'CHILD') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ChildMainScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ParentMainScreen()),
            (route) => false,
          );
        }
      } else {
        await AuthService.verifyRegisterOtp(
          email: widget.email,
          otp: otp,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác minh email thành công! Vui lòng đăng nhập.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Trở về màn hình đăng nhập
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
        title: const Text('Xác minh mã OTP'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.mark_email_read_outlined, size: 72, color: Colors.blueAccent),
              const SizedBox(height: 24),
              Text(
                'Nhập mã OTP 6 chữ số',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã OTP đã được gửi đến email:\n${widget.email}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _otpController,
                label: 'Mã OTP (6 chữ số)',
                hint: '123456',
                prefixIcon: Icons.lock_clock_outlined,
                keyboardType: TextInputType.number,
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
                text: 'Xác nhận OTP',
                isLoading: _isLoading,
                onPressed: _handleVerifyOtp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
