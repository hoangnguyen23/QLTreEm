import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text = status;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        text = 'Đang hoạt động';
        break;
      case 'INACTIVE':
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        text = 'Ngoại tuyến';
        break;
      case 'LOST':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        text = 'Báo mất';
        break;
      case 'UNPAIRED':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        text = 'Chưa ghép nối';
        break;
      case 'UNREAD':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        text = 'Chưa đọc';
        break;
      case 'READ':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        text = 'Đã đọc';
        break;
      case 'RESOLVED':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        text = 'Đã xử lý';
        break;
      case 'COMPLETED':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        text = 'Thành công';
        break;
      case 'PENDING':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
        text = 'Chờ ghép nối';
        break;
      default:
        bg = Colors.blueGrey.shade50;
        fg = Colors.blueGrey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
