// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
extension GymTimeOfDayFormat on TimeOfDay {
  String formatGym(BuildContext context) {
    final defaultFormat = MaterialLocalizations.of(context).formatTimeOfDay(this, alwaysUse24HourFormat: false);
    if (period == DayPeriod.am && hour == 0) {
      return defaultFormat.replaceFirst('12:', '00:');
    }
    return defaultFormat;
  }
}


// Examples can assume:
// late BuildContext context;

const Duration _kDialogSizeAnimationDuration = Duration(milliseconds: 200);
const Duration _kDialAnimateDuration = Duration(milliseconds: 200);
const double _kTwoPi = 2 * math.pi;
const Duration _kVibrateCommitDelay = Duration(milliseconds: 100);

const double _kTimePickerHeaderLandscapeWidth = 216;
const double _kTimePickerInnerDialOffset = 28;
const double _kTimePickerDialMinRadius = 50;
const double _kTimePickerDialPadding = 28;

/// Interactive input mode of the time picker dialog.
///
/// In [TimePickerEntryMode.dial] mode, a clock dial is displayed and the user
/// taps or drags the time they wish to select. In TimePickerEntryMode.input]
/// mode, [TextField]s are displayed and the user types in the time they wish to
/// select.
///
/// See also:
///
/// * [showGymTimePicker], a function that shows a [TimePickerDialog] and returns
///   the selected time as a [Future].
enum TimePickerEntryMode {
  /// User picks time from a clock dial.
  ///
  /// Can switch to [input] by activating a mode button in the dialog.
  dial,

  /// User can input the time by typing it into text fields.
  ///
  /// Can switch to [dial] by activating a mode button in the dialog.
  input,

  /// User can only pick time from a clock dial.
  ///
  /// There is no user interface to switch to another mode.
  dialOnly,

  /// User can only input the time by typing it into text fields.
  ///
  /// There is no user interface to switch to another mode.
  inputOnly,
}

// Whether the dial-mode time picker is currently selecting the hour or the
// minute.
enum _HourMinuteMode { hour, minute }

// Aspects of _TimePickerModel that can be depended upon.
enum _TimePickerAspect {
  useMaterial3,
  entryMode,
  hourMinuteMode,
  onHourMinuteModeChanged,
  onHourDoubleTapped,
  onMinuteDoubleTapped,
  selectedTime,
  onSelectedTimeChanged,
  orientation,
  theme,
  defaultTheme,
}

class _TimePickerModel extends InheritedModel<_TimePickerAspect> {
  const _TimePickerModel({
    required this.entryMode,
    required this.hourMinuteMode,
    required this.onHourMinuteModeChanged,
    required this.onHourDoubleTapped,
    required this.onMinuteDoubleTapped,
    required this.selectedTime,
    required this.onSelectedTimeChanged,
    required this.useMaterial3,
    required this.orientation,
    required this.theme,
    required this.defaultTheme,
    required super.child,
  });

  final TimePickerEntryMode entryMode;
  final _HourMinuteMode hourMinuteMode;
  final ValueChanged<_HourMinuteMode> onHourMinuteModeChanged;
  final GestureTapCallback onHourDoubleTapped;
  final GestureTapCallback onMinuteDoubleTapped;
  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> onSelectedTimeChanged;
  final bool useMaterial3;
  final Orientation orientation;
  final TimePickerThemeData theme;
  final _TimePickerDefaults defaultTheme;

  static _TimePickerModel of(BuildContext context, [_TimePickerAspect? aspect]) =>
      InheritedModel.inheritFrom<_TimePickerModel>(context, aspect: aspect)!;
  static TimePickerEntryMode entryModeOf(BuildContext context) =>
      of(context, _TimePickerAspect.entryMode).entryMode;
  static _HourMinuteMode hourMinuteModeOf(BuildContext context) =>
      of(context, _TimePickerAspect.hourMinuteMode).hourMinuteMode;
  static TimeOfDay selectedTimeOf(BuildContext context) =>
      of(context, _TimePickerAspect.selectedTime).selectedTime;
  static bool useMaterial3Of(BuildContext context) =>
      of(context, _TimePickerAspect.useMaterial3).useMaterial3;
  static Orientation orientationOf(BuildContext context) =>
      of(context, _TimePickerAspect.orientation).orientation;
  static TimePickerThemeData themeOf(BuildContext context) =>
      of(context, _TimePickerAspect.theme).theme;
  static _TimePickerDefaults defaultThemeOf(BuildContext context) =>
      of(context, _TimePickerAspect.defaultTheme).defaultTheme;

  static void setSelectedTime(BuildContext context, TimeOfDay value) =>
      of(context, _TimePickerAspect.onSelectedTimeChanged).onSelectedTimeChanged(value);
  static void setHourMinuteMode(BuildContext context, _HourMinuteMode value) =>
      of(context, _TimePickerAspect.onHourMinuteModeChanged).onHourMinuteModeChanged(value);

  @override
  bool updateShouldNotifyDependent(
    _TimePickerModel oldWidget,
    Set<_TimePickerAspect> dependencies,
  ) {
    if (useMaterial3 != oldWidget.useMaterial3 &&
        dependencies.contains(_TimePickerAspect.useMaterial3)) {
      return true;
    }
    if (entryMode != oldWidget.entryMode && dependencies.contains(_TimePickerAspect.entryMode)) {
      return true;
    }
    if (hourMinuteMode != oldWidget.hourMinuteMode &&
        dependencies.contains(_TimePickerAspect.hourMinuteMode)) {
      return true;
    }
    if (onHourMinuteModeChanged != oldWidget.onHourMinuteModeChanged &&
        dependencies.contains(_TimePickerAspect.onHourMinuteModeChanged)) {
      return true;
    }
    if (onHourMinuteModeChanged != oldWidget.onHourDoubleTapped &&
        dependencies.contains(_TimePickerAspect.onHourDoubleTapped)) {
      return true;
    }
    if (onHourMinuteModeChanged != oldWidget.onMinuteDoubleTapped &&
        dependencies.contains(_TimePickerAspect.onMinuteDoubleTapped)) {
      return true;
    }
    if (selectedTime != oldWidget.selectedTime &&
        dependencies.contains(_TimePickerAspect.selectedTime)) {
      return true;
    }
    if (onSelectedTimeChanged != oldWidget.onSelectedTimeChanged &&
        dependencies.contains(_TimePickerAspect.onSelectedTimeChanged)) {
      return true;
    }
    if (orientation != oldWidget.orientation &&
        dependencies.contains(_TimePickerAspect.orientation)) {
      return true;
    }
    if (theme != oldWidget.theme && dependencies.contains(_TimePickerAspect.theme)) {
      return true;
    }
    if (defaultTheme != oldWidget.defaultTheme &&
        dependencies.contains(_TimePickerAspect.defaultTheme)) {
      return true;
    }
    return false;
  }

  @override
  bool updateShouldNotify(_TimePickerModel oldWidget) {
    return useMaterial3 != oldWidget.useMaterial3 ||
        entryMode != oldWidget.entryMode ||
        hourMinuteMode != oldWidget.hourMinuteMode ||
        onHourMinuteModeChanged != oldWidget.onHourMinuteModeChanged ||
        onHourDoubleTapped != oldWidget.onHourDoubleTapped ||
        onMinuteDoubleTapped != oldWidget.onMinuteDoubleTapped ||
        selectedTime != oldWidget.selectedTime ||
        onSelectedTimeChanged != oldWidget.onSelectedTimeChanged ||
        orientation != oldWidget.orientation ||
        theme != oldWidget.theme ||
        defaultTheme != oldWidget.defaultTheme;
  }
}

/// The header for the time picker in dial mode.
class _DialTimePickerHeader extends StatelessWidget {
  const _DialTimePickerHeader({required this.helpText});

  final String helpText;

  @override
  Widget build(BuildContext context) {
    assert(_debugDialTimePickerEntryMode(context));
    final TimeOfDayFormat timeOfDayFormat = MaterialLocalizations.of(
      context,
    ).timeOfDayFormat(alwaysUse24HourFormat: false);

    final _TimePickerDefaults defaultTheme = _TimePickerModel.defaultThemeOf(context);
    final Orientation orientation = _TimePickerModel.orientationOf(context);
    final double dayPeriodHeight = orientation == Orientation.portrait
        ? defaultTheme.dayPeriodPortraitSize.height
        : defaultTheme.dayPeriodLandscapeSize.height;
    final double minInteractiveVerticalPadding = orientation == Orientation.portrait
        ? math.max(0, 2 * kMinInteractiveDimension - dayPeriodHeight)
        : math.max(0, kMinInteractiveDimension - dayPeriodHeight);

    final RenderObjectWidget orientationSpecificHeader = switch (orientation) {
      Orientation.portrait => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.only(
              bottom:
                  (_TimePickerModel.useMaterial3Of(context) ? 20 : 24) -
                  minInteractiveVerticalPadding / 2,
            ),
            child: Text(
              helpText,
              style: _TimePickerModel.themeOf(context).helpTextStyle ?? defaultTheme.helpTextStyle,
            ),
          ),
          Row(
            textDirection: timeOfDayFormat == TimeOfDayFormat.a_space_h_colon_mm
                ? TextDirection.rtl
                : TextDirection.ltr,
            spacing: 12,
            children: <Widget>[
              Expanded(
                child: Row(
                  // Hour/minutes should not change positions in RTL locales.
                  textDirection: TextDirection.ltr,
                  children: <Widget>[
                    const Expanded(child: _DialHourControl()),
                    _TimeSelectorSeparator(timeOfDayFormat: timeOfDayFormat),
                    const Expanded(child: _DialMinuteControl()),
                  ],
                ),
              ),
              const _DayPeriodControl(),
            ],
          ),
        ],
      ),
      Orientation.landscape => SizedBox(
        width: _kTimePickerHeaderLandscapeWidth,
        child: Stack(
          children: <Widget>[
            Text(
              helpText,
              style: _TimePickerModel.themeOf(context).helpTextStyle ?? defaultTheme.helpTextStyle,
            ),
            Column(
              verticalDirection: timeOfDayFormat == TimeOfDayFormat.a_space_h_colon_mm
                  ? VerticalDirection.up
                  : VerticalDirection.down,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: math.max(0, 16 - minInteractiveVerticalPadding / 2),
              children: <Widget>[
                Row(
                  // Hour/minutes should not change positions in RTL locales.
                  textDirection: TextDirection.ltr,
                  children: <Widget>[
                    const Expanded(child: _DialHourControl()),
                    _TimeSelectorSeparator(timeOfDayFormat: timeOfDayFormat),
                    const Expanded(child: _DialMinuteControl()),
                  ],
                ),
                const _DayPeriodControl(),
              ],
            ),
          ],
        ),
      ),
    };

    return Semantics(
      label: MaterialLocalizations.of(context).formatTimeOfDay(
        _TimePickerModel.selectedTimeOf(context),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      ),
      child: orientationSpecificHeader,
    );
  }
}

/// The control label for the time selector in dial mode.
class _DialTimeSelectorControl extends StatelessWidget {
  const _DialTimeSelectorControl({
    required this.text,
    required this.onTap,
    required this.onDoubleTap,
    required this.isSelected,
  });

  final String text;
  final GestureTapCallback onTap;
  final GestureTapCallback onDoubleTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    assert(_debugDialTimePickerEntryMode(context));
    final TimePickerThemeData timePickerTheme = _TimePickerModel.themeOf(context);
    final _TimePickerDefaults defaultTheme = _TimePickerModel.defaultThemeOf(context);
    final Color backgroundColor = timePickerTheme.hourMinuteColor ?? defaultTheme.hourMinuteColor;
    final ShapeBorder shape = timePickerTheme.hourMinuteShape ?? defaultTheme.hourMinuteShape;

    final states = <WidgetState>{if (isSelected) WidgetState.selected};
    final Color effectiveTextColor = WidgetStateProperty.resolveAs<Color>(
      _TimePickerModel.themeOf(context).hourMinuteTextColor ??
          _TimePickerModel.defaultThemeOf(context).hourMinuteTextColor,
      states,
    );
    final TextStyle effectiveStyle = WidgetStateProperty.resolveAs<TextStyle>(
      timePickerTheme.hourMinuteTextStyle ?? defaultTheme.hourMinuteTextStyle,
      states,
    ).copyWith(color: effectiveTextColor);

    return SizedBox(
      height: defaultTheme.hourMinuteSize.height,
      child: Material(
        color: WidgetStateProperty.resolveAs(backgroundColor, states),
        clipBehavior: Clip.antiAlias,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          onDoubleTap: isSelected ? onDoubleTap : null,
          child: Center(
            child: Text(text, style: effectiveStyle, textScaler: TextScaler.noScaling),
          ),
        ),
      ),
    );
  }
}

/// Displays the hour fragment in dial mode.
///
/// When tapped changes time picker dial mode to [_HourMinuteMode.hour].
class _DialHourControl extends StatelessWidget {
  const _DialHourControl();

  @override
  Widget build(BuildContext context) {
    assert(_debugDialTimePickerEntryMode(context));
    final TimeOfDay selectedTime = _TimePickerModel.selectedTimeOf(context);
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    String formatHour(TimeOfDay time) {
      int displayNum = time.hourOfPeriod;
      final bool isAm = time.period == DayPeriod.am;
      if (isAm) {
        return displayNum == 12 ? '00' : displayNum.toString().padLeft(2, '0');
      } else {
        return displayNum.toString().padLeft(2, '0');
      }
    }

    final String formattedHour = formatHour(selectedTime);

    TimeOfDay hoursFromSelected(int hoursToAdd) {
      // Cycle 1 through 12 without changing day period.
      final int periodOffset = selectedTime.periodOffset;
      final int hours = selectedTime.hourOfPeriod;
      return selectedTime.replacing(
        hour: periodOffset + (hours + hoursToAdd) % TimeOfDay.hoursPerPeriod,
      );
    }

    final TimeOfDay nextHour = hoursFromSelected(1);
    final String formattedNextHour = formatHour(nextHour);
    final TimeOfDay previousHour = hoursFromSelected(-1);
    final String formattedPreviousHour = formatHour(previousHour);

    return Semantics(
      value: '${localizations.timePickerHourModeAnnouncement} $formattedHour',
      excludeSemantics: true,
      increasedValue: formattedNextHour,
      onIncrease: () {
        _TimePickerModel.setSelectedTime(context, nextHour);
      },
      decreasedValue: formattedPreviousHour,
      onDecrease: () {
        _TimePickerModel.setSelectedTime(context, previousHour);
      },
      child: _DialTimeSelectorControl(
        isSelected: _TimePickerModel.hourMinuteModeOf(context) == _HourMinuteMode.hour,
        text: formattedHour,
        onTap: () => _TimePickerModel.setHourMinuteMode(context, _HourMinuteMode.hour),
        onDoubleTap: _TimePickerModel.of(
          context,
          _TimePickerAspect.onHourDoubleTapped,
        ).onHourDoubleTapped,
      ),
    );
  }
}

