import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/pairing_service.dart';

class QrPairingDialog extends StatefulWidget {
  final String childProfileId;
  final String childName;

  const QrPairingDialog({
    super.key,
    required this.childProfileId,
    required this.childName,
  });

  @override
  State<QrPairingDialog> createState() => _QrPairingDialogState();
}

class _QrPairingDialogState extends State<QrPairingDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _pairingId;
  String? _token;
  String? _qrPayload;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _generatePairing();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _generatePairing() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await PairingService.generatePairing(widget.childProfileId);
      setState(() {
        _pairingId = res['pairingId'];
        _token = res['token'];
        _qrPayload = res['qrPayload'] ?? res['token'];
        _isLoading = false;
      });

      // Bắt đầu thăm dò trạng thái xem máy con đã quét chưa
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        if (_pairingId == null) return;
        try {
          final status = await PairingService.checkPairingStatus(_pairingId!);
          if (status == 'COMPLETED') {
            timer.cancel();
            if (mounted) {
              Navigator.pop(context, true); // Thành công
            }
          }
        } catch (_) {}
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ghép nối: ${widget.childName}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _generatePairing,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _qrPayload ?? '',
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mở ứng dụng trên máy của Trẻ,\nchọn "Ghép nối QR" hoặc nhập mã bên dưới:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _token ?? '',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Sao chép mã',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _token ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép mã ghép nối')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Đang chờ thiết bị trẻ xác nhận...',
                    style: TextStyle(fontSize: 12, color: Colors.blueAccent),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
