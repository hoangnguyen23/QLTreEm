import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _selectedRoleFilter;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String url = ApiConfig.usersUrl;
      if (_selectedRoleFilter != null && _selectedRoleFilter!.isNotEmpty) {
        url += '?role=$_selectedRoleFilter';
      }
      final res = await ApiService.get(url);
      final data = res['data'] ?? res;
      final list = (data['users'] as List?) ?? [];
      setState(() {
        _users = list.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showChangeRoleDialog(UserModel user) {
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Đổi vai trò: ${user.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['ADMIN', 'PARENT', 'CHILD'].map((r) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Radio<String>(
                  value: r,
                  // ignore: deprecated_member_use
                  groupValue: selectedRole,
                  // ignore: deprecated_member_use
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedRole = val);
                  },
                ),
                title: Text(r),
                onTap: () => setModalState(() => selectedRole = r),
              );
            }).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                try {
                  await ApiService.patch(
                    '${ApiConfig.usersUrl}/${user.id}/role',
                    {'role': selectedRole},
                  );
                  _loadUsers();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa tài khoản ${user.name}?'),
        content: const Text('Hành động này không thể hoàn tác.'),
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
        await ApiService.delete('${ApiConfig.usersUrl}/${user.id}');
        _loadUsers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Trị Hệ Thống (ADMIN)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Text('Lọc vai trò: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _selectedRoleFilter,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tất cả')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                    DropdownMenuItem(value: 'PARENT', child: Text('PARENT')),
                    DropdownMenuItem(value: 'CHILD', child: Text('CHILD')),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedRoleFilter = val);
                    _loadUsers();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final u = _users[index];
                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: u.role == 'ADMIN'
                                      ? Colors.purple.shade100
                                      : Colors.blue.shade100,
                                  child: Icon(
                                    u.role == 'ADMIN' ? Icons.security : Icons.person,
                                    color: u.role == 'ADMIN' ? Colors.purple : Colors.blue,
                                  ),
                                ),
                                title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${u.email}\nVai trò: ${u.role}'),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == 'role') _showChangeRoleDialog(u);
                                    if (val == 'delete') _handleDeleteUser(u);
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'role',
                                      child: Text('Đổi vai trò'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Xóa tài khoản', style: TextStyle(color: Colors.red)),
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