/// A passive fragment showing a string value.
///
/// Used to display the appropriate separator between the input fields.
class _TimeSelectorSeparator extends StatelessWidget {
  const _TimeSelectorSeparator({required this.timeOfDayFormat});

  final TimeOfDayFormat timeOfDayFormat;

  String _timeSelectorSeparatorValue(TimeOfDayFormat timeOfDayFormat) {
    switch (timeOfDayFormat) {
      case TimeOfDayFormat.h_colon_mm_space_a:
      case TimeOfDayFormat.a_space_h_colon_mm:
      case TimeOfDayFormat.H_colon_mm:
      case TimeOfDayFormat.HH_colon_mm:
        return ':';
      case TimeOfDayFormat.HH_dot_mm:
        return '.';
      case TimeOfDayFormat.frenchCanadian:
        return 'h';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TimePickerThemeData timePickerTheme = TimePickerTheme.of(context);
    final _TimePickerDefaults defaultTheme = theme.useMaterial3
        ? _TimePickerDefaultsM3(context)
        : _TimePickerDefaultsM2(context);
    final states = <WidgetState>{};

    final Color effectiveTextColor = WidgetStateProperty.resolveAs<Color>(
      timePickerTheme.timeSelectorSeparatorColor?.resolve(states) ??
          timePickerTheme.hourMinuteTextColor ??
          defaultTheme.timeSelectorSeparatorColor?.resolve(states) ??
          defaultTheme.hourMinuteTextColor,
      states,
    );
    final TextStyle effectiveStyle = WidgetStateProperty.resolveAs<TextStyle>(
      timePickerTheme.timeSelectorSeparatorTextStyle?.resolve(states) ??
          timePickerTheme.hourMinuteTextStyle ??
          defaultTheme.timeSelectorSeparatorTextStyle?.resolve(states) ??
          defaultTheme.hourMinuteTextStyle,
      states,
    ).copyWith(color: effectiveTextColor, height: 1.0);

    final double height;
    switch (_TimePickerModel.entryModeOf(context)) {
      case TimePickerEntryMode.dial:
      case TimePickerEntryMode.dialOnly:
        height = defaultTheme.hourMinuteSize.height;
      case TimePickerEntryMode.input:
      case TimePickerEntryMode.inputOnly:
        height = defaultTheme.hourMinuteInputSize.height;
    }

    return ExcludeSemantics(
      child: SizedBox(
        width: timeOfDayFormat == TimeOfDayFormat.frenchCanadian ? 36 : 24,
        height: height,
        child: Center(
          child: Text(
            _timeSelectorSeparatorValue(timeOfDayFormat),
            style: effectiveStyle,
            textScaler: TextScaler.noScaling,
          ),
        ),
      ),
    );
  }
}

/// Displays the minute fragment in dial mode.
///
/// When tapped changes time picker dial mode to [_HourMinuteMode.minute].
class _DialMinuteControl extends StatelessWidget {
  const _DialMinuteControl();

  @override
  Widget build(BuildContext context) {
    assert(_debugDialTimePickerEntryMode(context));
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final TimeOfDay selectedTime = _TimePickerModel.selectedTimeOf(context);
    final String formattedMinute = localizations.formatMinute(selectedTime);
    final TimeOfDay nextMinute = selectedTime.replacing(
      minute: (selectedTime.minute + 1) % TimeOfDay.minutesPerHour,
    );
    final String formattedNextMinute = localizations.formatMinute(nextMinute);
    final TimeOfDay previousMinute = selectedTime.replacing(
      minute: (selectedTime.minute - 1) % TimeOfDay.minutesPerHour,
    );
    final String formattedPreviousMinute = localizations.formatMinute(previousMinute);

    return Semantics(
      excludeSemantics: true,
      value: '${localizations.timePickerMinuteModeAnnouncement} $formattedMinute',
      increasedValue: formattedNextMinute,
      onIncrease: () {
        _TimePickerModel.setSelectedTime(context, nextMinute);
      },
      decreasedValue: formattedPreviousMinute,
      onDecrease: () {
        _TimePickerModel.setSelectedTime(context, previousMinute);
      },
      child: _DialTimeSelectorControl(
        isSelected: _TimePickerModel.hourMinuteModeOf(context) == _HourMinuteMode.minute,
        text: formattedMinute,
        onTap: () => _TimePickerModel.setHourMinuteMode(context, _HourMinuteMode.minute),
        onDoubleTap: _TimePickerModel.of(
          context,
          _TimePickerAspect.onMinuteDoubleTapped,
        ).onMinuteDoubleTapped,
      ),
    );
  }
}

/// Displays the am/pm fragment and provides controls for switching between am
/// and pm.
class _DayPeriodControl extends StatelessWidget {
  const _DayPeriodControl({this.onPeriodChanged});

  final ValueChanged<TimeOfDay>? onPeriodChanged;

  void _togglePeriod(BuildContext context) {
    final TimeOfDay selectedTime = _TimePickerModel.selectedTimeOf(context);
    final int newHour = (selectedTime.hour + TimeOfDay.hoursPerPeriod) % TimeOfDay.hoursPerDay;
    final TimeOfDay newTime = selectedTime.replacing(hour: newHour);
    if (onPeriodChanged != null) {
      onPeriodChanged!(newTime);
    } else {
      _TimePickerModel.setSelectedTime(context, newTime);
    }
  }

  void _setAm(BuildContext context) {
    final TimeOfDay selectedTime = _TimePickerModel.selectedTimeOf(context);
    if (selectedTime.period == DayPeriod.am) {
      return;
    }
    _togglePeriod(context);
  }

  void _setPm(BuildContext context) {
    final TimeOfDay selectedTime = _TimePickerModel.selectedTimeOf(context);
    if (selectedTime.period == DayPeriod.pm) {
      return;
    }
    _togglePeriod(context);
  }

  @override
  Widget build(BuildContext context) {
    final TimePickerThemeData timePickerTheme = _TimePickerModel.themeOf(context);
    final _TimePickerDefaults defaultTheme = _TimePickerModel.defaultThemeOf(context);
    final TimeOfDay selectedTime = _TimePickerModel.selectedTimeOf(context);
    final amSelected = selectedTime.period == DayPeriod.am;
    final bool pmSelected = !amSelected;
    final BorderSide resolvedSide =
        timePickerTheme.dayPeriodBorderSide ?? defaultTheme.dayPeriodBorderSide;
    final OutlinedBorder resolvedShape =
        (timePickerTheme.dayPeriodShape ?? defaultTheme.dayPeriodShape).copyWith(
          side: resolvedSide,
        );

    Size dayPeriodSize;
    final Orientation orientation;
    switch (_TimePickerModel.entryModeOf(context)) {
      case TimePickerEntryMode.dial:
      case TimePickerEntryMode.dialOnly:
        orientation = _TimePickerModel.orientationOf(context);
        dayPeriodSize = switch (orientation) {
          Orientation.portrait => defaultTheme.dayPeriodPortraitSize,
          Orientation.landscape => defaultTheme.dayPeriodLandscapeSize,
        };
      case TimePickerEntryMode.input:
      case TimePickerEntryMode.inputOnly:
        orientation = Orientation.portrait;
        dayPeriodSize = defaultTheme.dayPeriodInputSize;
    }

    var amShape = resolvedShape;
    var pmShape = resolvedShape;
    final bool hasRoundedBorder =
        resolvedShape is RoundedRectangleBorder && resolvedShape.borderRadius is BorderRadius;

    // In order to respect Material touch target guidelines, the Semantics for
    // AM and PM buttons needs to expand out of the bounds of the buttons
    // (Similarly to Google Agenda).
    // To achieve this, instead of using a parent Material which clips
    // the Semantics, each button should manage its own shape.
    // The logic below "cuts" the given period selector shape in two parts,
    // one for the AM button, the other for the PM button. Each sub-shape
    // is obtained by removing some rounded corners from the original shape.
    switch (orientation) {
      case Orientation.portrait:
        if (hasRoundedBorder) {
          final borderRadius = resolvedShape.borderRadius as BorderRadius;
          amShape = resolvedShape.copyWith(
            borderRadius: BorderRadius.only(
              topLeft: borderRadius.topLeft,
              topRight: borderRadius.topRight,
            ),
          );
          pmShape = resolvedShape.copyWith(
            borderRadius: BorderRadius.only(
              bottomLeft: borderRadius.bottomLeft,
              bottomRight: borderRadius.bottomRight,
            ),
          );
        }

        final minInteractiveSize = Size(
          dayPeriodSize.width,
          math.max(dayPeriodSize.height, 2 * kMinInteractiveDimension),
        );

        final Widget amButton = _AmPmButton(
          selected: amSelected,
          onPressed: () => _setAm(context),
          label: t.common.am,
          padding: EdgeInsets.only(top: (minInteractiveSize.height - dayPeriodSize.height) / 2),
          shape: amShape,
        );

        final Widget pmButton = _AmPmButton(
          selected: pmSelected,
          onPressed: () => _setPm(context),
          label: t.common.pm,
          padding: EdgeInsets.only(bottom: (minInteractiveSize.height - dayPeriodSize.height) / 2),
          shape: pmShape,
        );

        return _DayPeriodInputPadding(
          minSize: minInteractiveSize,
          orientation: orientation,
          child: SizedBox.fromSize(
            size: minInteractiveSize,
            child: Center(
              child: SizedBox(
                width: dayPeriodSize.width,
                height: dayPeriodSize.height,
                child: Column(
                  children: <Widget>[
                    Expanded(child: amButton),
                    const SizedBox(height: 8),
                    Expanded(child: pmButton),
                  ],
                ),
              ),
            ),
          ),
        );
      case Orientation.landscape:
        if (hasRoundedBorder) {
          final borderRadius = resolvedShape.borderRadius as BorderRadius;
          amShape = resolvedShape.copyWith(
            borderRadius: BorderRadius.only(
              topLeft: borderRadius.topLeft,
              bottomLeft: borderRadius.bottomLeft,
            ),
          );
          pmShape = resolvedShape.copyWith(
            borderRadius: BorderRadius.only(
              topRight: borderRadius.topRight,
              bottomRight: borderRadius.bottomRight,
            ),
          );
        }

        final minInteractiveSize = Size(
          dayPeriodSize.width,
          math.max(dayPeriodSize.height, kMinInteractiveDimension),
        );

        final Widget amButton = _AmPmButton(
          selected: amSelected,
          onPressed: () => _setAm(context),
          label: t.common.am,
          padding: EdgeInsets.symmetric(
            vertical: (minInteractiveSize.height - dayPeriodSize.height) / 2,
          ),
          shape: amShape,
        );

        final Widget pmButton = _AmPmButton(
          selected: pmSelected,
          onPressed: () => _setPm(context),
          label: t.common.pm,
          padding: EdgeInsets.symmetric(
            vertical: (minInteractiveSize.height - dayPeriodSize.height) / 2,
          ),
          shape: pmShape,
        );

        return _DayPeriodInputPadding(
          minSize: minInteractiveSize,
          orientation: orientation,
          child: SizedBox(
            height: minInteractiveSize.height,
            child: Center(
              child: SizedBox(
                width: dayPeriodSize.width,
                height: dayPeriodSize.height,
                child: Row(
                  children: <Widget>[
                    Expanded(child: amButton),
                    const SizedBox(width: 8),
                    Expanded(child: pmButton),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }
}

class _AmPmButton extends StatelessWidget {
  const _AmPmButton({
    required this.onPressed,
    required this.selected,
    required this.label,
    required this.padding,
    required this.shape,
  });

  final bool selected;
  final VoidCallback onPressed;
  final String label;
  final EdgeInsets padding;
  final OutlinedBorder shape;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(color: selected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A widget to pad the area around the [_DayPeriodControl]'s inner [Material].
class _DayPeriodInputPadding extends SingleChildRenderObjectWidget {
  const _DayPeriodInputPadding({
    required Widget super.child,
    required this.minSize,
    required this.orientation,
  });

  final Size minSize;
  final Orientation orientation;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderInputPadding(minSize, orientation);
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderInputPadding renderObject) {
    renderObject
      ..minSize = minSize
      ..orientation = orientation;
  }
}

class _RenderInputPadding extends RenderShiftedBox {
  _RenderInputPadding(this._minSize, this._orientation, [RenderBox? child]) : super(child);

  Size get minSize => _minSize;
  Size _minSize;
  set minSize(Size value) {
    if (_minSize == value) {
      return;
    }
    _minSize = value;
    markNeedsLayout();
  }

  Orientation get orientation => _orientation;
  Orientation _orientation;
  set orientation(Orientation value) {
    if (_orientation == value) {
      return;
    }
    _orientation = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null) {
      return math.max(child!.getMinIntrinsicWidth(height), minSize.width);
    }
    return 0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null) {
      return math.max(child!.getMinIntrinsicHeight(width), minSize.height);
    }
    return 0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null) {
      return math.max(child!.getMaxIntrinsicWidth(height), minSize.width);
    }
    return 0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null) {
      return math.max(child!.getMaxIntrinsicHeight(width), minSize.height);
    }
    return 0;
  }

  Size _computeSize({required BoxConstraints constraints, required ChildLayouter layoutChild}) {
    if (child != null) {
      final Size childSize = layoutChild(child!, constraints);
      final double width = math.max(childSize.width, minSize.width);
      final double height = math.max(childSize.height, minSize.height);
      return constraints.constrain(Size(width, height));
    }
    return Size.zero;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _computeSize(constraints: constraints, layoutChild: ChildLayoutHelper.dryLayoutChild);
  }

  @override
  double? computeDryBaseline(covariant BoxConstraints constraints, TextBaseline baseline) {
    final RenderBox? child = this.child;
    if (child == null) {
      return null;
    }
    final double? result = child.getDryBaseline(constraints, baseline);
    if (result == null) {
      return null;
    }
    // Calculate the size and child offset using the same logic as performLayout
    final Size drySize = getDryLayout(constraints);
    final Size childSize = child.getDryLayout(constraints);
    final Offset childOffset = Alignment.center.alongOffset(drySize - childSize as Offset);
    return result + childOffset.dy;
  }

  @override
  void performLayout() {
    size = _computeSize(constraints: constraints, layoutChild: ChildLayoutHelper.layoutChild);
    if (child != null) {
      final childParentData = child!.parentData! as BoxParentData;
      childParentData.offset = Alignment.center.alongOffset(size - child!.size as Offset);
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) {
      return true;
    }

    if (position.dx < 0 ||
        position.dx > math.max(child!.size.width, minSize.width) ||
        position.dy < 0 ||
        position.dy > math.max(child!.size.height, minSize.height)) {
      return false;
    }

    Offset newPosition = child!.size.center(Offset.zero);
    newPosition += switch (orientation) {
      Orientation.portrait when position.dy > newPosition.dy => const Offset(0, 1),
      Orientation.landscape when position.dx > newPosition.dx => const Offset(1, 0),
      Orientation.portrait => const Offset(0, -1),
      Orientation.landscape => const Offset(-1, 0),
    };

    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(newPosition),
      position: newPosition,
      hitTest: (BoxHitTestResult result, Offset position) {
        assert(position == newPosition);
        return child!.hitTest(result, position: newPosition);
      },
    );
  }
}

class _TappableLabel {
  _TappableLabel({
    required this.value,
    required this.inner,
    required this.painter,
    required this.onTap,
  });

  /// The value this label is displaying.
  final int value;

  /// This value is part of the "inner" ring of values on the dial, used for 24
  /// hour input.
  final bool inner;

  /// Paints the text of the label.
  final TextPainter painter;

  /// Called when a tap gesture is detected on the label.
  final VoidCallback onTap;
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.primaryLabels,
    required this.selectedLabels,
    required this.backgroundColor,
    required this.handColor,
    required this.handWidth,
    required this.dotColor,
    required this.dotRadius,
    required this.centerRadius,
    required this.theta,
    required this.radius,
    required this.textDirection,
    required this.selectedValue,
  }) : super(repaint: PaintingBinding.instance.systemFonts);

  final List<_TappableLabel> primaryLabels;
  final List<_TappableLabel> selectedLabels;
  final Color backgroundColor;
  final Color handColor;
  final double handWidth;
  final Color dotColor;
  final double dotRadius;
  final double centerRadius;
  final double theta;
  final double radius;
  final TextDirection textDirection;
  final int selectedValue;

  void dispose() {
    for (final _TappableLabel label in primaryLabels) {
      label.painter.dispose();
    }
    for (final _TappableLabel label in selectedLabels) {
      label.painter.dispose();
    }
    primaryLabels.clear();
    selectedLabels.clear();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double dialRadius = clampDouble(
      size.shortestSide / 2,
      _kTimePickerDialMinRadius + dotRadius,
      double.infinity,
    );
    final double labelRadius = clampDouble(
      dialRadius - _kTimePickerDialPadding,
      _kTimePickerDialMinRadius,
      double.infinity,
    );
    final double innerLabelRadius = clampDouble(
      labelRadius - _kTimePickerInnerDialOffset,
      0,
      double.infinity,
    );
    final double handleRadius = clampDouble(
      labelRadius - (radius < 0.5 ? 1 : 0) * (labelRadius - innerLabelRadius),
      _kTimePickerDialMinRadius,
      double.infinity,
    );
    final center = Offset(size.width / 2, size.height / 2);
    final centerPoint = center;
    canvas.drawCircle(centerPoint, dialRadius, Paint()..color = backgroundColor);

    Offset getOffsetForTheta(double theta, double radius) {
      return center + Offset(radius * math.cos(theta), -radius * math.sin(theta));
    }

    void paintLabels(List<_TappableLabel> labels, double radius) {
      if (labels.isEmpty) {
        return;
      }
      final double labelThetaIncrement = -_kTwoPi / labels.length;
      double labelTheta = math.pi / 2;

      for (final label in labels) {
        final TextPainter labelPainter = label.painter;
        final labelOffset = Offset(-labelPainter.width / 2, -labelPainter.height / 2);
        labelPainter.paint(canvas, getOffsetForTheta(labelTheta, radius) + labelOffset);
        labelTheta += labelThetaIncrement;
      }
    }

    void paintInnerOuterLabels(List<_TappableLabel>? labels) {
      if (labels == null) {
        return;
      }

      paintLabels(labels.where((_TappableLabel label) => !label.inner).toList(), labelRadius);
      paintLabels(labels.where((_TappableLabel label) => label.inner).toList(), innerLabelRadius);
    }

    paintInnerOuterLabels(primaryLabels);

    final selectorPaint = Paint()..color = handColor;
    final Offset focusedPoint = getOffsetForTheta(theta, handleRadius);
    canvas.drawCircle(centerPoint, centerRadius, selectorPaint);
    canvas.drawCircle(focusedPoint, dotRadius, selectorPaint);
    selectorPaint.strokeWidth = handWidth;
    canvas.drawLine(centerPoint, focusedPoint, selectorPaint);

    // Add a dot inside the selector but only when it isn't over the labels.
    // This checks that the selector's theta is between two labels. A remainder
    // between 0.1 and 0.45 indicates that the selector is roughly not above any
    // labels. The values were derived by manually testing the dial.
    final double labelThetaIncrement = -_kTwoPi / primaryLabels.length;
    if (theta % labelThetaIncrement > 0.1 && theta % labelThetaIncrement < 0.45) {
      canvas.drawCircle(focusedPoint, 2, selectorPaint..color = dotColor);
    }

    final focusedRect = Rect.fromCircle(center: focusedPoint, radius: dotRadius);
    canvas
      ..save()
      ..clipPath(Path()..addOval(focusedRect));
    paintInnerOuterLabels(selectedLabels);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DialPainter oldPainter) {
    return oldPainter.primaryLabels != primaryLabels ||
        oldPainter.selectedLabels != selectedLabels ||
        oldPainter.backgroundColor != backgroundColor ||
        oldPainter.handColor != handColor ||
        oldPainter.theta != theta;
  }
}
class _Dial extends StatefulWidget {
  const _Dial({
    required this.selectedTime,
    required this.hourMinuteMode,
    required this.onChanged,
    required this.onHourSelected,
  });

