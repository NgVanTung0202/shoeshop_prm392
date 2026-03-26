import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/admin_drawer.dart';

class AdminUsersScreen extends StatelessWidget {
  final FirestoreService _fs = FirestoreService();

  AdminUsersScreen({super.key});

  // ─── Danh sách role hợp lệ ───────────────────────────────────────────────
  static const List<String> _roles = ['customer', 'staff', 'admin'];

  // ─── Dialog tạo tài khoản nhân viên ──────────────────────────────────────
  void _showCreateDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedRole = 'staff';
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text("Tạo tài khoản nhân viên"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildField(nameCtrl, "Họ và tên", Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildField(
                      emailCtrl,
                      "Email",
                      Icons.email_outlined,
                      keyboard: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      phoneCtrl,
                      "Số điện thoại",
                      Icons.phone_outlined,
                      keyboard: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: "Vai trò",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items:
                          ['staff', 'admin']
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(_roleLabel(r)),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (v) =>
                              setDialogState(() => selectedRole = v ?? 'staff'),
                    ),
                    const SizedBox(height: 8),
                    // Ghi chú cho admin
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Nhân viên sẽ dùng email này để tự đăng ký mật khẩu. Không cần xác thực email.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(ctx),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed:
                      loading
                          ? null
                          : () async {
                            if (emailCtrl.text.trim().isEmpty ||
                                nameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Vui lòng điền đầy đủ thông tin",
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() => loading = true);

                            try {
                              // Chỉ lưu Firestore — không tạo Firebase Auth
                              // Không làm mất session admin
                              await AuthService().createStaffRecord(
                                email: emailCtrl.text.trim(),
                                name: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                role: selectedRole,
                              );

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Đã tạo hồ sơ nhân viên thành công",
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => loading = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Lỗi: $e")),
                                );
                              }
                            }
                          },
                  child:
                      loading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text("Tạo"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Dialog chỉnh sửa thông tin user ─────────────────────────────────────
  void _showEditDialog(
    BuildContext context,
    String uid,
    Map<String, dynamic> data,
  ) {
    final nameCtrl = TextEditingController(text: data["name"] ?? "");
    final phoneCtrl = TextEditingController(text: data["phone"] ?? "");
    String selectedRole =
        _roles.contains(data["role"]) ? data["role"] as String : 'customer';
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text("Chỉnh sửa tài khoản"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Email chỉ xem, không sửa
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      child: Text(
                        data["email"] ?? "",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildField(nameCtrl, "Họ và tên", Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildField(
                      phoneCtrl,
                      "Số điện thoại",
                      Icons.phone_outlined,
                      keyboard: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: "Vai trò",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items:
                          _roles
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(_roleLabel(r)),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (v) => setDialogState(
                            () => selectedRole = v ?? 'customer',
                          ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(ctx),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed:
                      loading
                          ? null
                          : () async {
                            setDialogState(() => loading = true);
                            try {
                              await _fs.updateUserInfo(
                                uid: uid,
                                name: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                role: selectedRole,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Cập nhật thành công"),
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => loading = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Lỗi: $e")),
                                );
                              }
                            }
                          },
                  child:
                      loading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text("Lưu"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Confirm dialog xóa ───────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, String uid, String email) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Xác nhận xóa"),
            content: Text("Bạn có chắc muốn xóa tài khoản \"$email\" không?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  try {
                    await _fs.deleteUser(uid);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đã xóa tài khoản")),
                    );
                  } catch (e) {
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Lỗi: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text("Xóa", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  static String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'staff':
        return 'Nhân viên';
      default:
        return 'Khách hàng';
    }
  }

  static Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'staff':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  static Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(selected: AdminMenuItem.users),
      appBar: AppBar(
        title: const Text("Quản lý người dùng"),
        automaticallyImplyLeading: false,
        leading: Builder(
          builder:
              (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                tooltip: 'Menu',
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text("Thêm nhân viên"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fs.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có dữ liệu"));
          }

          final users = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              final role = data["role"] ?? "customer";
              final email = data["email"] ?? "No Email";
              final name = data["name"] ?? "";

              return Card(
                elevation: 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _roleColor(role).withValues(alpha: 0.15),
                    child: Text(
                      (name.isNotEmpty
                              ? name[0]
                              : (email.isNotEmpty ? email[0] : '?'))
                          .toUpperCase(),
                      style: TextStyle(
                        color: _roleColor(role),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    name.isNotEmpty ? name : email,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge role
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _roleColor(role).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _roleColor(role).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _roleLabel(role),
                          style: TextStyle(
                            fontSize: 11,
                            color: _roleColor(role),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Edit
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 20,
                        ),
                        tooltip: "Chỉnh sửa",
                        onPressed:
                            () => _showEditDialog(context, user.id, data),
                      ),
                      // Delete
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        tooltip: "Xóa",
                        onPressed:
                            () => _confirmDelete(context, user.id, email),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
