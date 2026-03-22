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

  Future<void> _loadViaSdk() async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(widget.url);
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
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    return Image.network(
      widget.url,
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
        if (_looksLikeFirebaseStorageUrl(widget.url) && !_sdkLoadStarted) {
          _sdkLoadStarted = true;
          _loadViaSdk();
        }
        return widget.fallback;
      },
    );
  }
}