  final TimeOfDay selectedTime;
  final _HourMinuteMode hourMinuteMode;
  final ValueChanged<TimeOfDay>? onChanged;
  final VoidCallback? onHourSelected;

  @override
  _DialState createState() => _DialState();
}

class _DialState extends State<_Dial> with SingleTickerProviderStateMixin {
  late ThemeData themeData;
  late MaterialLocalizations localizations;
  _DialPainter? painter;
  late AnimationController _animationController;
  late Tween<double> _thetaTween;
  late Animation<double> _theta;
  late Tween<double> _radiusTween;
  late Animation<double> _radius;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: _kDialAnimateDuration, vsync: this);
    _thetaTween = Tween<double>(begin: _getThetaForTime(widget.selectedTime));
    _radiusTween = Tween<double>(begin: _getRadiusForTime(widget.selectedTime));
    _theta = _animationController.drive(CurveTween(curve: standardEasing)).drive(_thetaTween)
      ..addListener(
        () => setState(() {
          /* _theta.value has changed */
        }),
      );
    _radius = _animationController.drive(CurveTween(curve: standardEasing)).drive(_radiusTween)
      ..addListener(
        () => setState(() {
          /* _radius.value has changed */
        }),
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(debugCheckHasMediaQuery(context));
    themeData = Theme.of(context);
    localizations = MaterialLocalizations.of(context);
  }

  @override
  void didUpdateWidget(_Dial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hourMinuteMode != oldWidget.hourMinuteMode ||
        widget.selectedTime != oldWidget.selectedTime) {
      if (!_dragging) {
        _animateTo(_getThetaForTime(widget.selectedTime), _getRadiusForTime(widget.selectedTime));
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    painter?.dispose();
    super.dispose();
  }

  static double _nearest(double target, double a, double b) {
    return ((target - a).abs() < (target - b).abs()) ? a : b;
  }

  void _animateTo(double targetTheta, double targetRadius) {
    void animateToValue({
      required double target,
      required Animation<double> animation,
      required Tween<double> tween,
      required AnimationController controller,
      required double min,
      required double max,
    }) {
      double beginValue = _nearest(target, animation.value, max);
      beginValue = _nearest(target, beginValue, min);
      tween
        ..begin = beginValue
        ..end = target;
      controller
        ..value = 0
        ..forward();
    }

    animateToValue(
      target: targetTheta,
      animation: _theta,
      tween: _thetaTween,
      controller: _animationController,
      min: _theta.value - _kTwoPi,
      max: _theta.value + _kTwoPi,
    );
    animateToValue(
      target: targetRadius,
      animation: _radius,
      tween: _radiusTween,
      controller: _animationController,
      min: 0,
      max: 1,
    );
  }

  double _getRadiusForTime(TimeOfDay time) {
    return 1;
  }

  double _getThetaForTime(TimeOfDay time) {
    final double fraction = switch (widget.hourMinuteMode) {
      _HourMinuteMode.hour => (time.hour / TimeOfDay.hoursPerPeriod) % TimeOfDay.hoursPerPeriod,
      _HourMinuteMode.minute => (time.minute / TimeOfDay.minutesPerHour) % TimeOfDay.minutesPerHour,
    };
    return (math.pi / 2 - fraction * _kTwoPi) % _kTwoPi;
  }

  TimeOfDay _getTimeForTheta(double theta, {bool roundMinutes = false, required double radius}) {
    final double fraction = (0.25 - (theta % _kTwoPi) / _kTwoPi) % 1;
    switch (widget.hourMinuteMode) {
      case _HourMinuteMode.hour:
        int newHour = (fraction * TimeOfDay.hoursPerPeriod).round() % TimeOfDay.hoursPerPeriod;
        newHour = newHour + widget.selectedTime.periodOffset;
        return widget.selectedTime.replacing(hour: newHour);
      case _HourMinuteMode.minute:
        int minute = (fraction * TimeOfDay.minutesPerHour).round() % TimeOfDay.minutesPerHour;
        if (roundMinutes) {
          // Round the minutes to nearest 5 minute interval.
          minute = ((minute + 2) ~/ 5) * 5 % TimeOfDay.minutesPerHour;
        }
        return widget.selectedTime.replacing(minute: minute);
    }
  }

  TimeOfDay _notifyOnChangedIfNeeded({bool roundMinutes = false}) {
    final TimeOfDay current = _getTimeForTheta(
      _theta.value,
      roundMinutes: roundMinutes,
      radius: _radius.value,
    );
    if (widget.onChanged == null) {
      return current;
    }
    if (current != widget.selectedTime) {
      widget.onChanged!(current);
    }
    return current;
  }

  void _updateThetaForPan({bool roundMinutes = false}) {
    setState(() {
      final Offset offset = _position! - _center!;
      final double labelRadius = _dialSize!.shortestSide / 2 - _kTimePickerDialPadding;
      final double innerRadius = labelRadius - _kTimePickerInnerDialOffset;
      double angle = (math.atan2(offset.dx, offset.dy) - math.pi / 2) % _kTwoPi;
      final double radius = clampDouble(
        (offset.distance - innerRadius) / _kTimePickerInnerDialOffset,
        0,
        1,
      );
      if (roundMinutes) {
        angle = _getThetaForTime(
          _getTimeForTheta(angle, roundMinutes: roundMinutes, radius: radius),
        );
      }
      // The controller doesn't animate during the pan gesture.
      _thetaTween
        ..begin = angle
        ..end = angle;
      _radiusTween
        ..begin = radius
        ..end = radius;
    });
  }

  Offset? _position;
  Offset? _center;
  Size? _dialSize;

  void _handlePanStart(DragStartDetails details) {
    assert(!_dragging);
    _dragging = true;
    final box = context.findRenderObject()! as RenderBox;
    _position = box.globalToLocal(details.globalPosition);
    _dialSize = box.size;
    _center = _dialSize!.center(Offset.zero);
    _updateThetaForPan();
    _notifyOnChangedIfNeeded();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _position = _position! + details.delta;
    _updateThetaForPan();
    _notifyOnChangedIfNeeded();
  }

  void _handlePanEnd(DragEndDetails details) {
    assert(_dragging);
    _dragging = false;
    _position = null;
    _center = null;
    _dialSize = null;
    _animateTo(_getThetaForTime(widget.selectedTime), _getRadiusForTime(widget.selectedTime));
    if (widget.hourMinuteMode == _HourMinuteMode.hour) {
      widget.onHourSelected?.call();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    final box = context.findRenderObject()! as RenderBox;
    _position = box.globalToLocal(details.globalPosition);
    _center = box.size.center(Offset.zero);
    _dialSize = box.size;
    _updateThetaForPan(roundMinutes: true);
    _notifyOnChangedIfNeeded(roundMinutes: true);
    if (widget.hourMinuteMode == _HourMinuteMode.hour) {
      widget.onHourSelected?.call();
    }
    final TimeOfDay time = _getTimeForTheta(
      _theta.value,
      roundMinutes: true,
      radius: _radius.value,
    );
    _animateTo(_getThetaForTime(time), _getRadiusForTime(time));
    _dragging = false;
    _position = null;
    _center = null;
    _dialSize = null;
  }

  void _selectHour(int hour) {
    final TimeOfDay time;

    TimeOfDay getAmPmTime() {
      return switch (widget.selectedTime.period) {
        DayPeriod.am => TimeOfDay(hour: hour == 12 ? 0 : hour, minute: widget.selectedTime.minute),
        DayPeriod.pm => TimeOfDay(
          hour: hour == 12 ? 0 : hour + TimeOfDay.hoursPerPeriod,
          minute: widget.selectedTime.minute,
        ),
      };
    }

    switch (widget.hourMinuteMode) {
      case _HourMinuteMode.hour:
        time = getAmPmTime();
      case _HourMinuteMode.minute:
        time = getAmPmTime();
    }
    final double angle = _getThetaForTime(time);
    _thetaTween
      ..begin = angle
      ..end = angle;
    _notifyOnChangedIfNeeded();
  }

  void _selectMinute(int minute) {
    final time = TimeOfDay(hour: widget.selectedTime.hour, minute: minute);
    final double angle = _getThetaForTime(time);
    _thetaTween
      ..begin = angle
      ..end = angle;
    _notifyOnChangedIfNeeded();
  }

  static const List<TimeOfDay> _amHours = <TimeOfDay>[
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 1, minute: 0),
    TimeOfDay(hour: 2, minute: 0),
    TimeOfDay(hour: 3, minute: 0),
    TimeOfDay(hour: 4, minute: 0),
    TimeOfDay(hour: 5, minute: 0),
    TimeOfDay(hour: 6, minute: 0),
    TimeOfDay(hour: 7, minute: 0),
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 11, minute: 0),
  ];



