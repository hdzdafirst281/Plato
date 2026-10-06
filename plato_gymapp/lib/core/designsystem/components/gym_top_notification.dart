import 'dart:async';
import 'dart:collection';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _QueuedTopNotification {
  final VoidCallback run;
  final Completer<bool> completer;
  const _QueuedTopNotification(this.run, this.completer);
}

class GymTopNotification {
  static bool _showing = false;
  static OverlayEntry? _currentEntry;
  static Completer<bool>? _currentCompleter;
  static final Queue<_QueuedTopNotification> _queue =
      Queue<_QueuedTopNotification>();
  static final List<Completer<void>> _idleWaiters = [];

  static bool get isShowing => _showing;

  static Future<void> get whenIdle {
    if (!_showing && _queue.isEmpty) return Future.value();
    final completer = Completer<void>();
    _idleWaiters.add(completer);
    return completer.future;
  }

  static void clear() {
    final entry = _currentEntry;
    _currentEntry = null;
    if (entry?.mounted == true) entry!.remove();
    entry?.dispose();
    if (_currentCompleter?.isCompleted == false) {
      _currentCompleter!.complete(false);
    }
    _currentCompleter = null;
    for (final queued in _queue) {
      if (!queued.completer.isCompleted) queued.completer.complete(false);
    }
    _queue.clear();
    _showing = false;
    _completeIdleWaiters();
  }

  static void _next() {
    _showing = false;
    _currentCompleter = null;
    if (_queue.isNotEmpty) {
      _queue.removeFirst().run();
    } else {
      _completeIdleWaiters();
    }
  }

  static void _completeIdleWaiters() {
    for (final waiter in _idleWaiters) {
      if (!waiter.isCompleted) waiter.complete();
    }
    _idleWaiters.clear();
  }

  /// Completes with true after the banner was actually inserted and dismissed.
  static Future<bool> show(
    BuildContext context, {
    String message = '',
    TextSpan? richMessage,
    Widget? customBody,
    IconData? icon,
    Color? accentColor,
    Duration duration = const Duration(seconds: 4),
    String? semanticLabel,
    bool haptic = true,
    VoidCallback? onPresented,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final completer = Completer<bool>();
    late VoidCallback run;
    run = () => _showNow(
      context,
      message: message,
      richMessage: richMessage,
      customBody: customBody,
      icon: icon,
      accentColor: accentColor,
      duration: duration,
      semanticLabel: semanticLabel,
      haptic: haptic,
      onPresented: onPresented,
      actionLabel: actionLabel,
      onAction: onAction,
      completer: completer,
    );
    if (_showing) {
      _queue.add(_QueuedTopNotification(run, completer));
    } else {
      run();
    }
    return completer.future;
  }

  static void _showNow(
    BuildContext context, {
    required String message,
    required TextSpan? richMessage,
    required Widget? customBody,
    required IconData? icon,
    required Color? accentColor,
    required Duration duration,
    required String? semanticLabel,
    required bool haptic,
    required VoidCallback? onPresented,
    required String? actionLabel,
    required VoidCallback? onAction,
    required Completer<bool> completer,
  }) {
    if (!context.mounted) {
      completer.complete(false);
      _next();
      return;
    }
    _showing = true;
    _currentCompleter = completer;
    OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null &&
        context is StatefulElement &&
        context.state is NavigatorState) {
      overlay = (context.state as NavigatorState).overlay;
    }
    if (overlay == null) {
      completer.complete(false);
      _next();
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
        semanticLabel: semanticLabel,
        haptic: haptic,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: () {
          if (entry.mounted) entry.remove();
          entry.dispose();
          if (_currentEntry == entry) {
            _currentEntry = null;
            if (!completer.isCompleted) completer.complete(true);
            _next();
          }
        },
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);
    onPresented?.call();
  }
}

class _TopNotificationOverlay extends StatefulWidget {
  final String message;
  final TextSpan? richMessage;
  final Widget? customBody;
  final IconData? icon;
  final Color? accentColor;
  final Duration duration;
  final String? semanticLabel;
  final bool haptic;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _TopNotificationOverlay({
    required this.message,
    this.richMessage,
    this.customBody,
    required this.icon,
    required this.accentColor,
    required this.duration,
    required this.semanticLabel,
    required this.haptic,
    required this.actionLabel,
    required this.onAction,
    required this.onDismissed,
  });

  @override
  State<_TopNotificationOverlay> createState() =>
      _TopNotificationOverlayState();
}

class _TopNotificationOverlayState extends State<_TopNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _timer;
  bool _dismissing = false;
  late final bool _reduceMotion;

  @override
  void initState() {
    super.initState();
    _reduceMotion =
        PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    _controller = AnimationController(
      vsync: this,
      duration: _reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 350),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(
      begin: .96,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    if (widget.haptic && !_reduceMotion) {
      HapticFeedback.lightImpact();
    }
    _timer = Timer(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    _timer?.cancel();
    if (!mounted || _reduceMotion) {
      widget.onDismissed();
      return;
    }
    _controller.reverse().whenComplete(widget.onDismissed);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = widget.accentColor ?? colors.primary;
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
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
              child: Semantics(
                container: true,
                liveRegion: true,
                excludeSemantics: widget.semanticLabel != null,
                label: widget.semanticLabel,
                onDismiss: _dismiss,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if ((details.primaryDelta ?? 0) < -2) _dismiss();
                  },
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 260,
                      maxWidth: 440,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: .9),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: accent.withValues(alpha: .4),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (widget.icon != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: .15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        widget.icon,
                                        color: accent,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Expanded(
                                    child:
                                        widget.customBody ??
                                        (widget.richMessage != null
                                            ? RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    color: colors.onSurface,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  children: [
                                                    widget.richMessage!,
                                                  ],
                                                ),
                                              )
                                            : Text(
                                                widget.message,
                                                style: TextStyle(
                                                  color: colors.onSurface,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              )),
                                  ),
                                  IconButton(
                                    tooltip: MaterialLocalizations.of(
                                      context,
                                    ).closeButtonTooltip,
                                    onPressed: _dismiss,
                                    icon: const Icon(Icons.close, size: 20),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              if (widget.actionLabel != null &&
                                  widget.onAction != null)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      widget.onAction!();
                                      _dismiss();
                                    },
                                    child: Text(widget.actionLabel!),
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
      ),
    );
  }
}
