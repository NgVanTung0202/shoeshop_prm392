import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:typed_data';

import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FirestoreService _fs = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  bool loading = false;

  XFile? _pickedXFile;
  Uint8List? _pickedBytes;   // preview local trước khi upload
  String? _existingAvatarUrl;

  // Key để force rebuild NetworkImage khi URL thực ra không đổi
  Key _avatarKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ─── Load profile ─────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (!mounted) return;

    setState(() {
      if (data != null) {
        _nameController.text = data["name"] ?? "";
        _phoneController.text = data["phone"] ?? "";
        _existingAvatarUrl = data["avatarUrl"];
      }
    });
  }

  // ─── Pick avatar ──────────────────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    try {
      XFile? xfile;

      if (kIsWeb) {
        xfile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 512,
        );
      } else if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux) {
        const typeGroup = XTypeGroup(
          label: 'Images',
          extensions: <String>['jpg', 'jpeg', 'png', 'webp'],
        );
        xfile = await openFile(acceptedTypeGroups: [typeGroup]);
      } else {
        xfile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 512,
        );
      }

      if (xfile == null) return;

      final bytes = await xfile.readAsBytes();
      if (!mounted) return;

      setState(() {
        _pickedXFile = xfile;
        _pickedBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể chọn ảnh: $e")),
      );
    }
  }

  // ─── Update profile ───────────────────────────────────────────────────────
  Future<void> _updateProfile() async {
    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final bool hasNewAvatar = _pickedXFile != null;

      final String? newUrl = await _fs.updateProfileWithAvatarXFile(
        uid: user.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        xfile: _pickedXFile,
        existingAvatarUrl: _existingAvatarUrl,
      );

      if (!mounted) return;

      setState(() {
        loading = false;
        _pickedXFile = null;
        _pickedBytes = null;
        if (hasNewAvatar && newUrl != null) {
          _existingAvatarUrl = newUrl;
          // Force Flutter tạo lại widget NetworkImage — bỏ qua cache cũ
          _avatarKey = UniqueKey();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thông tin thành công")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  // ─── Avatar widget ────────────────────────────────────────────────────────
  Widget _buildAvatar() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
            ),
            child: CircleAvatar(
              key: _avatarKey,
              radius: 60,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: _pickedBytes != null
                  ? MemoryImage(_pickedBytes!) as ImageProvider
                  : (_existingAvatarUrl != null && _existingAvatarUrl!.isNotEmpty)
                      ? NetworkImage(_existingAvatarUrl!)
                      : null,
              child: (_pickedBytes == null &&
                      (_existingAvatarUrl == null ||
                          _existingAvatarUrl!.isEmpty))
                  ? const Icon(Icons.person, size: 60, color: Colors.blue)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: loading ? null : _pickAvatar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    loading ? "Đang tải..." : "Đổi ảnh đại diện",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông tin cá nhân"),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildAvatar(),
              const SizedBox(height: 32),
              
              /// Form Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        enabled: !loading,
                        decoration: InputDecoration(
                          labelText: "Họ và tên",
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.blue.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        enabled: !loading,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Số điện thoại",
                          prefixIcon: const Icon(Icons.phone_outlined, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.blue.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 28),
              
              /// Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_outlined, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Lưu thay đổi",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}