  _TappableLabel _buildTappableLabel({
    required TextStyle? textStyle,
    required int selectedValue,
    required int value,
    required bool inner,
    required String label,
    required VoidCallback onTap,
  }) {
    return _TappableLabel(
      value: value,
      inner: inner,
      painter: TextPainter(
        text: TextSpan(style: textStyle, text: label),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 2.0),
      )..layout(),
      onTap: onTap,
    );
  }



  List<_TappableLabel> _build12HourRing({
    required TextStyle? textStyle,
    required int selectedValue,
  }) {
    final bool isAm = widget.selectedTime.period == DayPeriod.am;
    
    return <_TappableLabel>[
      for (final TimeOfDay timeOfDay in _amHours)
        _buildTappableLabel(
          textStyle: textStyle,
          selectedValue: selectedValue,
          inner: false,
          value: timeOfDay.hour,
          label: () {
            int displayNum = timeOfDay.hour;
            if (isAm) {
              if (displayNum == 12) displayNum = 0; 
            } else {
              if (displayNum == 0) displayNum = 12;
            }
            return displayNum.toString().padLeft(2, '0');
          }(),
          onTap: () {
            _selectHour(timeOfDay.hour);
          },
        ),
    ];
  }

  List<_TappableLabel> _buildMinutes({required TextStyle? textStyle, required int selectedValue}) {
    const minuteMarkerValues = <TimeOfDay>[
      TimeOfDay(hour: 0, minute: 0),
      TimeOfDay(hour: 0, minute: 5),
      TimeOfDay(hour: 0, minute: 10),
      TimeOfDay(hour: 0, minute: 15),
      TimeOfDay(hour: 0, minute: 20),
      TimeOfDay(hour: 0, minute: 25),
      TimeOfDay(hour: 0, minute: 30),
      TimeOfDay(hour: 0, minute: 35),
      TimeOfDay(hour: 0, minute: 40),
      TimeOfDay(hour: 0, minute: 45),
      TimeOfDay(hour: 0, minute: 50),
      TimeOfDay(hour: 0, minute: 55),
    ];

    return <_TappableLabel>[
      for (final TimeOfDay timeOfDay in minuteMarkerValues)
        _buildTappableLabel(
          textStyle: textStyle,
          selectedValue: selectedValue,
          inner: false,
          value: timeOfDay.minute,
          label: localizations.formatMinute(timeOfDay),
          onTap: () {
            _selectMinute(timeOfDay.minute);
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    assert(_debugDialTimePickerEntryMode(context));
    final ThemeData theme = Theme.of(context);
    final TimePickerThemeData timePickerTheme = TimePickerTheme.of(context);
    final _TimePickerDefaults defaultTheme = theme.useMaterial3
        ? _TimePickerDefaultsM3(context)
        : _TimePickerDefaultsM2(context);
    final Color backgroundColor =
        timePickerTheme.dialBackgroundColor ?? defaultTheme.dialBackgroundColor;
    final Color dialHandColor = timePickerTheme.dialHandColor ?? defaultTheme.dialHandColor;
    final TextStyle labelStyle = timePickerTheme.dialTextStyle ?? defaultTheme.dialTextStyle;
    final Color dialTextUnselectedColor = WidgetStateProperty.resolveAs<Color>(
      timePickerTheme.dialTextColor ?? defaultTheme.dialTextColor,
      <WidgetState>{},
    );
    final Color dialTextSelectedColor = WidgetStateProperty.resolveAs<Color>(
      timePickerTheme.dialTextColor ?? defaultTheme.dialTextColor,
      <WidgetState>{WidgetState.selected},
    );
    final TextStyle resolvedUnselectedLabelStyle = labelStyle.copyWith(
      color: dialTextUnselectedColor,
    );
    final TextStyle resolvedSelectedLabelStyle = labelStyle.copyWith(color: dialTextSelectedColor);
    final dotColor = dialTextSelectedColor;

    List<_TappableLabel> primaryLabels;
    List<_TappableLabel> selectedLabels;
    final int selectedDialValue;
    final double radiusValue;
    switch (widget.hourMinuteMode) {
      case _HourMinuteMode.hour:
        selectedDialValue = widget.selectedTime.hourOfPeriod;
        primaryLabels = _build12HourRing(
          textStyle: resolvedUnselectedLabelStyle,
          selectedValue: selectedDialValue,
        );
        selectedLabels = _build12HourRing(
          textStyle: resolvedSelectedLabelStyle,
          selectedValue: selectedDialValue,
        );
        radiusValue = 1;
      case _HourMinuteMode.minute:
        selectedDialValue = widget.selectedTime.minute;
        primaryLabels = _buildMinutes(
          textStyle: resolvedUnselectedLabelStyle,
          selectedValue: selectedDialValue,
        );
        selectedLabels = _buildMinutes(
          textStyle: resolvedSelectedLabelStyle,
          selectedValue: selectedDialValue,
        );
        radiusValue = 1;
    }
    painter?.dispose();
    painter = _DialPainter(
      selectedValue: selectedDialValue,
      primaryLabels: primaryLabels,
      selectedLabels: selectedLabels,
      backgroundColor: backgroundColor,
      handColor: dialHandColor,
      handWidth: defaultTheme.handWidth,
      dotColor: dotColor,
      dotRadius: defaultTheme.dotRadius,
      centerRadius: defaultTheme.centerRadius,
      theta: _theta.value,
      radius: radiusValue,
      textDirection: Directionality.of(context),
    );

    return GestureDetector(
      excludeFromSemantics: true,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onTapUp: _handleTapUp,
      child: CustomPaint(painter: painter),
    );
  }
}

class _TimePickerInput extends StatefulWidget {
  const _TimePickerInput({
    required this.initialSelectedTime,
    required this.errorInvalidText,
    required this.hourLabelText,
    required this.minuteLabelText,
    required this.helpText,
    required this.autofocusHour,
    required this.autofocusMinute,
    required this.emptyInitialTime,
    this.restorationId,
    this.onValidationError,
  });

  /// The time initially selected when the dialog is shown.
  final TimeOfDay initialSelectedTime;

  /// Optionally provide your own validation error text.
  final String? errorInvalidText;

  /// Optionally provide your own hour label text.
  final String? hourLabelText;

  /// Optionally provide your own minute label text.
  final String? minuteLabelText;

  final String helpText;

  final bool? autofocusHour;

  final bool? autofocusMinute;

  final ValueChanged<bool>? onValidationError;

  /// Restoration ID to save and restore the state of the time picker input
  /// widget.
  ///
  /// If it is non-null, the widget will persist and restore its state
  ///
  /// The state of this widget is persisted in a [RestorationBucket] claimed
  /// from the surrounding [RestorationScope] using the provided restoration ID.
  final String? restorationId;

  /// If true and [TimePickerEntryMode.input] is used, hour and minute fields
  /// start empty instead of using [initialSelectedTime].
  ///
  /// Useful when users prefer manual input without clearing pre-filled values.
  /// Ignored in dial mode.
  final bool emptyInitialTime;

  @override
  _TimePickerInputState createState() => _TimePickerInputState();
}

class _TimePickerInputState extends State<_TimePickerInput> with RestorationMixin {
  late final RestorableTimeOfDay _selectedTime = RestorableTimeOfDay(widget.initialSelectedTime);
  final RestorableBool hourHasError = RestorableBool(false);
  final RestorableBool minuteHasError = RestorableBool(false);

  @override
  void dispose() {
    _selectedTime.dispose();
    hourHasError.dispose();
    minuteHasError.dispose();
    super.dispose();
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedTime, 'selected_time');
    registerForRestoration(hourHasError, 'hour_has_error');
    registerForRestoration(minuteHasError, 'minute_has_error');
  }

  int? _parseHour(String? value) {
    if (value == null || value.isEmpty) {
      return _selectedTime.value.period == DayPeriod.pm ? 12 : 0;
    }

    int? newHour = int.tryParse(value);
    if (newHour == null) {
      return null;
    }

    if (_selectedTime.value.period == DayPeriod.pm) {
      if (newHour >= 1 && newHour <= 12) {
        if (newHour == 12) return 12;
        return newHour + 12;
      }
    } else {
      if (newHour >= 0 && newHour <= 11) {
        return newHour;
      }
    }
    return null;
  }

  int? _parseMinute(String? value) {
    if (value == null || value.isEmpty) {
      return 0;
    }

    int? newMinute = int.tryParse(value);
    if (newMinute == null) {
      return null;
    }

    if (newMinute >= 0 && newMinute < 60) {
      return newMinute;
    }
    return null;
  }

  void _handleHourSavedSubmitted(String? value) {
    final int? newHour = _parseHour(value);
    if (newHour != null) {
      _selectedTime.value = TimeOfDay(hour: newHour, minute: _selectedTime.value.minute);
      _TimePickerModel.setSelectedTime(context, _selectedTime.value);
      FocusScope.of(context).requestFocus();
    }
  }

  void _handleHourChanged(String value) {
    final int? newHour = _parseHour(value);
    if (newHour != null && value.length == 2) {
      // If a valid hour is typed, move focus to the minute TextField.
      FocusScope.of(context).nextFocus();
    }
  }

  void _handleMinuteSavedSubmitted(String? value) {
    final int? newMinute = _parseMinute(value);
    if (newMinute != null) {
      _selectedTime.value = TimeOfDay(hour: _selectedTime.value.hour, minute: int.parse(value!));
      _TimePickerModel.setSelectedTime(context, _selectedTime.value);
      FocusScope.of(context).unfocus();
    }
  }

  void _handleDayPeriodChanged(TimeOfDay value) {
    _selectedTime.value = value;
    _TimePickerModel.setSelectedTime(context, _selectedTime.value);
  }

  String? _validateHour(String? value) {
    final int? newHour = _parseHour(value);
    final bool hasError = newHour == null;
    if (hourHasError.value != hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            hourHasError.value = hasError;
          });
          widget.onValidationError?.call(hourHasError.value || minuteHasError.value);
        }
      });
    }
    return null;
  }

  String? _validateMinute(String? value) {
    final int? newMinute = _parseMinute(value);
    final bool hasError = newMinute == null;
    if (minuteHasError.value != hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            minuteHasError.value = hasError;
          });
          widget.onValidationError?.call(hourHasError.value || minuteHasError.value);
        }
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final TimeOfDayFormat timeOfDayFormat = MaterialLocalizations.of(
      context,
    ).timeOfDayFormat(alwaysUse24HourFormat: false);
    final ThemeData theme = Theme.of(context);
    final TimePickerThemeData timePickerTheme = _TimePickerModel.themeOf(context);
    final _TimePickerDefaults defaultTheme = _TimePickerModel.defaultThemeOf(context);
    // DO NOT call .copyWith() on hourMinuteTextStyle, as it is a WidgetStateTextStyle and copyWith strips resolved properties like fontSize!
    final TextStyle hourMinuteStyle = timePickerTheme.hourMinuteTextStyle ?? defaultTheme.hourMinuteTextStyle;

    final double minInteractiveVerticalPadding = math.max(
      0,
      2 * kMinInteractiveDimension - defaultTheme.dayPeriodInputSize.height,
    );

    return Padding(
      padding: _TimePickerModel.useMaterial3Of(context)
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.only(
              bottom:
                  (_TimePickerModel.useMaterial3Of(context) ? 20 : 24) -
                  minInteractiveVerticalPadding / 2,
            ),
            child: Text(
              widget.helpText,
              style:
                  _TimePickerModel.themeOf(context).helpTextStyle ??
                  _TimePickerModel.defaultThemeOf(context).helpTextStyle,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (timeOfDayFormat == TimeOfDayFormat.a_space_h_colon_mm) ...<Widget>[
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: _DayPeriodControl(onPeriodChanged: _handleDayPeriodChanged),
                ),
              ],
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(top: minInteractiveVerticalPadding / 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Hour/minutes should not change positions in RTL locales.
                    textDirection: TextDirection.ltr,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _HourTextField(
                                restorationId: 'hour_text_field',
                                selectedTime: _selectedTime.value,
                                style: hourMinuteStyle,
                                autofocus: widget.autofocusHour,
                                inputAction: TextInputAction.next,
                                validator: _validateHour,
                                onSavedSubmitted: _handleHourSavedSubmitted,
                                onChanged: _handleHourChanged,
                                hourLabelText: widget.hourLabelText,
                                emptyInitialTime: widget.emptyInitialTime,
                                hasError: hourHasError.value,
                              ),
                            ),
                            hourHasError.value
                                ? Text(
                                      _selectedTime.value.period == DayPeriod.am
                                          ? t.common.err_invalid_hour_am
                                          : t.common.err_invalid_hour_pm,
                                      style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.error),
                                      maxLines: 2,
                                    )
                                  : ExcludeSemantics(
                                      child: Text(
                                        widget.hourLabelText ??
                                            MaterialLocalizations.of(context).timePickerHourLabel,
                                        style: theme.textTheme.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                          ],
                        ),
                      ),
                      _TimeSelectorSeparator(timeOfDayFormat: timeOfDayFormat),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _MinuteTextField(
                                restorationId: 'minute_text_field',
                                selectedTime: _selectedTime.value,
                                style: hourMinuteStyle,
                                autofocus: widget.autofocusMinute,
                                inputAction: TextInputAction.done,
                                validator: _validateMinute,
                                onSavedSubmitted: _handleMinuteSavedSubmitted,
                                minuteLabelText: widget.minuteLabelText,
                                emptyInitialTime: widget.emptyInitialTime,
                                hasError: minuteHasError.value,
                              ),
                            ),
                            minuteHasError.value
                                ? Text(
                                      t.common.err_invalid_minute,
                                      style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.error),
                                      maxLines: 2,
                                    )
                                  : ExcludeSemantics(
                                      child: Text(
                                        widget.minuteLabelText ??
                                            MaterialLocalizations.of(context).timePickerMinuteLabel,
                                        style: theme.textTheme.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (timeOfDayFormat != TimeOfDayFormat.a_space_h_colon_mm) ...<Widget>[
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12),
                  child: _DayPeriodControl(onPeriodChanged: _handleDayPeriodChanged),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HourTextField extends StatelessWidget {
  const _HourTextField({
    required this.selectedTime,
    required this.style,
    required this.autofocus,
    required this.inputAction,
    required this.validator,
    required this.onSavedSubmitted,
    required this.onChanged,
    required this.hourLabelText,
    required this.emptyInitialTime,
    this.restorationId,
    this.hasError = false,
  });

  final TimeOfDay selectedTime;
  final TextStyle style;
  final bool? autofocus;
  final TextInputAction inputAction;
  final FormFieldValidator<String> validator;
  final ValueChanged<String?> onSavedSubmitted;
  final ValueChanged<String> onChanged;
  final String? hourLabelText;
  final String? restorationId;
  final bool emptyInitialTime;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return _HourMinuteTextField(
      restorationId: restorationId,
      selectedTime: selectedTime,
      isHour: true,
      autofocus: autofocus,
      inputAction: inputAction,
      style: style,
      semanticHintText: hourLabelText ?? MaterialLocalizations.of(context).timePickerHourLabel,
      validator: validator,
      onSavedSubmitted: onSavedSubmitted,
      emptyInitialTime: emptyInitialTime,
      onChanged: onChanged,
      hasError: hasError,
    );
  }
}

class _MinuteTextField extends StatelessWidget {
  const _MinuteTextField({
    required this.selectedTime,
    required this.style,
    required this.autofocus,
    required this.inputAction,
    required this.validator,
    required this.onSavedSubmitted,
    required this.minuteLabelText,
    required this.emptyInitialTime,
    this.restorationId,
    this.hasError = false,
  });

  final TimeOfDay selectedTime;
  final TextStyle style;
  final bool? autofocus;
  final TextInputAction inputAction;
  final FormFieldValidator<String> validator;
  final ValueChanged<String?> onSavedSubmitted;
  final String? minuteLabelText;
  final String? restorationId;
  final bool emptyInitialTime;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return _HourMinuteTextField(
      restorationId: restorationId,
      selectedTime: selectedTime,
      isHour: false,
      autofocus: autofocus,
      inputAction: inputAction,
      style: style,
      semanticHintText: minuteLabelText ?? MaterialLocalizations.of(context).timePickerMinuteLabel,
      validator: validator,
      emptyInitialTime: emptyInitialTime,
      onSavedSubmitted: onSavedSubmitted,
      hasError: hasError,
    );
  }
}

