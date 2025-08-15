// lib/utils/use_isToast.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Optional: set this from main.dart so you can show toasts without a BuildContext.
/// Example in main.dart: ToastService.setNavigatorKey(navigatorKey);
GlobalKey<NavigatorState>? _globalNavigatorKey;

class ToastService {
  ToastService._internal();
  static final ToastService _instance = ToastService._internal();
  factory ToastService() => _instance;

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _globalNavigatorKey = key;
  }

  final List<_ToastRequest> _queue = [];
  _ToastEntryController? _current;

  /// Show a toast.
  ///
  /// If [context] is null, you must have set [setNavigatorKey] first.
  void show({
    BuildContext? context,
    required String title,
    String? description,
    bool isError = false,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.top,
  }) {
    final ctx = context ?? _globalNavigatorKey?.currentState?.overlay?.context;
    if (ctx == null) return;

    _queue.add(
      _ToastRequest(
        title: title,
        description: description,
        isError: isError,
        icon: icon,
        duration: duration,
        position: position,
      ),
    );
    _pump(ctx);
  }

  void dismiss() {
    _current?.dismiss();
  }

  void _pump(BuildContext context) {
    if (_current != null) return; // already showing one

    if (_queue.isEmpty) return;
    final req = _queue.removeAt(0);

    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;

    _current = _ToastEntryController(
      request: req,
      onClosed: () {
        _current = null;
        if (_queue.isNotEmpty) {
          // show next on the same frame
          WidgetsBinding.instance.addPostFrameCallback((_) => _pump(context));
        }
      },
    );

    overlay.insert(_current!.entry);
    _current!.show();
  }
}

enum ToastPosition { top, bottom }

class _ToastRequest {
  final String title;
  final String? description;
  final bool isError;
  final IconData? icon;
  final Duration duration;
  final ToastPosition position;

  const _ToastRequest({
    required this.title,
    this.description,
    required this.isError,
    this.icon,
    required this.duration,
    required this.position,
  });
}

class _ToastEntryController {
  final _ToastRequest request;
  final VoidCallback onClosed;
  late final OverlayEntry entry;
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final BuildContext _overlayContext;
  bool _dismissed = false;

  _ToastEntryController({
    required this.request,
    required this.onClosed,
  }) {
    entry = OverlayEntry(
      maintainState: false,
      opaque: false,
      builder: (context) {
        _overlayContext = context;
        return _ToastAnimatedBox(
          request: request,
          onTap: dismiss,
          controllerBuilder: (vsync) {
            _controller = AnimationController(
              vsync: vsync,
              duration: const Duration(milliseconds: 180),
              reverseDuration: const Duration(milliseconds: 140),
            );
            final beginOffset = request.position == ToastPosition.top
                ? const Offset(0, -0.08)
                : const Offset(0, 0.08);

            _slide = Tween<Offset>(begin: beginOffset, end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: _controller, curve: Curves.easeOutCubic));

            _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
            return _controller;
          },
          slide: () => _slide,
          fade: () => _fade,
        );
      },
    );
  }

  void show() async {
    // light haptic
    HapticFeedback.selectionClick();
    await _controller.forward();
    // Auto-dismiss after duration unless already dismissed by tap
    if (!_dismissed) {
      await Future.delayed(request.duration);
      if (!_dismissed) dismiss();
    }
  }

  void dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    await _controller.reverse();
    entry.remove();
    onClosed();
  }
}

class _ToastAnimatedBox extends StatefulWidget {
  final _ToastRequest request;
  final AnimationController Function(TickerProvider vsync) controllerBuilder;
  final Animation<Offset> Function() slide;
  final Animation<double> Function() fade;
  final VoidCallback onTap;

  const _ToastAnimatedBox({
    required this.request,
    required this.controllerBuilder,
    required this.slide,
    required this.fade,
    required this.onTap,
  });

  @override
  State<_ToastAnimatedBox> createState() => _ToastAnimatedBoxState();
}

class _ToastAnimatedBoxState extends State<_ToastAnimatedBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = widget.controllerBuilder(this);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final bg = widget.request.isError ? cs.error : cs.primary;
    final onBg = cs.onPrimary; // both success/error are on “primary-like” bg

    final safe = MediaQuery.of(context).padding;
    final isTop = widget.request.position == ToastPosition.top;

    final margin = EdgeInsets.fromLTRB(
        16, isTop ? (safe.top + 12) : 12, 16, isTop ? 12 : (safe.bottom + 12));

    final icon = widget.request.icon ??
        (widget.request.isError
            ? Icons.error_outline
            : Icons.check_circle_outline);

    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
        child: Align(
          alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
          child: Padding(
            padding: margin,
            child: FadeTransition(
              opacity: widget.fade(),
              child: SlideTransition(
                position: widget.slide(),
                child: Semantics(
                  liveRegion: true,
                  label: widget.request.title,
                  hint: widget.request.description ?? '',
                  child: Material(
                    color: bg,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: widget.onTap, // tap to dismiss
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, color: onBg, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.request.title,
                                    style: t.textTheme.bodyLarge?.copyWith(
                                      color: onBg,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if ((widget.request.description ?? '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.request.description!,
                                      style: t.textTheme.bodySmall
                                          ?.copyWith(color: onBg),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
