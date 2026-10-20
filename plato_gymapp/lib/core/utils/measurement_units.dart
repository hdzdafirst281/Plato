import 'package:flutter/foundation.dart';

enum WeightUnit { kilogram, pound }

enum HydrationUnit { liter, usGallon }

enum DistanceUnit { kilometer, mile }

enum BodyLengthUnit { metric, imperial }

enum FoodMassUnit { gram, ounce }

@immutable
class MeasurementPreferences {
  const MeasurementPreferences({
    this.weight = WeightUnit.kilogram,
    this.hydration = HydrationUnit.liter,
    this.distance = DistanceUnit.kilometer,
    this.bodyLength = BodyLengthUnit.metric,
    this.foodMass = FoodMassUnit.gram,
  });

  final WeightUnit weight;
  final HydrationUnit hydration;
  final DistanceUnit distance;
  final BodyLengthUnit bodyLength;
  final FoodMassUnit foodMass;

  factory MeasurementPreferences.fromJson(Map<String, dynamic>? json) {
    T parse<T extends Enum>(List<T> values, Object? raw, T fallback) =>
        values.where((value) => value.name == raw).firstOrNull ?? fallback;

    return MeasurementPreferences(
      weight: parse(WeightUnit.values, json?['weight'], WeightUnit.kilogram),
      hydration: parse(
        HydrationUnit.values,
        json?['hydration'],
        HydrationUnit.liter,
      ),
      distance: parse(
        DistanceUnit.values,
        json?['distance'],
        DistanceUnit.kilometer,
      ),
      bodyLength: parse(
        BodyLengthUnit.values,
        json?['body_length'],
        BodyLengthUnit.metric,
      ),
      foodMass: parse(
        FoodMassUnit.values,
        json?['food_mass'],
        FoodMassUnit.gram,
      ),
    );
  }

  Map<String, String> toJson() => {
    'weight': weight.name,
    'hydration': hydration.name,
    'distance': distance.name,
    'body_length': bodyLength.name,
    'food_mass': foodMass.name,
  };

  MeasurementPreferences copyWith({
    WeightUnit? weight,
    HydrationUnit? hydration,
    DistanceUnit? distance,
    BodyLengthUnit? bodyLength,
    FoodMassUnit? foodMass,
  }) => MeasurementPreferences(
    weight: weight ?? this.weight,
    hydration: hydration ?? this.hydration,
    distance: distance ?? this.distance,
    bodyLength: bodyLength ?? this.bodyLength,
    foodMass: foodMass ?? this.foodMass,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementPreferences &&
          weight == other.weight &&
          hydration == other.hydration &&
          distance == other.distance &&
          bodyLength == other.bodyLength &&
          foodMass == other.foodMass;

  @override
  int get hashCode =>
      Object.hash(weight, hydration, distance, bodyLength, foodMass);
}

class MeasurementFormatter {
  const MeasurementFormatter(this.preferences);

  static const poundsPerKilogram = 2.2046226218;
  static const usGallonsPerLiter = 0.2641720524;
  static const milesPerKilometer = 0.6213711922;
  static const inchesPerCentimeter = 0.3937007874;
  static const ouncesPerGram = 0.03527396195;

  final MeasurementPreferences preferences;

  String get weightUnit =>
      preferences.weight == WeightUnit.kilogram ? 'kg' : 'lb';
  String get hydrationUnit =>
      preferences.hydration == HydrationUnit.liter ? 'L' : 'US gal';
  String get distanceUnit =>
      preferences.distance == DistanceUnit.kilometer ? 'km' : 'mi';
  String get speedUnit =>
      preferences.distance == DistanceUnit.kilometer ? 'km/h' : 'mph';
  String get bodyLengthUnit =>
      preferences.bodyLength == BodyLengthUnit.metric ? 'cm' : 'in';
  String get heightUnit =>
      preferences.bodyLength == BodyLengthUnit.metric ? 'cm' : 'ft/in';
  String get foodMassUnit =>
      preferences.foodMass == FoodMassUnit.gram ? 'g' : 'oz';

  double weightFromKg(double kilograms) =>
      preferences.weight == WeightUnit.kilogram
      ? kilograms
      : kilograms * poundsPerKilogram;

  double weightToKg(double displayValue) =>
      preferences.weight == WeightUnit.kilogram
      ? displayValue
      : displayValue / poundsPerKilogram;

  double hydrationFromLiters(double liters) =>
      preferences.hydration == HydrationUnit.liter
      ? liters
      : liters * usGallonsPerLiter;

  double hydrationToLiters(double displayValue) =>
      preferences.hydration == HydrationUnit.liter
      ? displayValue
      : displayValue / usGallonsPerLiter;

  double distanceFromKm(double kilometers) =>
      preferences.distance == DistanceUnit.kilometer
      ? kilometers
      : kilometers * milesPerKilometer;

  double distanceToKm(double displayValue) =>
      preferences.distance == DistanceUnit.kilometer
      ? displayValue
      : displayValue / milesPerKilometer;

  double speedFromKmh(double kilometersPerHour) =>
      distanceFromKm(kilometersPerHour);

  double speedToKmh(double displayValue) => distanceToKm(displayValue);

  double bodyLengthFromCm(double centimeters) =>
      preferences.bodyLength == BodyLengthUnit.metric
      ? centimeters
      : centimeters * inchesPerCentimeter;

  double bodyLengthToCm(double displayValue) =>
      preferences.bodyLength == BodyLengthUnit.metric
      ? displayValue
      : displayValue / inchesPerCentimeter;

  double foodMassFromGrams(double grams) =>
      preferences.foodMass == FoodMassUnit.gram ? grams : grams * ouncesPerGram;

  double foodMassToGrams(double displayValue) =>
      preferences.foodMass == FoodMassUnit.gram
      ? displayValue
      : displayValue / ouncesPerGram;

  String formatWeight(double kilograms, {int decimals = 1}) =>
      '${number(weightFromKg(kilograms), decimals)} $weightUnit';

  String formatHydration(double liters, {int decimals = 2}) =>
      '${number(hydrationFromLiters(liters), decimals)} $hydrationUnit';

  String formatDistance(double kilometers, {int decimals = 2}) =>
      '${number(distanceFromKm(kilometers), decimals)} $distanceUnit';

  String formatSpeed(double kilometersPerHour, {int decimals = 1}) =>
      '${number(speedFromKmh(kilometersPerHour), decimals)} $speedUnit';

  String formatBodyLength(double centimeters, {int decimals = 1}) =>
      '${number(bodyLengthFromCm(centimeters), decimals)} $bodyLengthUnit';

  String formatHeight(double centimeters) {
    if (preferences.bodyLength == BodyLengthUnit.metric) {
      return '${number(centimeters, 1)} cm';
    }
    final roundedTotalInches =
        (centimeters * inchesPerCentimeter * 10).round() / 10;
    final feet = roundedTotalInches ~/ 12;
    final inches = roundedTotalInches - feet * 12;
    return '$feet ft ${number(inches, 1)} in';
  }

  String formatFoodMass(double grams, {int decimals = 1}) =>
      '${number(foodMassFromGrams(grams), decimals)} $foodMassUnit';

  static String number(double value, int maxDecimals) {
    final fixed = value.toStringAsFixed(maxDecimals);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
