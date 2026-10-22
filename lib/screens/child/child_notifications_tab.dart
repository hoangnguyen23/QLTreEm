import 'package:flutter/material.dart';
import '../../models/alert_model.dart';
import '../../services/alert_service.dart';

class ChildNotificationsTab extends StatefulWidget {
  const ChildNotificationsTab({super.key});

  @override
  State<ChildNotificationsTab> createState() => _ChildNotificationsTabState();
}

class _ChildNotificationsTabState extends State<ChildNotificationsTab> {
  List<AlertModel> _alerts = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AlertService.getAlerts();
      if (mounted) {
        setState(() {
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

  Future<void> _handleMarkRead(AlertModel alert) async {
    try {
      await AlertService.markRead(alert.id);
      _loadAlerts();
    } catch (_) {}
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
            ElevatedButton(onPressed: _loadAlerts, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Thông báo từ Phụ huynh'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount mới',
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
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAlerts,
        child: _alerts.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mark_chat_read_outlined, size: 72, color: Colors.teal.shade200),
                      const SizedBox(height: 16),
                      const Text(
                        'Không có thông báo mới',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Con chưa có lời nhắc hoặc cảnh báo nào từ Phụ huynh.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
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

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: isUnread ? 3 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isUnread
                          ? BorderSide(color: Colors.teal.shade400, width: 1.5)
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
                                  Icon(
                                    alert.type == 'SAFE_ZONE_EXIT'
                                        ? Icons.warning_amber_rounded
                                        : Icons.notifications_active,
                                    color: alert.type == 'SAFE_ZONE_EXIT' ? Colors.orange : Colors.teal,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    alert.title,
                                    style: TextStyle(
                                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              if (isUnread)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.teal),
                                  ),
                                  child: const Text(
                                    'Mới',
                                    style: TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            alert.message,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${alert.createdAt.hour.toString().padLeft(2, '0')}:${alert.createdAt.minute.toString().padLeft(2, '0')} ngày ${alert.createdAt.day}/${alert.createdAt.month}/${alert.createdAt.year}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              if (isUnread)
                                TextButton.icon(
                                  icon: const Icon(Icons.check, size: 16, color: Colors.teal),
                                  label: const Text('Đã nhận', style: TextStyle(color: Colors.teal)),
                                  onPressed: () => _handleMarkRead(alert),
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
    );
  }
}
