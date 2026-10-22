import 'package:flutter/material.dart';
import '../../models/child_model.dart';
import '../../services/child_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/status_badge.dart';
import 'qr_pairing_dialog.dart';

class ChildrenTab extends StatefulWidget {
  const ChildrenTab({super.key});

  @override
  State<ChildrenTab> createState() => _ChildrenTabState();
}

class _ChildrenTabState extends State<ChildrenTab> {
  List<ChildModel> _children = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ChildService.getChildren();
      setState(() {
        _children = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showAddChildDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDob;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Thêm hồ sơ Trẻ em'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: 'Tên của bé',
                  hint: 'Ví dụ: Bé An',
                  prefixIcon: Icons.child_care,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: emailController,
                  label: 'Email tài khoản Trẻ (Tùy chọn)',
                  hint: 'Ví dụ: nepjun123.com@gmail.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    selectedDob == null
                        ? 'Chọn ngày sinh (Tùy chọn)'
                        : 'Ngày sinh: ${selectedDob!.day}/${selectedDob!.month}/${selectedDob!.year}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: const Icon(Icons.calendar_today, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 365 * 8)),
                      firstDate: DateTime(2005),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDob = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: notesController,
                  label: 'Ghi chú',
                  hint: 'Lớp học, trường, dặn dò...',
                  prefixIcon: Icons.notes,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                try {
                  await ChildService.createChild(
                    name: name,
                    dateOfBirth: selectedDob,
                    notes: notesController.text.trim(),
                    childEmail: emailController.text.trim(),
                  );
                  _loadChildren();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Đã thêm hồ sơ trẻ thành công')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Tạo hồ sơ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditChildDialog(ChildModel child) {
    final nameController = TextEditingController(text: child.name);
    final emailController = TextEditingController(text: child.childUser?['email'] ?? '');
    final notesController = TextEditingController(text: child.notes ?? '');
    DateTime? selectedDob = child.dateOfBirth;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Chỉnh sửa hồ sơ Trẻ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: 'Tên của bé',
                  prefixIcon: Icons.child_care,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: emailController,
                  label: 'Email tài khoản Trẻ (Liên kết)',
                  hint: 'Nhập email tài khoản trẻ để liên kết',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    selectedDob == null
                        ? 'Chọn ngày sinh'
                        : 'Ngày sinh: ${selectedDob!.day}/${selectedDob!.month}/${selectedDob!.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDob ?? DateTime.now(),
                      firstDate: DateTime(2005),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDob = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: notesController,
                  label: 'Ghi chú',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                try {
                  await ChildService.updateChild(
                    id: child.id,
                    name: nameController.text.trim(),
                    dateOfBirth: selectedDob,
                    notes: notesController.text.trim(),
                    childEmail: emailController.text.trim(),
                  );
                  _loadChildren();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật hồ sơ thành công!')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeleteChild(ChildModel child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa hồ sơ ${child.name}?'),
        content: const Text('Tất cả thiết bị và vùng an toàn liên quan sẽ bị xóa theo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ChildService.deleteChild(child.id);
        _loadChildren();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
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
            ElevatedButton(onPressed: _loadChildren, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadChildren,
        child: _children.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.child_care, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa có hồ sơ trẻ nào',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bấm nút bên dưới để tạo hồ sơ và ghép nối với điện thoại của con',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Thêm hồ sơ Trẻ',
                        icon: Icons.add,
                        onPressed: _showAddChildDialog,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _children.length,
                itemBuilder: (context, index) {
                  final child = _children[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  child.name.isNotEmpty ? child.name[0].toUpperCase() : 'B',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      child.name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    if (child.notes != null && child.notes!.isNotEmpty)
                                      Text(
                                        child.notes!,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          child.childUser != null ? Icons.check_circle : Icons.link_off,
                                          size: 14,
                                          color: child.childUser != null ? Colors.teal : Colors.orange,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            child.childUser != null
                                                ? 'Tài khoản: ${child.childUser!['email'] ?? ""}'
                                                : 'Chưa liên kết email tài khoản',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: child.childUser != null ? Colors.teal.shade700 : Colors.orange.shade800,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'edit') _showEditChildDialog(child);
                                  if (val == 'delete') _handleDeleteChild(child);
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Xóa hồ sơ', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          const Text(
                            'Thiết bị liên kết:',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          if (child.devices.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Chưa có thiết bị nào được ghép nối',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    icon: const Icon(Icons.qr_code, size: 16),
                                    label: const Text('Ghép nối QR'),
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final res = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => QrPairingDialog(
                                          childProfileId: child.id,
                                          childName: child.name,
                                        ),
                                      );
                                      if (res == true) {
                                        _loadChildren();
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Ghép nối thiết bị thành công!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            )
                          else
                            ...child.devices.map(
                              (dev) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.smartphone, color: Colors.teal),
                                title: Text(dev.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'Nền tảng: ${dev.platform} | ID: ${dev.deviceIdentifier}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: StatusBadge(status: dev.status),
                              ),
                            ),
                          if (child.devices.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.add_to_home_screen, size: 16),
                                label: const Text('Ghép thêm thiết bị mới'),
                                onPressed: () async {
                                  final res = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => QrPairingDialog(
                                      childProfileId: child.id,
                                      childName: child.name,
                                    ),
                                  );
                                  if (res == true) _loadChildren();
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddChildDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm trẻ'),
      ),
    );
  }
}
