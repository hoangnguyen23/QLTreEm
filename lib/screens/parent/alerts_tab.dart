import 'package:flutter/material.dart';
import '../../models/alert_model.dart';
import '../../models/child_model.dart';
import '../../services/alert_service.dart';
import '../../services/child_service.dart';
import '../../widgets/status_badge.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  List<AlertModel> _alerts = [];
  List<ChildModel> _children = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // Bộ lọc
  String? _selectedChildId; // null = Tất cả trẻ
  String? _selectedType; // null = Tất cả loại
  String? _selectedStatus; // null = Tất cả trạng thái

  @override
  void initState() {
    super.initState();
    _loadChildrenAndAlerts();
  }

  Future<void> _loadChildrenAndAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final children = await ChildService.getChildren();
      final res = await AlertService.getAlerts(
        status: _selectedStatus,
        type: _selectedType,
        childId: _selectedChildId,
      );

      if (mounted) {
        setState(() {
          _children = children;
          _alerts = (res['alerts'] as List<AlertModel>?) ?? [];
          _unreadCount = (res['unreadCount'] as int?) ?? 0;
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

  Future<void> _loadAlertsOnly() async {
    try {
      final res = await AlertService.getAlerts(
        status: _selectedStatus,
        type: _selectedType,
        childId: _selectedChildId,
      );
      if (mounted) {
        setState(() {
          _alerts = (res['alerts'] as List<AlertModel>?) ?? [];
          _unreadCount = (res['unreadCount'] as int?) ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleMarkRead(AlertModel alert) async {
    try {
      await AlertService.markRead(alert.id);
      _loadAlertsOnly();
    } catch (_) {}
  }

  Future<void> _handleMarkResolved(AlertModel alert) async {
    try {
      await AlertService.markResolved(alert.id);
      _loadAlertsOnly();
    } catch (_) {}
  }

  Future<void> _handleDeleteAlert(AlertModel alert) async {
    try {
      await AlertService.deleteAlert(alert.id);
      _loadAlertsOnly();
    } catch (_) {}
  }

  String _formatType(String type) {
    switch (type) {
      case 'SAFE_ZONE_EXIT':
        return 'Rời vùng an toàn';
      case 'DEVICE_OFFLINE':
        return 'Mất kết nối thiết bị';
      case 'LOW_BATTERY':
        return 'Pin yếu';
      case 'SCREEN_TIME_LIMIT':
        return 'Giới hạn màn hình';
      case 'OTHER':
        return 'Báo động SOS / Khác';
      default:
        return type;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'SAFE_ZONE_EXIT':
        return Icons.warning_rounded;
      case 'DEVICE_OFFLINE':
        return Icons.wifi_off_rounded;
      case 'LOW_BATTERY':
        return Icons.battery_alert_rounded;
      case 'SCREEN_TIME_LIMIT':
        return Icons.timer_off_rounded;
      case 'OTHER':
        return Icons.sos_rounded;
      default:
        return Icons.notifications_active;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'SAFE_ZONE_EXIT':
        return Colors.orange.shade800;
      case 'OTHER':
        return Colors.red.shade700;
      case 'DEVICE_OFFLINE':
        return Colors.blueGrey;
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadChildrenAndAlerts, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Cảnh Báo & Vi Phạm'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount chưa đọc',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadAlertsOnly,
          ),
        ],
      ),
      body: Column(
        children: [
          // Bộ lọc nâng cao theo Trẻ, Loại cảnh báo và Trạng thái
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Lọc theo từng Trẻ
                Row(
                  children: [
                    const Icon(Icons.child_care, size: 18, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    const Text('Lọc theo trẻ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value: _selectedChildId,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Tất cả các con')),
                              ..._children.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedChildId = val);
                              _loadAlertsOnly();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 2. Lọc theo Loại cảnh báo & Trạng thái
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Trạng thái Chưa đọc
                      FilterChip(
                        label: const Text('Chưa đọc'),
                        selected: _selectedStatus == 'UNREAD',
                        selectedColor: Colors.red.shade100,
                        checkmarkColor: Colors.red,
                        onSelected: (selected) {
                          setState(() => _selectedStatus = selected ? 'UNREAD' : null);
                          _loadAlertsOnly();
                        },
                      ),
                      const SizedBox(width: 6),
                      // Rời vùng an toàn
                      FilterChip(
                        label: const Text('Rời vùng an toàn'),
                        selected: _selectedType == 'SAFE_ZONE_EXIT',
                        selectedColor: Colors.orange.shade100,
                        onSelected: (selected) {
                          setState(() => _selectedType = selected ? 'SAFE_ZONE_EXIT' : null);
                          _loadAlertsOnly();
                        },
                      ),
                      const SizedBox(width: 6),
                      // Khẩn cấp SOS
                      FilterChip(
                        label: const Text('Báo động SOS'),
                        selected: _selectedType == 'OTHER',
                        selectedColor: Colors.red.shade100,
                        onSelected: (selected) {
                          setState(() => _selectedType = selected ? 'OTHER' : null);
                          _loadAlertsOnly();
                        },
                      ),
                      const SizedBox(width: 6),
                      // Đã xử lý
                      FilterChip(
                        label: const Text('Đã xử lý'),
                        selected: _selectedStatus == 'RESOLVED',
                        selectedColor: Colors.green.shade100,
                        onSelected: (selected) {
                          setState(() => _selectedStatus = selected ? 'RESOLVED' : null);
                          _loadAlertsOnly();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Danh sách cảnh báo
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAlertsOnly,
              child: _alerts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'Không có cảnh báo nào',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tất cả trẻ đều đang an toàn hoặc không có vi phạm theo bộ lọc này.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _alerts.length,
                      itemBuilder: (context, index) {
                        final alert = _alerts[index];
                        final isUnread = alert.status == 'UNREAD';
                        final typeColor = _getTypeColor(alert.type);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: isUnread ? 3 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: isUnread
                                ? BorderSide(color: Colors.red.shade400, width: 1.5)
                                : BorderSide.none,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: typeColor.withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(_getTypeIcon(alert.type), color: typeColor, size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              alert.title,
                                              style: TextStyle(
                                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              _formatType(alert.type),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: typeColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    StatusBadge(status: alert.status),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  alert.message,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13.5,
                                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                                const Divider(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${alert.createdAt.hour.toString().padLeft(2, '0')}:${alert.createdAt.minute.toString().padLeft(2, '0')} ngày ${alert.createdAt.day}/${alert.createdAt.month}/${alert.createdAt.year}',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        if (isUnread)
                                          TextButton.icon(
                                            icon: const Icon(Icons.mark_email_read, size: 15),
                                            label: const Text('Đã đọc', style: TextStyle(fontSize: 12)),
                                            onPressed: () => _handleMarkRead(alert),
                                          ),
                                        if (alert.status != 'RESOLVED')
                                          TextButton.icon(
                                            icon: const Icon(Icons.done_all, size: 15, color: Colors.green),
                                            label: const Text('Đã xử lý', style: TextStyle(color: Colors.green, fontSize: 12)),
                                            onPressed: () => _handleMarkResolved(alert),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                          tooltip: 'Xóa cảnh báo',
                                          onPressed: () => _handleDeleteAlert(alert),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