class _HourMinuteTextField extends StatefulWidget {
  const _HourMinuteTextField({
    required this.selectedTime,
    required this.isHour,
    required this.autofocus,
    required this.inputAction,
    required this.style,
    required this.semanticHintText,
    required this.validator,
    required this.onSavedSubmitted,
    this.restorationId,
    required this.emptyInitialTime,
    this.onChanged,
    this.hasError = false,
  });

  final TimeOfDay selectedTime;
  final bool isHour;
  final bool? autofocus;
  final TextInputAction inputAction;
  final TextStyle style;
  final String semanticHintText;
  final FormFieldValidator<String> validator;
  final ValueChanged<String?> onSavedSubmitted;
  final ValueChanged<String>? onChanged;
  final String? restorationId;
  final bool emptyInitialTime;
  final bool hasError;

  @override
  _HourMinuteTextFieldState createState() => _HourMinuteTextFieldState();
}

class _HourMinuteTextFieldState extends State<_HourMinuteTextField> with RestorationMixin {
  final RestorableTextEditingController controller = RestorableTextEditingController();
  final RestorableBool controllerHasBeenSet = RestorableBool(false);
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode()
      ..addListener(() {
        setState(() {
          // Rebuild when focus changes.
          if (!focusNode.hasFocus && controller.value.text.isEmpty) {
            final bool isHour = widget.isHour;
            final bool isAm = widget.selectedTime.period == DayPeriod.am;
            String defaultFill;
            if (isHour) {
              int displayNum = isAm ? 0 : 12;
              defaultFill = displayNum == 12 ? '12' : displayNum.toString().padLeft(2, '0');
            } else {
              defaultFill = '00';
            }
            controller.value.text = defaultFill;
            widget.onChanged?.call(defaultFill);
            widget.onSavedSubmitted(defaultFill);
          } else if (!focusNode.hasFocus && controller.value.text.length == 1) {
            final String newFill = controller.value.text.padLeft(2, '0');
            controller.value.text = newFill;
            widget.onChanged?.call(newFill);
            widget.onSavedSubmitted(newFill);
          }
          if (kIsWeb && focusNode.hasFocus && primaryFocus?.context != null) {
            Actions.maybeInvoke(
              primaryFocus!.context!,
              const SelectAllTextIntent(SelectionChangedCause.keyboard),
            );
          }
        });
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only set the text value if it has not been populated with a localized
    // version yet.
    // If emptyInitialTime is true, set it to an empty string to indicate no
    // initial time.
    if (!controllerHasBeenSet.value) {
      controllerHasBeenSet.value = true;
      final String initialTextValue = widget.emptyInitialTime ? '' : _formattedValue;
      controller.value.value = TextEditingValue(text: initialTextValue);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    controllerHasBeenSet.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(controller, 'text_editing_controller');
    registerForRestoration(controllerHasBeenSet, 'has_controller_been_set');
  }

  String get _formattedValue {
    final bool alwaysUse24HourFormat = MediaQuery.alwaysUse24HourFormatOf(context);
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    if (!widget.isHour) {
      return localizations.formatMinute(widget.selectedTime);
    }
    
    if (alwaysUse24HourFormat) {
      return localizations.formatHour(
        widget.selectedTime,
        alwaysUse24HourFormat: true,
      );
    }
    
    int displayNum = widget.selectedTime.hourOfPeriod;
    final bool isAm = widget.selectedTime.period == DayPeriod.am;
    if (isAm) {
      return displayNum == 12 ? '00' : displayNum.toString().padLeft(2, '0');
    } else {
      return displayNum.toString().padLeft(2, '0');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TimePickerThemeData timePickerTheme = TimePickerTheme.of(context);
    final _TimePickerDefaults defaultTheme = theme.useMaterial3
        ? _TimePickerDefaultsM3(context)
        : _TimePickerDefaultsM2(context);


    final InputDecorationThemeData inputDecorationTheme =
        timePickerTheme.inputDecorationTheme ?? defaultTheme.inputDecorationTheme;
    InputDecoration inputDecoration = const InputDecoration(
    ).applyDefaults(inputDecorationTheme);
    // Remove the hint text when focused because the centered cursor
    // appears odd above the hint text.
    // Clear the hint text when emptyInitialTime is true.
    final String? hintText = focusNode.hasFocus || widget.emptyInitialTime ? null : _formattedValue;

    // Because the fill color is specified in both the inputDecorationTheme and
    // the TimePickerTheme, if there's one in the user's input decoration theme,
    // use that. If not, but there's one in the user's
    // timePickerTheme.hourMinuteColor, use that, and otherwise use the default.
    // We ignore the value in the fillColor of the input decoration in the
    // default theme here, but it's the same as the hourMinuteColor.
    final Color startingFillColor =
        timePickerTheme.inputDecorationTheme?.fillColor ??
        timePickerTheme.hourMinuteColor ??
        defaultTheme.hourMinuteColor;
    final Color fillColor;
    if (widget.hasError) {
      fillColor = theme.colorScheme.errorContainer;
    } else if (theme.useMaterial3) {
      fillColor = WidgetStateProperty.resolveAs<Color>(startingFillColor, <WidgetState>{
        if (focusNode.hasFocus) WidgetState.focused,
        if (focusNode.hasFocus) WidgetState.selected,
      });
    } else {
      fillColor = focusNode.hasFocus ? Colors.transparent : startingFillColor;
    }

    inputDecoration = inputDecoration.copyWith(hintText: hintText, fillColor: fillColor);
    
    if (widget.hasError) {
      inputDecoration = inputDecoration.copyWith(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
          borderRadius: BorderRadius.circular(8.0),
        ),
      );
    }

    final states = <WidgetState>{
      if (focusNode.hasFocus) WidgetState.focused,
      if (focusNode.hasFocus) WidgetState.selected,
    };
    final Color effectiveTextColor = WidgetStateProperty.resolveAs<Color>(
      timePickerTheme.hourMinuteTextColor ?? defaultTheme.hourMinuteTextColor,
      states,
    );
    final TextStyle effectiveStyle = WidgetStateProperty.resolveAs<TextStyle>(
      widget.style,
      states,
    ).copyWith(color: effectiveTextColor);

    return SizedBox.fromSize(
      size: defaultTheme.hourMinuteInputSize,
      child: MediaQuery.withNoTextScaling(
        child: UnmanagedRestorationScope(
          bucket: bucket,
          child: Semantics(
            label: widget.semanticHintText,
            child: TextFormField(
              autovalidateMode: AutovalidateMode.always,
              restorationId: 'hour_minute_text_form_field',
              autofocus: widget.autofocus ?? false,
              expands: true,
              maxLines: null,
              inputFormatters: <TextInputFormatter>[LengthLimitingTextInputFormatter(2)],
              focusNode: focusNode,
              textAlign: TextAlign.center,
              textInputAction: widget.inputAction,
              keyboardType: TextInputType.number,
              style: effectiveStyle,
              controller: controller.value,
              decoration: inputDecoration,
              validator: widget.validator,
              onEditingComplete: () => widget.onSavedSubmitted(controller.value.text),
              onSaved: widget.onSavedSubmitted,
              onFieldSubmitted: widget.onSavedSubmitted,
              onChanged: widget.onChanged,
            ),
          ),
        ),
      ),
    );
  }
}

/// Signature for when the time picker entry mode is changed.
typedef EntryModeChangeCallback = void Function(TimePickerEntryMode mode);

/// A Material Design time picker designed to appear inside a popup dialog.
///
/// Pass this widget to [showDialog]. The value returned by [showDialog] is the
/// selected [TimeOfDay] if the user taps the "OK" button, or null if the user
/// taps the "CANCEL" button. The selected time is reported by calling
/// [Navigator.pop].
///
/// Use [showGymTimePicker] to show a dialog already containing a [TimePickerDialog].
class TimePickerDialog extends StatefulWidget {
  /// Creates a Material Design time picker.
  const TimePickerDialog({
    super.key,
    required this.initialTime,
    this.cancelText,
    this.confirmText,
    this.helpText,
    this.errorInvalidText,
    this.hourLabelText,
    this.minuteLabelText,
    this.restorationId,
    this.initialEntryMode = TimePickerEntryMode.dial,
    this.orientation,
    this.onEntryModeChanged,
    this.switchToInputEntryModeIcon,
    this.switchToTimerEntryModeIcon,
    this.emptyInitialInput = false,
  });

  /// The time initially selected when the dialog is shown.
  final TimeOfDay initialTime;

  /// Optionally provide your own text for the cancel button.
  ///
  /// If null, the button uses [MaterialLocalizations.cancelButtonLabel].
  final String? cancelText;

  /// Optionally provide your own text for the confirm button.
  ///
  /// If null, the button uses [MaterialLocalizations.okButtonLabel].
  final String? confirmText;

  /// Optionally provide your own help text to the header of the time picker.
  final String? helpText;

  /// Optionally provide your own validation error text.
  final String? errorInvalidText;

  /// Optionally provide your own hour label text.
  final String? hourLabelText;

  /// Optionally provide your own minute label text.
  final String? minuteLabelText;

  /// Restoration ID to save and restore the state of the [TimePickerDialog].
  ///
  /// If it is non-null, the time picker will persist and restore the
  /// dialog's state.
  ///
  /// The state of this widget is persisted in a [RestorationBucket] claimed
  /// from the surrounding [RestorationScope] using the provided restoration ID.
  ///
  /// See also:
  ///
  ///  * [RestorationManager], which explains how state restoration works in
  ///    Flutter.
  final String? restorationId;

  /// The entry mode for the picker. Whether it's text input or a dial.
  final TimePickerEntryMode initialEntryMode;

  /// The optional [orientation] parameter sets the [Orientation] to use when
  /// displaying the dialog.
  ///
  /// By default, the orientation is derived from the [MediaQueryData.size] of
  /// the ambient [MediaQuery]. If the aspect of the size is tall, then
  /// [Orientation.portrait] is used, if the size is wide, then
  /// [Orientation.landscape] is used.
  ///
  /// Use this parameter to override the default and force the dialog to appear
  /// in either portrait or landscape mode regardless of the aspect of the
  /// [MediaQueryData.size].
  final Orientation? orientation;

  /// Callback called when the selected entry mode is changed.
  final EntryModeChangeCallback? onEntryModeChanged;

  /// {@macro flutter.material.time_picker.switchToInputEntryModeIcon}
  final Icon? switchToInputEntryModeIcon;

  /// {@macro flutter.material.time_picker.switchToTimerEntryModeIcon}
  final Icon? switchToTimerEntryModeIcon;

  /// If true and entry mode is [TimePickerEntryMode.input], the hour and minute
  /// fields will be empty on start instead of pre-filled with [initialTime].
  ///
  /// Has no effect in dial mode.
  final bool emptyInitialInput;

  @override
  State<TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<TimePickerDialog> with RestorationMixin {
  late final RestorableEnum<TimePickerEntryMode> _entryMode = RestorableEnum<TimePickerEntryMode>(
    widget.initialEntryMode,
    values: TimePickerEntryMode.values,
  );
  late final RestorableTimeOfDay _selectedTime = RestorableTimeOfDay(widget.initialTime);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _hasError = false;

  void _handleValidationError(bool hasError) {
    if (_hasError != hasError) {
      setState(() {
        _hasError = hasError;
      });
    }
  }
  final RestorableEnum<AutovalidateMode> _autovalidateMode = RestorableEnum<AutovalidateMode>(
    AutovalidateMode.disabled,
    values: AutovalidateMode.values,
  );
  late final RestorableEnumN<Orientation> _orientation = RestorableEnumN<Orientation>(
    widget.orientation,
    values: Orientation.values,
  );

  // Base sizes
  static const Size _kTimePickerPortraitSize = Size(310, 468);
  static const Size _kTimePickerLandscapeSize = Size(524, 342);
  static const Size _kTimePickerLandscapeSizeM2 = Size(508, 300);
  static const Size _kTimePickerInputSize = Size(312, 252);
  static const double _kTimePickerInputMinimumHeight = 216;

  // Absolute minimum dialog sizes, which is the point at which it begins
  // scrolling to fit everything in.
  static const Size _kTimePickerMinPortraitSize = Size(238, 326);
  static const Size _kTimePickerMinLandscapeSize = Size(416, 248);
  static const Size _kTimePickerMinInputSize = Size(312, 196);

  @override
  void dispose() {
    _selectedTime.dispose();
    _entryMode.dispose();
    _autovalidateMode.dispose();
    _orientation.dispose();
    super.dispose();
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedTime, 'selected_time');
    registerForRestoration(_entryMode, 'entry_mode');
    registerForRestoration(_autovalidateMode, 'autovalidate_mode');
    registerForRestoration(_orientation, 'orientation');
  }

  void _handleTimeChanged(TimeOfDay value) {
    if (value != _selectedTime.value) {
      setState(() {
        _selectedTime.value = value;
      });
    }
  }

  void _handleEntryModeChanged(TimePickerEntryMode value) {
    if (value != _entryMode.value) {
      setState(() {
        switch (_entryMode.value) {
          case TimePickerEntryMode.dial:
            _autovalidateMode.value = AutovalidateMode.disabled;
          case TimePickerEntryMode.input:
            _formKey.currentState!.save();
          case TimePickerEntryMode.dialOnly:
            break;
          case TimePickerEntryMode.inputOnly:
            break;
        }
        _entryMode.value = value;
        widget.onEntryModeChanged?.call(value);
      });
    }
  }

  void _toggleEntryMode() {
    switch (_entryMode.value) {
      case TimePickerEntryMode.dial:
        _handleEntryModeChanged(TimePickerEntryMode.input);
      case TimePickerEntryMode.input:
        _handleEntryModeChanged(TimePickerEntryMode.dial);
      case TimePickerEntryMode.dialOnly:
      case TimePickerEntryMode.inputOnly:
        FlutterError('Can not change entry mode from $_entryMode');
    }
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  void _handleOk() {
    if (_entryMode.value == TimePickerEntryMode.input ||
        _entryMode.value == TimePickerEntryMode.inputOnly) {
      final FormState form = _formKey.currentState!;
      if (!form.validate()) {
        setState(() {
          _autovalidateMode.value = AutovalidateMode.always;
        });
        return;
      }
      form.save();
    }
    Navigator.pop(context, _selectedTime.value);
  }

  Size _minDialogSize(BuildContext context, {required bool useMaterial3}) {
    final Orientation orientation = _orientation.value ?? MediaQuery.orientationOf(context);

    switch (_entryMode.value) {
      case TimePickerEntryMode.dial:
      case TimePickerEntryMode.dialOnly:
        return switch (orientation) {
          Orientation.portrait => _kTimePickerMinPortraitSize,
          Orientation.landscape => _kTimePickerMinLandscapeSize,
        };
      case TimePickerEntryMode.input:
      case TimePickerEntryMode.inputOnly:
        return Size(_kTimePickerMinPortraitSize.width, _kTimePickerMinInputSize.height);
    }
  }

  Size _dialogSize(BuildContext context, {required bool useMaterial3}) {
    final Orientation orientation = _orientation.value ?? MediaQuery.orientationOf(context);
    // Constrain the textScaleFactor to prevent layout issues. Since only some
    // parts of the time picker scale up with textScaleFactor, we cap the factor
    // to 1.1 as that provides enough space to reasonably fit all the content.
    //
    // 14 is a common font size used to compute the effective text scale.
    const fontSizeToScale = 14.0;
    final double textScaleFactor =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1).scale(fontSizeToScale) /
        fontSizeToScale;

    final Size timePickerSize;
    switch (_entryMode.value) {
      case TimePickerEntryMode.dial:
      case TimePickerEntryMode.dialOnly:
        switch (orientation) {
          case Orientation.portrait:
            timePickerSize = _kTimePickerPortraitSize;
          case Orientation.landscape:
            timePickerSize = Size(
              _kTimePickerLandscapeSize.width * textScaleFactor,
              useMaterial3 ? _kTimePickerLandscapeSize.height : _kTimePickerLandscapeSizeM2.height,
            );
        }
      case TimePickerEntryMode.input:
      case TimePickerEntryMode.inputOnly:
        timePickerSize = Size(_kTimePickerPortraitSize.width, _kTimePickerInputSize.height);
    }
    return Size(timePickerSize.width, timePickerSize.height * textScaleFactor);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final ThemeData theme = Theme.of(context);
    final TimePickerThemeData pickerTheme = TimePickerTheme.of(context);
    final _TimePickerDefaults defaultTheme = theme.useMaterial3
        ? _TimePickerDefaultsM3(context)
        : _TimePickerDefaultsM2(context);
    final ShapeBorder baseShape = pickerTheme.shape ?? defaultTheme.shape;
    final ShapeBorder shape = baseShape is OutlinedBorder
        ? baseShape.copyWith(
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          )
        : baseShape;
    final Color entryModeIconColor =
        pickerTheme.entryModeIconColor ?? defaultTheme.entryModeIconColor;
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);

    final bool isTablet = MediaQuery.sizeOf(context).width > 600;

    final Widget actions = Padding(
      padding: EdgeInsetsDirectional.only(
        start: theme.useMaterial3 ? 0 : 4,
        top: isTablet ? 8 : 24,
        bottom: 0,
        end: theme.useMaterial3 ? 0 : 4,
      ),
      child: Row(
        children: <Widget>[
          if (_entryMode.value == TimePickerEntryMode.dial ||
              _entryMode.value == TimePickerEntryMode.input)
            IconButton(
              // In material3 mode, we want to use the color as part of the
              // button style which applies its own opacity. In material2 mode,
              // we want to use the color as the color, which already includes
              // the opacity.
              color: theme.useMaterial3 ? null : entryModeIconColor,
              style: theme.useMaterial3
                  ? IconButton.styleFrom(foregroundColor: entryModeIconColor)
                  : null,
              onPressed: _toggleEntryMode,
              icon: _entryMode.value == TimePickerEntryMode.dial
                  ? widget.switchToInputEntryModeIcon ?? const Icon(Icons.keyboard_outlined)
                  : widget.switchToTimerEntryModeIcon ?? const Icon(Icons.access_time),
              tooltip: _entryMode.value == TimePickerEntryMode.dial
                  ? MaterialLocalizations.of(context).inputTimeModeButtonLabel
                  : MaterialLocalizations.of(context).dialModeButtonLabel,
            ),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OverflowBar(
                  spacing: 8,
                  overflowAlignment: OverflowBarAlignment.end,
                  children: <Widget>[
                    TextButton(
                      style: pickerTheme.cancelButtonStyle ?? defaultTheme.cancelButtonStyle,
                      onPressed: _handleCancel,
                      child: Text(
                        widget.cancelText ??
                            (theme.useMaterial3
                                ? localizations.cancelButtonLabel
                                : localizations.cancelButtonLabel.toUpperCase()),
                      ),
                    ),
                    TextButton(
                      style: pickerTheme.confirmButtonStyle ?? defaultTheme.confirmButtonStyle,
                      onPressed: _hasError ? null : _handleOk,
                      child: Text(widget.confirmText ?? localizations.okButtonLabel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final Offset tapTargetSizeOffset = switch (theme.materialTapTargetSize) {
      MaterialTapTargetSize.padded => Offset.zero,
      // _dialogSize returns "padded" sizes.
      MaterialTapTargetSize.shrinkWrap => const Offset(0, -12),
    };
    final Size dialogSize =
        _dialogSize(context, useMaterial3: theme.useMaterial3) + tapTargetSizeOffset;
    final Size minDialogSize =
        _minDialogSize(context, useMaterial3: theme.useMaterial3) + tapTargetSizeOffset;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    EdgeInsetsGeometry effectiveDialogPadding = pickerTheme.padding ?? defaultTheme.padding;
    if (isTablet && effectiveDialogPadding is EdgeInsets) {
      effectiveDialogPadding = effectiveDialogPadding.copyWith(
        bottom: math.max(0, effectiveDialogPadding.bottom - 16),
      );
    }

    Widget dialog = Dialog(
      shape: shape,
      elevation: pickerTheme.elevation ?? defaultTheme.elevation,
      backgroundColor: pickerTheme.backgroundColor ?? defaultTheme.backgroundColor,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical:
            (_entryMode.value == TimePickerEntryMode.input ||
                _entryMode.value == TimePickerEntryMode.inputOnly)
            ? 0
            : 24,
      ),
      child: Padding(
        padding: effectiveDialogPadding,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Size constrainedSize = constraints.constrain(dialogSize);
            final allowedSize = Size(
              constrainedSize.width < minDialogSize.width
                  ? minDialogSize.width
                  : constrainedSize.width,
              constrainedSize.height < minDialogSize.height
                  ? minDialogSize.height
                  : constrainedSize.height,
            );
            return SingleChildScrollView(
              restorationId: 'time_picker_scroll_view_horizontal',
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                restorationId: 'time_picker_scroll_view_vertical',
                child: AnimatedContainer(
                  width: allowedSize.width,
                  duration: _kDialogSizeAnimationDuration,
                  curve: Curves.easeIn,
                  constraints: BoxConstraints(
                    minHeight: _kTimePickerInputMinimumHeight,
                    maxHeight: allowedSize.height,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Builder(
                        builder: (BuildContext context) {
                          final Widget child = Form(
                            key: _formKey,
                            autovalidateMode: _autovalidateMode.value,
                            child: _TimePicker(
                              time: widget.initialTime,
                              onTimeChanged: _handleTimeChanged,
                              helpText: widget.helpText,
                              cancelText: widget.cancelText,
                              confirmText: widget.confirmText,
                              errorInvalidText: widget.errorInvalidText,
                              hourLabelText: widget.hourLabelText,
                              minuteLabelText: widget.minuteLabelText,
                              restorationId: 'time_picker',
                              entryMode: _entryMode.value,
                              orientation: widget.orientation,
                              onEntryModeChanged: _handleEntryModeChanged,
                              switchToInputEntryModeIcon: widget.switchToInputEntryModeIcon,
                              switchToTimerEntryModeIcon: widget.switchToTimerEntryModeIcon,
                              emptyInitialInput: widget.emptyInitialInput,
                              onValidationError: _handleValidationError,
                            ),
                          );
                          if (_entryMode.value != TimePickerEntryMode.input &&
                              _entryMode.value != TimePickerEntryMode.inputOnly) {
                            return Flexible(child: child);
                          }
                          return child;
                        },
                      ),
                      actions,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
      child: Transform.translate(
        offset: Offset(0, -keyboardHeight / 2.5),
        child: dialog,
      ),
    );
  }
}

// The _TimePicker widget is constructed so that in the future we could expose
// this as a public API for embedding time pickers into other non-dialog
// widgets, once we're sure we want to support that.

/// A Time Picker widget that can be embedded into another widget.
class _TimePicker extends StatefulWidget {
  /// Creates a const Material Design time picker.
  const _TimePicker({
    required this.time,
    required this.onTimeChanged,
    this.helpText,
    this.cancelText,
    this.confirmText,
    this.errorInvalidText,
    this.hourLabelText,
    this.minuteLabelText,
    this.restorationId,
    this.entryMode = TimePickerEntryMode.dial,
    this.orientation,
    this.onEntryModeChanged,
    this.switchToInputEntryModeIcon,
    this.switchToTimerEntryModeIcon,
    required this.emptyInitialInput,
    this.onValidationError,
  });

  /// Optionally provide your own text for the help text at the top of the
  /// control.
  ///
  /// If null, the widget uses [MaterialLocalizations.timePickerDialHelpText]
  /// when the [entryMode] is [TimePickerEntryMode.dial], and
  /// [MaterialLocalizations.timePickerInputHelpText] when the [entryMode] is
  /// [TimePickerEntryMode.input].
  final String? helpText;

  /// Optionally provide your own text for the cancel button.
  ///
  /// If null, the button uses [MaterialLocalizations.cancelButtonLabel].
  final String? cancelText;

  /// Optionally provide your own text for the confirm button.
  ///
  /// If null, the button uses [MaterialLocalizations.okButtonLabel].
  final String? confirmText;

  /// Optionally provide your own validation error text.
  final String? errorInvalidText;

  /// Optionally provide your own hour label text.
  final String? hourLabelText;

  /// Optionally provide your own minute label text.
  final String? minuteLabelText;

  /// Restoration ID to save and restore the state of the [TimePickerDialog].
  ///
  /// If it is non-null, the time picker will persist and restore the
  /// dialog's state.
  ///
  /// The state of this widget is persisted in a [RestorationBucket] claimed
  /// from the surrounding [RestorationScope] using the provided restoration ID.
  ///
  /// See also:
  ///
  ///  * [RestorationManager], which explains how state restoration works in
  ///    Flutter.
  final String? restorationId;

  /// The initial entry mode for the picker. Whether it's text input or a dial.
  final TimePickerEntryMode entryMode;

  /// The currently selected time of day.
  final TimeOfDay time;

  final ValueChanged<TimeOfDay>? onTimeChanged;

  /// The optional [orientation] parameter sets the [Orientation] to use when
  /// displaying the dialog.
  ///
  /// By default, the orientation is derived from the [MediaQueryData.size] of
  /// the ambient [MediaQuery]. If the aspect of the size is tall, then
  /// [Orientation.portrait] is used, if the size is wide, then
  /// [Orientation.landscape] is used.
  ///
  /// Use this parameter to override the default and force the dialog to appear
  /// in either portrait or landscape mode regardless of the aspect of the
  /// [MediaQueryData.size].
  final Orientation? orientation;

  /// Callback called when the selected entry mode is changed.
  final EntryModeChangeCallback? onEntryModeChanged;

  /// {@macro flutter.material.time_picker.switchToInputEntryModeIcon}
  final Icon? switchToInputEntryModeIcon;

  /// {@macro flutter.material.time_picker.switchToTimerEntryModeIcon}
  final Icon? switchToTimerEntryModeIcon;

  /// If true, input fields start empty in input mode.
  final bool emptyInitialInput;

  final ValueChanged<bool>? onValidationError;

  @override
  State<_TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<_TimePicker> with RestorationMixin {
  Timer? _vibrateTimer;
  late MaterialLocalizations localizations;
  final RestorableEnum<_HourMinuteMode> _hourMinuteMode = RestorableEnum<_HourMinuteMode>(
    _HourMinuteMode.hour,
    values: _HourMinuteMode.values,
  );
  final RestorableEnumN<_HourMinuteMode> _lastModeAnnounced = RestorableEnumN<_HourMinuteMode>(
    null,
    values: _HourMinuteMode.values,
  );
  final RestorableBoolN _autofocusHour = RestorableBoolN(null);
  final RestorableBoolN _autofocusMinute = RestorableBoolN(null);
  late final RestorableEnumN<Orientation> _orientation = RestorableEnumN<Orientation>(
    widget.orientation,
    values: Orientation.values,
  );
  RestorableTimeOfDay get selectedTime => _selectedTime;
  late final RestorableTimeOfDay _selectedTime = RestorableTimeOfDay(widget.time);

  @override
  void dispose() {
    _vibrateTimer?.cancel();
    _vibrateTimer = null;
    _orientation.dispose();
    _selectedTime.dispose();
    _hourMinuteMode.dispose();
    _lastModeAnnounced.dispose();
    _autofocusHour.dispose();
    _autofocusMinute.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = MaterialLocalizations.of(context);
  }

  @override
  void didUpdateWidget(_TimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orientation != widget.orientation) {
      _orientation.value = widget.orientation;
    }
    if (oldWidget.time != widget.time) {
      _selectedTime.value = widget.time;
    }
    if (oldWidget.entryMode != widget.entryMode) {
      if (widget.entryMode == TimePickerEntryMode.input || widget.entryMode == TimePickerEntryMode.inputOnly) {
        if (_autofocusHour.value != true && _autofocusMinute.value != true) {
          if (_hourMinuteMode.value == _HourMinuteMode.hour) {
            _autofocusHour.value = true;
            _autofocusMinute.value = false;
          } else {
            _autofocusHour.value = false;
            _autofocusMinute.value = true;
          }
        }
      } else {
        _autofocusHour.value = false;
        _autofocusMinute.value = false;
      }
    }
  }

  void _setEntryMode(TimePickerEntryMode mode) {
    widget.onEntryModeChanged?.call(mode);
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_hourMinuteMode, 'hour_minute_mode');
    registerForRestoration(_lastModeAnnounced, 'last_mode_announced');
    registerForRestoration(_autofocusHour, 'autofocus_hour');
    registerForRestoration(_autofocusMinute, 'autofocus_minute');
    registerForRestoration(_selectedTime, 'selected_time');
    registerForRestoration(_orientation, 'orientation');
  }

  void _vibrate() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        _vibrateTimer?.cancel();
        _vibrateTimer = Timer(_kVibrateCommitDelay, () {
          HapticFeedback.vibrate();
          _vibrateTimer = null;
        });
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        break;
    }
  }

  void _handleHourMinuteModeChanged(_HourMinuteMode mode) {
    _vibrate();
    setState(() {
      _hourMinuteMode.value = mode;
    });
  }

  void _handleEntryModeToggle() {
    setState(() {
      TimePickerEntryMode newMode = widget.entryMode;
      switch (widget.entryMode) {
        case TimePickerEntryMode.dial:
          newMode = TimePickerEntryMode.input;
        case TimePickerEntryMode.input:
          _autofocusHour.value = false;
          _autofocusMinute.value = false;
          newMode = TimePickerEntryMode.dial;
        case TimePickerEntryMode.dialOnly:
        case TimePickerEntryMode.inputOnly:
          FlutterError('Can not change entry mode from ${widget.entryMode}');
      }
      _setEntryMode(newMode);
    });
  }

  void _handleTimeChanged(TimeOfDay value) {
    _vibrate();
    setState(() {
      _selectedTime.value = value;
      widget.onTimeChanged?.call(value);
    });
  }

  void _handleHourDoubleTapped() {
    _autofocusHour.value = true;
    _handleEntryModeToggle();
  }

  void _handleMinuteDoubleTapped() {
    _autofocusMinute.value = true;
    _handleEntryModeToggle();
  }

  void _handleHourSelected() {
    setState(() {
      _hourMinuteMode.value = _HourMinuteMode.minute;
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final ThemeData theme = Theme.of(context);
    final _TimePickerDefaults defaultTheme = theme.useMaterial3
        ? _TimePickerDefaultsM3(context, entryMode: widget.entryMode)
        : _TimePickerDefaultsM2(context);
    final Orientation orientation = _orientation.value ?? MediaQuery.orientationOf(context);


    final String helpText;
    final Widget picker;
    switch (widget.entryMode) {
      case TimePickerEntryMode.dial:
      case TimePickerEntryMode.dialOnly:
        helpText =
            widget.helpText ??
            (theme.useMaterial3
                ? localizations.timePickerDialHelpText
                : localizations.timePickerDialHelpText.toUpperCase());

        // The vertical adjustment used to make both AM/PM buttons accessible.
        // Because the period selector height is increased based on this value,
        // the dial padding has to be decreased of the same amount.
        final double portraitMinInteractiveVerticalAdjustment = math.max(
          0,
          2 * kMinInteractiveDimension - defaultTheme.dayPeriodPortraitSize.height,
        );
        final EdgeInsetsGeometry dialPadding = switch (orientation) {
          Orientation.portrait => EdgeInsets.only(
            left: 12,
            right: 12,
            top: 36 - portraitMinInteractiveVerticalAdjustment / 2,
          ),
          Orientation.landscape => const EdgeInsetsDirectional.only(start: 64),
        };

        final Widget dial = Padding(
          padding: dialPadding,
          child: ExcludeSemantics(
            child: SizedBox.fromSize(
              size: defaultTheme.dialSize,
              child: AspectRatio(
                aspectRatio: 1,
                child: _Dial(
                  hourMinuteMode: _hourMinuteMode.value,

                  selectedTime: _selectedTime.value,
                  onChanged: _handleTimeChanged,
                  onHourSelected: _handleHourSelected,
                ),
              ),
            ),
          ),
        );

        switch (orientation) {
          case Orientation.portrait:
            picker = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: theme.useMaterial3 ? 0 : 16),
                  child: _DialTimePickerHeader(helpText: helpText),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Dial grows and shrinks with the available space.
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: theme.useMaterial3 ? 0 : 16),
                          child: dial,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          case Orientation.landscape:
            picker = Column(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: theme.useMaterial3 ? 0 : 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _DialTimePickerHeader(helpText: helpText),
                        Expanded(child: dial),
                      ],
                    ),
                  ),
                ),
              ],
            );
        }
      case TimePickerEntryMode.input:
      case TimePickerEntryMode.inputOnly:
        final String helpText =
            widget.helpText ??
            (theme.useMaterial3
                ? localizations.timePickerInputHelpText
                : localizations.timePickerInputHelpText.toUpperCase());

        picker = Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _TimePickerInput(
              initialSelectedTime: _selectedTime.value,
              errorInvalidText: widget.errorInvalidText,
              hourLabelText: widget.hourLabelText,
              minuteLabelText: widget.minuteLabelText,
              helpText: helpText,
              autofocusHour: _autofocusHour.value,
              autofocusMinute: _autofocusMinute.value,
              restorationId: 'time_picker_input',
              emptyInitialTime: widget.emptyInitialInput,
              onValidationError: widget.onValidationError,
            ),
          ],
        );
    }
    return _TimePickerModel(
      entryMode: widget.entryMode,
      selectedTime: _selectedTime.value,
      hourMinuteMode: _hourMinuteMode.value,
      orientation: orientation,
      onHourMinuteModeChanged: _handleHourMinuteModeChanged,
      onHourDoubleTapped: _handleHourDoubleTapped,
      onMinuteDoubleTapped: _handleMinuteDoubleTapped,

      onSelectedTimeChanged: _handleTimeChanged,
      useMaterial3: theme.useMaterial3,
      theme: TimePickerTheme.of(context),
      defaultTheme: defaultTheme,
      child: picker,
    );
  }
}

/// Shows a dialog containing a Material Design time picker.
///
/// The returned Future resolves to the time selected by the user when the user
/// closes the dialog. If the user cancels the dialog, null is returned.
///
/// {@tool snippet} Show a dialog with [initialTime] equal to the current time.
///
/// ```dart
/// Future<TimeOfDay?> selectedTime = showGymTimePicker(
///   initialTime: TimeOfDay.now(),
///   context: context,
/// );
/// ```
/// {@end-tool}
///
/// The [context], [barrierDismissible], [barrierColor], [barrierLabel],
/// [useRootNavigator] and [routeSettings] arguments are passed to [showDialog],
/// the documentation for which discusses how it is used.
///
/// The [builder] parameter can be used to wrap the dialog widget to add
/// inherited widgets like [Localizations.override], [Directionality], or
/// [MediaQuery].
///
/// The `initialEntryMode` parameter can be used to determine the initial time
/// entry selection of the picker (either a clock dial or text input).
///
/// Optional strings for the [helpText], [cancelText], [errorInvalidText],
/// [hourLabelText], [minuteLabelText] and [confirmText] can be provided to
/// override the default values.
///
/// The optional [orientation] parameter sets the [Orientation] to use when
/// displaying the dialog. By default, the orientation is derived from the
/// [MediaQueryData.size] of the ambient [MediaQuery]: wide sizes use the
/// landscape orientation, and tall sizes use the portrait orientation. Use this
/// parameter to override the default and force the dialog to appear in either
/// portrait or landscape mode.
///
/// {@template flutter.material.time_picker.switchToInputEntryModeIcon}
/// The optional [switchToInputEntryModeIcon] argument can be used to customize
/// the input method icon that is shown when the [TimePickerEntryMode]
/// is [TimePickerEntryMode.dial].
///
/// Defaults to an [Icon] widget with [Icons.keyboard_outlined] as icon.
/// {@endtemplate}
///
/// {@template flutter.material.time_picker.switchToTimerEntryModeIcon}
/// The optional [switchToTimerEntryModeIcon] argument can be used to customize
/// the input method icon that is shown when the [TimePickerEntryMode]
/// is [TimePickerEntryMode.input].
///
/// Defaults to an [Icon] widget with [Icons.access_time] as icon.
/// {@endtemplate}
///
/// {@macro flutter.widgets.RawDialogRoute}
///
/// By default, the time picker gets its colors from the overall theme's
/// [ColorScheme]. The time picker can be further customized by providing a
/// [TimePickerThemeData] to the overall theme.
///
/// {@tool snippet} Show a dialog with the text direction overridden to be
/// [TextDirection.rtl].
///
/// ```dart
/// Future<TimeOfDay?> selectedTimeRTL = showGymTimePicker(
///   context: context,
///   initialTime: TimeOfDay.now(),
///   builder: (BuildContext context, Widget? child) {
///     return Directionality(
///       textDirection: TextDirection.rtl,
///       child: child!,
///     );
///   },
/// );
/// ```
/// {@end-tool}
///
/// {@tool snippet} Show a dialog with time unconditionally displayed in 24 hour
/// format.
///
/// ```dart
/// Future<TimeOfDay?> selectedTime24Hour = showGymTimePicker(
///   context: context,
///   initialTime: const TimeOfDay(hour: 10, minute: 47),
///   builder: (BuildContext context, Widget? child) {
///     return MediaQuery(
///       data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
///       child: child!,
///     );
///   },
/// );
/// ```
/// {@end-tool}
///
/// {@tool dartpad}
/// This example illustrates how to open a time picker, and allows exploring
/// some of the variations in the types of time pickers that may be shown.
///
/// ** See code in examples/api/lib/material/time_picker/show_time_picker.0.dart **
/// {@end-tool}
///
/// See also:
///
/// * [showDatePicker], which shows a dialog that contains a Material Design
///   date picker.
/// * [TimePickerThemeData], which allows you to customize the colors,
///   typography, and shape of the time picker.
/// * [DisplayFeatureSubScreen], which documents the specifics of how
///   [DisplayFeature]s can split the screen into sub-screens.
Future<TimeOfDay?> showGymTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  TransitionBuilder? builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useRootNavigator = true,
  TimePickerEntryMode initialEntryMode = TimePickerEntryMode.dial,
  String? cancelText,
  String? confirmText,
  String? helpText,
  String? errorInvalidText,
  String? hourLabelText,
  String? minuteLabelText,
  RouteSettings? routeSettings,
  EntryModeChangeCallback? onEntryModeChanged,
  Offset? anchorPoint,
  Orientation? orientation,
  Icon? switchToInputEntryModeIcon,
  Icon? switchToTimerEntryModeIcon,
  bool emptyInitialInput = false,
}) async {
  assert(debugCheckHasMaterialLocalizations(context));

  final Widget dialog = TimePickerDialog(
    initialTime: initialTime,
    initialEntryMode: initialEntryMode,
    cancelText: cancelText,
    confirmText: confirmText,
    helpText: helpText,
    errorInvalidText: errorInvalidText,
    hourLabelText: hourLabelText,
    minuteLabelText: minuteLabelText,
    orientation: orientation,
    onEntryModeChanged: onEntryModeChanged,
    switchToInputEntryModeIcon: switchToInputEntryModeIcon,
    switchToTimerEntryModeIcon: switchToTimerEntryModeIcon,
    emptyInitialInput: emptyInitialInput,
  );
  return showDialog<TimeOfDay>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useRootNavigator: useRootNavigator,
    builder: (BuildContext context) {
      final Widget widget = builder == null ? dialog : builder(context, dialog);
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: widget,
      );
    },
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
  );
}

