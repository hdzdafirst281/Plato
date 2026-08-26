import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GymTopNotification {
  static void show(
    BuildContext context, {
    String message = '', 
    TextSpan? richMessage, 
    Widget? customBody,
    IconData? icon,
    Color? accentColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    // 1. Dùng maybeOf để tìm Overlay ở các Widget cha một cách an toàn (không crash)
    OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    
    // 2. Nếu không thấy (vì context truyền vào chính là Navigator của GoRouter),
    // chúng ta sẽ lấy Overlay từ State của chính Navigator đó.
    if (overlay == null && context is StatefulElement && context.state is NavigatorState) {
      overlay = (context.state as NavigatorState).overlay;
    }

    // 3. Chốt chặn an toàn cuối cùng
    if (overlay == null) {
      debugPrint("🚨 GymTopNotification: No Overlay found. Cannot show notification.");
      return;
    }

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _TopNotificationOverlay(
        message: message,
        richMessage: richMessage,
        customBody: customBody,
        icon: icon,
        accentColor: accentColor,
        duration: duration,
        onDismissed: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _TopNotificationOverlay extends StatefulWidget {
  final String message;
  final TextSpan? richMessage;
  final Widget? customBody;
  final IconData? icon;
  final Color? accentColor;
  final Duration duration;
  final VoidCallback onDismissed;

  const _TopNotificationOverlay({
    required this.message,
    this.richMessage,
    this.customBody,
    required this.icon,
    required this.accentColor,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_TopNotificationOverlay> createState() => _TopNotificationOverlayState();
}

class _TopNotificationOverlayState extends State<_TopNotificationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _playEnterAnimation();
    _timer = Timer(widget.duration, _dismiss);
  }

  void _playEnterAnimation() {
    _controller.forward();
    
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _dismiss() {
    _timer?.cancel();
    if (mounted) {
      _controller.reverse(from: 1.0).then((_) {
        widget.onDismissed();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Nền mờ ảo: Lấy màu nền cơ bản nhưng tăng độ trong suốt
    final Color glassColor = colorScheme.surface.withValues(alpha: 0.85);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: _offsetAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                behavior: HitTestBehavior.deferToChild,
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! < -2) {
                    _dismiss();
                  }
                },
                child: Container(
                  constraints: const BoxConstraints(minWidth: 260, maxWidth: 400),
                  // Đặt Shadow ở lớp ngoài cùng
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // Hiệu ứng làm mờ background
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: glassColor,
                          borderRadius: BorderRadius.circular(40),
                          // Viền màu nhấn siêu mỏng, giúp tách biệt với background
                          border: Border.all(
                            color: widget.accentColor!.withValues(alpha: 0.4), 
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // NẾU CÓ ICON THÌ MỚI HIỂN THỊ
                            if (widget.icon != null && widget.accentColor != null) ...[
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: widget.accentColor!.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(widget.icon, color: widget.accentColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                            ],
                            
                            Flexible(
                              child: widget.customBody ?? (widget.richMessage != null
                                  ? RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                        ),
                                        children: [widget.richMessage!],
                                      ),
                                      textAlign: TextAlign.left,
                                    )
                                  : Text(
                                      widget.message,
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                      textAlign: TextAlign.left,
                                    )),
                            ),
                            if (widget.icon != null) const SizedBox(width: 4), 
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