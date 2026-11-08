import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_motion.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';

class LanguageSelectionDialog {
  const LanguageSelectionDialog._();

  static Future<AppLocale?> show({
    required BuildContext context,
    bool useRootNavigator = true,
    bool showCloseAction = true,
    Future<bool> Function(AppLocale locale)? onSelected,
  }) async {
    var isApplying = false;
    void close([AppLocale? locale]) =>
        Navigator.of(context, rootNavigator: useRootNavigator).pop(locale);

    final selectedLocale = await GymDialog.showCustom<AppLocale>(
      context: context,
      useRootNavigator: useRootNavigator,
      titleWidget: Row(
        children: [
          Icon(Symbols.language, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.settings.title_language_dialog,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> select(AppLocale locale) async {
            if (isApplying) return;
            setDialogState(() => isApplying = true);
            final applied = await onSelected?.call(locale) ?? true;
            if (!dialogContext.mounted) return;
            if (applied) {
              close(locale);
            } else {
              setDialogState(() => isApplying = false);
            }
          }

          return PopScope(
            canPop: !isApplying,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LanguageRow(
                    locale: AppLocale.vi,
                    name: 'Tiếng Việt',
                    isSelected: LocaleSettings.currentLocale == AppLocale.vi,
                    isApplying: isApplying,
                    onTap: isApplying ? null : () => select(AppLocale.vi),
                  ),
                  const SizedBox(height: 8),
                  _LanguageRow(
                    locale: AppLocale.en,
                    name: 'English',
                    isSelected: LocaleSettings.currentLocale == AppLocale.en,
                    isApplying: isApplying,
                    onTap: isApplying ? null : () => select(AppLocale.en),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: showCloseAction
          ? [
              TextButton(
                onPressed: () {
                  if (!isApplying) close();
                },
                child: Text(
                  t.common.close,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ]
          : const [],
    );

    if (selectedLocale != null) {
      await Future<void>.delayed(GymMotion.content);
    }
    return selectedLocale;
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.locale,
    required this.name,
    required this.isSelected,
    required this.isApplying,
    required this.onTap,
  });

  final AppLocale locale;
  final String name;
  final bool isSelected;
  final bool isApplying;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: name,
      excludeSemantics: true,
      child: AnimatedContainer(
        key: ValueKey('language-option-${locale.languageCode}'),
        duration: GymMotion.reduceMotion(context)
            ? Duration.zero
            : GymMotion.quick,
        curve: GymMotion.stateCurve,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.55)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            trailing: isApplying
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : isSelected
                ? Icon(Symbols.check, color: colorScheme.primary)
                : null,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class LanguageChangeTransition extends StatefulWidget {
  const LanguageChangeTransition({
    super.key,
    required this.trigger,
    required this.child,
  });

  final Object trigger;
  final Widget child;

  @override
  State<LanguageChangeTransition> createState() =>
      _LanguageChangeTransitionState();
}

class _LanguageChangeTransitionState extends State<LanguageChangeTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: GymMotion.screen,
      value: 1,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: GymMotion.enterCurve,
    );
  }

  @override
  void didUpdateWidget(covariant LanguageChangeTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger == widget.trigger) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final value = _animation.value;
        return ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Opacity(
            key: const ValueKey('language-change-opacity'),
            opacity: value,
            child: Transform.translate(
              key: const ValueKey('language-change-transform'),
              offset: Offset(0, 48 * (1 - value)),
              transformHitTests: false,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