// An abstract base class for the M2 and M3 defaults below, so that their return
// types can be non-nullable.
abstract class _TimePickerDefaults extends TimePickerThemeData {
  @override
  Color get backgroundColor;

  @override
  ButtonStyle get cancelButtonStyle;

  @override
  ButtonStyle get confirmButtonStyle;

  @override
  BorderSide get dayPeriodBorderSide;

  @override
  Color get dayPeriodColor;

  @override
  OutlinedBorder get dayPeriodShape;

  Size get dayPeriodInputSize;
  Size get dayPeriodLandscapeSize;
  Size get dayPeriodPortraitSize;

  @override
  Color get dayPeriodTextColor;

  @override
  TextStyle get dayPeriodTextStyle;

  @override
  Color get dialBackgroundColor;

  @override
  Color get dialHandColor;

  // Sizes that are generated from the tokens, but these aren't ones we're ready
  // to expose in the theme.
  Size get dialSize;
  double get handWidth;
  double get dotRadius;
  double get centerRadius;

  @override
  Color get dialTextColor;

  @override
  TextStyle get dialTextStyle;

  @override
  double get elevation;

  @override
  Color get entryModeIconColor;

  @override
  TextStyle get helpTextStyle;

  @override
  Color get hourMinuteColor;

  @override
  ShapeBorder get hourMinuteShape;

