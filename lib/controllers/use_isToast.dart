import 'package:flutter/material.dart';

class _ToastData {
  final String title;
  final String message;
  final bool open;

  _ToastData({
    required this.title,
    required this.message,
    required this.open,
  });
}

class ToastService {
  static final ToastService _instance = ToastService._internal();

  factory ToastService() => _instance;

  ToastService._internal();

  final List<_ToastData> _toastQueue = [];
  OverlayEntry? _overlayEntry;

  void showToast({
    required BuildContext context,
    required String title,
    String? description,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (_overlayEntry != null) return; // Only 1 toast at a time

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.85),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                if (description != null)
                  Text(description,
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(duration, () => dismissToast());
  }

  void dismissToast() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
