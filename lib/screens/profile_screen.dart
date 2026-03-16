import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';

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
      child: Stack(
        children: [
          // Dùng UniqueKey để force rebuild khi ảnh mới được upload
          CircleAvatar(
            key: _avatarKey,
            radius: 56,
            backgroundColor: Colors.blue.shade100,
            backgroundImage: _pickedBytes != null
                ? MemoryImage(_pickedBytes!) as ImageProvider
                : (_existingAvatarUrl != null && _existingAvatarUrl!.isNotEmpty)
                    ? NetworkImage(_existingAvatarUrl!)
                    : null,
            child: (_pickedBytes == null &&
                    (_existingAvatarUrl == null ||
                        _existingAvatarUrl!.isEmpty))
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

  // ─── Build ────────────────────────────────────────────────────────────────
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