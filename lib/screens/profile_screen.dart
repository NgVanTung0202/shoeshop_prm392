import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

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
  File? _newAvatarFile;         // file ảnh mới chọn từ gallery
  String? _existingAvatarUrl;  // URL ảnh đang lưu trên Storage

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

  /// Load thông tin profile từ Firestore
  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data != null) {
      _nameController.text = data["name"] ?? "";
      _phoneController.text = data["phone"] ?? "";
      _existingAvatarUrl = data["avatarUrl"];
    }

    if (!mounted) return;
    setState(() {});
  }

  /// Chọn ảnh từ gallery
  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked == null) return;
    setState(() {
      _newAvatarFile = File(picked.path);
    });
  }

  /// Lưu profile (name, phone, avatar nếu có)
  Future<void> _updateProfile() async {
    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _fs.updateProfileWithAvatar(
        uid: user.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        avatarFile: _newAvatarFile,
        existingAvatarUrl: _existingAvatarUrl,
      );

      // Nếu vừa upload ảnh mới, cập nhật lại URL hiển thị
      if (_newAvatarFile != null) {
        await _loadProfile();
        _newAvatarFile = null;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thông tin thành công")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  /// Widget hiển thị avatar
  Widget _buildAvatar() {
    ImageProvider? imageProvider;

    if (_newAvatarFile != null) {
      imageProvider = FileImage(_newAvatarFile!);
    } else if (_existingAvatarUrl != null && _existingAvatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_existingAvatarUrl!);
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: Colors.blue.shade100,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person, size: 56, color: Colors.blue)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: loading ? null : _pickAvatar,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt,
                    size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông tin cá nhân"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildAvatar(),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: loading ? null : _pickAvatar,
              icon: const Icon(Icons.photo_library, size: 18),
              label: const Text("Đổi ảnh đại diện"),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Họ và tên",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Số điện thoại",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : _updateProfile,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Lưu thay đổi",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
