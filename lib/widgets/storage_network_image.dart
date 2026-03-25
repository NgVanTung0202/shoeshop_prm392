import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

/// Ảnh từ URL (Storage / CDN). Trên Web, [Image.network] đôi khi lỗi dù URL đúng
/// (CORS / rule đọc cần auth). Khi đó thử [FirebaseStorage.refFromURL] + [getData]
/// để dùng session Firebase Auth đã đăng nhập.
class StorageNetworkImage extends StatefulWidget {
  const StorageNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    required this.fallback,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget fallback;

  @override
  State<StorageNetworkImage> createState() => _StorageNetworkImageState();
}

class _StorageNetworkImageState extends State<StorageNetworkImage> {
  Uint8List? _bytes;
  bool _sdkLoadStarted = false;

  static bool _looksLikeFirebaseStorageUrl(String u) {
    return u.contains('firebasestorage.googleapis.com') ||
        u.contains('firebasestorage.app');
  }

  static bool _isHttpUrl(String u) {
    return u.startsWith('http://') || u.startsWith('https://');
  }

  static bool _isGsUrl(String u) {
    return u.startsWith('gs://');
  }

  static bool _isStoragePath(String u) {
    return u.startsWith('images/') || u.startsWith('avatars/');
  }

  Reference _resolveStorageRef(String u) {
    if (_isGsUrl(u) || _looksLikeFirebaseStorageUrl(u)) {
      return FirebaseStorage.instance.refFromURL(u);
    }
    return FirebaseStorage.instance.ref().child(u);
  }

  Future<void> _loadViaSdk() async {
    try {
      final ref = _resolveStorageRef(widget.url.trim());
      final data = await ref.getData(8 * 1024 * 1024);
      if (!mounted) return;
      if (data != null && data.isNotEmpty) {
        setState(() => _bytes = data);
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url.trim();

    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    if (_isHttpUrl(url)) {
      return Image.network(
        url,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          if (_looksLikeFirebaseStorageUrl(url) && !_sdkLoadStarted) {
            _sdkLoadStarted = true;
            _loadViaSdk();
          }
          return widget.fallback;
        },
      );
    }

    if ((_isGsUrl(url) || _isStoragePath(url)) && !_sdkLoadStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _sdkLoadStarted) return;
          _sdkLoadStarted = true;
          _loadViaSdk();
      });
    }

    return widget.fallback;
  }
}