  Size get hourMinuteSize;
  Size get hourMinuteInputSize;

  @override
  Color get hourMinuteTextColor;

  @override
  TextStyle get hourMinuteTextStyle;

  @override
  InputDecorationThemeData get inputDecorationTheme;

  @override
  EdgeInsetsGeometry get padding;

  @override
  ShapeBorder get shape;
}

// These theme defaults are not auto-generated: they match the values for the
// Material 2 spec, which are not expected to change.
class _TimePickerDefaultsM2 extends _TimePickerDefaults {
  _TimePickerDefaultsM2(this.context) : super();

  final BuildContext context;

  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;
  static const OutlinedBorder _kDefaultShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  @override
  Color get backgroundColor {
    return _colors.surface;
  }

  @override
  ButtonStyle get cancelButtonStyle {
    return TextButton.styleFrom();
  }

  @override
  ButtonStyle get confirmButtonStyle {
    return TextButton.styleFrom();
  }

  @override
  BorderSide get dayPeriodBorderSide {
    return BorderSide(
      color: Color.alphaBlend(_colors.onSurface.withOpacity(0.38), _colors.surface),
    );
  }

  @override
  Color get dayPeriodColor {
    return WidgetStateColor.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return _colors.primary.withOpacity(_colors.brightness == Brightness.dark ? 0.24 : 0.12);
      }
      // The unselected day period should match the overall picker dialog color.
      // Making it transparent enables that without being redundant and allows
      // the optional elevation overlay for dark mode to be visible.
      return Colors.transparent;
    });
  }

  @override
  OutlinedBorder get dayPeriodShape {
    return _kDefaultShape;
  }

  @override
  Size get dayPeriodPortraitSize {
    return const Size(52, 80);
  }

  @override
  Size get dayPeriodLandscapeSize {
    return const Size(0, 40);
  }

  @override
  Size get dayPeriodInputSize {
    return const Size(52, 80);
  }

  @override
  Color get dayPeriodTextColor {
    return WidgetStateColor.resolveWith((Set<WidgetState> states) {
      return states.contains(WidgetState.selected)
          ? _colors.primary
          : _colors.onSurface.withOpacity(0.60);
    });
  }

  @override
  TextStyle get dayPeriodTextStyle {
    return _textTheme.titleMedium!.copyWith(color: dayPeriodTextColor);
  }

  @override
  Color get dialBackgroundColor {
    return _colors.onSurface.withOpacity(_colors.brightness == Brightness.dark ? 0.12 : 0.08);
  }

  @override
  Color get dialHandColor {
    return _colors.primary;
  }

  @override
  Size get dialSize {
    return const Size.square(280);
  }

  @override
  double get handWidth {
    return 2;
  }

  @override
  double get dotRadius {
    return 22;
  }

  @override
  double get centerRadius {
    return 4;
  }

  @override
  Color get dialTextColor {
    return WidgetStateColor.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return _colors.surface;
      }
      return _colors.onSurface;
    });
  }

  @override
  TextStyle get dialTextStyle {
    return _textTheme.bodyLarge!;
  }

  @override
  double get elevation {
    return 6;
  }

  @override
  Color get entryModeIconColor {
    return _colors.onSurface.withOpacity(_colors.brightness == Brightness.dark ? 1.0 : 0.6);
  }

  @override
  TextStyle get helpTextStyle {
    return _textTheme.labelSmall!;
  }

  @override
  Color get hourMinuteColor {
    return WidgetStateColor.resolveWith((Set<WidgetState> states) {
      return states.contains(WidgetState.selected)
          ? _colors.primary.withOpacity(_colors.brightness == Brightness.dark ? 0.24 : 0.12)
          : _colors.onSurface.withOpacity(0.12);
    });
  }

  @override
  ShapeBorder get hourMinuteShape {
    return _kDefaultShape;
  }

  @override
  Size get hourMinuteSize {
    return const Size(96, 80);
  }

  @override
  Size get hourMinuteInputSize {
    return hourMinuteSize;
  }

  @override
  Color get hourMinuteTextColor {
    return WidgetStateColor.resolveWith((Set<WidgetState> states) {
      return states.contains(WidgetState.selected) ? _colors.primary : _colors.onSurface;
    });
  }

  @override
  TextStyle get hourMinuteTextStyle {
    return _textTheme.displayLarge!;
  }

  Color get _hourMinuteInputColor {
    return WidgetStateColor.resolveWith((Set<WidgetState> states) {
      return states.contains(WidgetState.selected)
          ? Colors.transparent
          : _colors.onSurface.withOpacity(0.12);
    });
  }

  @override
  InputDecorationThemeData get inputDecorationTheme {
    return InputDecorationThemeData(
      contentPadding: EdgeInsets.zero,
      filled: true,
      fillColor: _hourMinuteInputColor,
      focusColor: Colors.transparent,
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
      errorBorder: OutlineInputBorder(borderSide: BorderSide(color: _colors.error, width: 2)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _colors.primary, width: 2)),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _colors.error, width: 2),
      ),
      hintStyle: hourMinuteTextStyle.copyWith(color: _colors.onSurface.withOpacity(0.36)),
    );
  }

  @override
  EdgeInsetsGeometry get padding {
    return const EdgeInsets.fromLTRB(8, 18, 8, 8);
  }

  @override
  ShapeBorder get shape {
    return _kDefaultShape;
  }
}

/// Ensure the widget is called in [TimePickerEntryMode.dial] or [TimePickerEntryMode.dialOnly] mode.
bool _debugDialTimePickerEntryMode(BuildContext context) {
  final TimePickerEntryMode entryMode = _TimePickerModel.entryModeOf(context);
  return entryMode == TimePickerEntryMode.dial || entryMode == TimePickerEntryMode.dialOnly;
}

// BEGIN GENERATED TOKEN PROPERTIES - TimePicker

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// dart format off
class _TimePickerDefaultsM3 extends _TimePickerDefaults {
  _TimePickerDefaultsM3(this.context, { this.entryMode = TimePickerEntryMode.dial });

  final BuildContext context;
  final TimePickerEntryMode entryMode;

  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color get backgroundColor {
    return _colors.surfaceContainerHigh;
  }

  @override
  ButtonStyle get cancelButtonStyle {
    return TextButton.styleFrom();
  }

  @override
  ButtonStyle get confirmButtonStyle {
    return TextButton.styleFrom();
  }

  @override
  BorderSide get dayPeriodBorderSide {
    return BorderSide(color: _colors.outline);
  }

  @override
  Color get dayPeriodColor {
    return WidgetStateColor.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return _colors.tertiaryContainer;
      }
      // The unselected day period should match the overall picker dialog color.
      // Making it transparent enables that without being redundant and allows
      // the optional elevation overlay for dark mode to be visible.
      return Colors.transparent;
    });
  }

  @override
  OutlinedBorder get dayPeriodShape {
    return const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))).copyWith(side: dayPeriodBorderSide);
  }

  @override
  Size get dayPeriodPortraitSize {
    return const Size(52, 80);
  }

  @override
  Size get dayPeriodLandscapeSize {
    return const Size(216, 38);
  }

  @override
  Size get dayPeriodInputSize {
    return dayPeriodPortraitSize;
  }

  @override
  Color get dayPeriodTextColor {
    return WidgetStateColor.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.focused)) {
          return _colors.onTertiaryContainer;
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onTertiaryContainer;
        }
        if (states.contains(WidgetState.pressed)) {
          return _colors.onTertiaryContainer;
        }
        return _colors.onTertiaryContainer;
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.onSurfaceVariant;
      }
      if (states.contains(WidgetState.hovered)) {
        return _colors.onSurfaceVariant;
      }
      if (states.contains(WidgetState.pressed)) {
        return _colors.onSurfaceVariant;
      }
      return _colors.onSurfaceVariant;
    });
  }

  @override
  TextStyle get dayPeriodTextStyle {
    return _textTheme.titleMedium!.copyWith(color: dayPeriodTextColor);
  }

  @override
  Color get dialBackgroundColor {
    return _colors.surfaceContainerHighest;
  }

  @override
  Color get dialHandColor {
    return _colors.primary;
  }

  @override
  Size get dialSize {
    return const Size.square(256.0);
  }

  @override
  double get handWidth {
    return const Size(2, double.infinity).width;
  }

  @override
  double get dotRadius {
    return const Size.square(48.0).width / 2;
  }

  @override
  double get centerRadius {
    return const Size.square(8.0).width / 2;
  }

  @override
  Color get dialTextColor {
    return WidgetStateColor.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return _colors.onPrimary;
      }
      return _colors.onSurface;
    });
  }

  @override
  TextStyle get dialTextStyle {
    return _textTheme.bodyLarge!;
  }

  @override
  double get elevation {
    return 6.0;
  }

  @override
  Color get entryModeIconColor {
    return _colors.onSurface;
  }

  @override
  TextStyle get helpTextStyle {
    return WidgetStateTextStyle.resolveWith((Set<WidgetState> states) {
      final TextStyle textStyle = _textTheme.labelMedium!;
      return textStyle.copyWith(color: _colors.onSurfaceVariant);
    });
  }

  @override
  EdgeInsetsGeometry get padding {
    return const EdgeInsets.all(24);
  }

  @override
  Color get hourMinuteColor {
    return WidgetStateColor.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        Color overlayColor = _colors.primaryContainer;
        if (states.contains(WidgetState.pressed)) {
          overlayColor = _colors.onPrimaryContainer;
        } else if (states.contains(WidgetState.hovered)) {
          const hoverOpacity = 0.08;
          overlayColor = _colors.onPrimaryContainer.withOpacity(hoverOpacity);
        } else if (states.contains(WidgetState.focused)) {
          const focusOpacity = 0.1;
          overlayColor = _colors.onPrimaryContainer.withOpacity(focusOpacity);
        }
        return Color.alphaBlend(overlayColor, _colors.primaryContainer);
      } else {
        Color overlayColor = _colors.surfaceContainerHighest;
        if (states.contains(WidgetState.pressed)) {
          overlayColor = _colors.onSurface;
        } else if (states.contains(WidgetState.hovered)) {
          const hoverOpacity = 0.08;
          overlayColor = _colors.onSurface.withOpacity(hoverOpacity);
        } else if (states.contains(WidgetState.focused)) {
          const focusOpacity = 0.1;
          overlayColor = _colors.onSurface.withOpacity(focusOpacity);
        }
        return Color.alphaBlend(overlayColor, _colors.surfaceContainerHighest);
      }
    });
  }

  @override
  ShapeBorder get hourMinuteShape {
    return const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0)));
  }

  @override
  Size get hourMinuteSize {
    return const Size(96, 80);
  }

  @override
  Size get hourMinuteInputSize {
    return hourMinuteSize;
  }

  @override
  Color get hourMinuteTextColor {
    return WidgetStateColor.resolveWith((Set<WidgetState> states) {
      return _hourMinuteTextColor.resolve(states);
    });
  }

  WidgetStateProperty<Color> get _hourMinuteTextColor {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.onPrimaryContainer;
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onPrimaryContainer;
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onPrimaryContainer;
        }
        return _colors.onPrimaryContainer;
      } else {
        // unselected
        if (states.contains(WidgetState.pressed)) {
          return _colors.onSurface;
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onSurface;
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onSurface;
        }
        return _colors.onSurface;
      }
    });
  }

  @override
  TextStyle get hourMinuteTextStyle {
    return WidgetStateTextStyle.resolveWith((Set<WidgetState> states) {
      // TODO(tahatesser): Update this when https://github.com/flutter/flutter/issues/131247 is fixed.
      // This is using the correct text style from Material 3 spec.
      // https://m3.material.io/components/time-pickers/specs#fd0b6939-edab-4058-82e1-93d163945215
      return switch (entryMode) {
        TimePickerEntryMode.dial || TimePickerEntryMode.dialOnly
          => _textTheme.displayLarge!.copyWith(color: _hourMinuteTextColor.resolve(states)),
        TimePickerEntryMode.input || TimePickerEntryMode.inputOnly
          => _textTheme.displayLarge!.copyWith(color: _hourMinuteTextColor.resolve(states)),
      };
    });
  }

  @override
  InputDecorationThemeData get inputDecorationTheme {
    // This is NOT correct, but there's no token for
    // 'time-input.container.shape', so this is using the radius from the shape
    // for the hour/minute selector. It's a BorderRadiusGeometry, so we have to
    // resolve it before we can use it.
    final BorderRadius selectorRadius = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0)))
      .borderRadius
      .resolve(Directionality.of(context));
    return InputDecorationThemeData(
      contentPadding: EdgeInsets.zero,
      filled: true,
      // This should be derived from a token, but there isn't one for 'time-input'.
      fillColor: hourMinuteColor,
      // This should be derived from a token, but there isn't one for 'time-input'.
      focusColor: _colors.primaryContainer,
      enabledBorder: OutlineInputBorder(
        borderRadius: selectorRadius,
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: selectorRadius,
        borderSide: BorderSide(color: _colors.error, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: selectorRadius,
        borderSide: BorderSide(color: _colors.primary, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: selectorRadius,
        borderSide: BorderSide(color: _colors.error, width: 2),
      ),
      hintStyle: hourMinuteTextStyle.copyWith(color: _colors.onSurface.withOpacity(0.36)),
      // Prevent the error text from appearing.
      // TODO(rami-a): Remove this workaround once
      // https://github.com/flutter/flutter/issues/54104
      // is fixed.
    );
  }

  @override
  ShapeBorder get shape {
    return const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28.0)));
  }

  @override
  WidgetStateProperty<Color?>? get timeSelectorSeparatorColor {
    // TODO(tahatesser): Update this when tokens are available.
    // This is taken from https://m3.material.io/components/time-pickers/specs.
    return MaterialStatePropertyAll<Color>(_colors.onSurface);
  }

  @override
  WidgetStateProperty<TextStyle?>? get timeSelectorSeparatorTextStyle {
    // TODO(tahatesser): Update this when tokens are available.
    // This is taken from https://m3.material.io/components/time-pickers/specs.
    return MaterialStatePropertyAll<TextStyle?>(_textTheme.displayLarge);
  }
}
// dart format on

// END GENERATED TOKEN PROPERTIES - TimePicker
