import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/utils/measurement_units.dart';
import 'package:plato_gymapp/features/auth/data/models/user_models.dart';
import 'package:plato_gymapp/features/nutrition/data/models/nutrition_models.dart';

void main() {
  group('MeasurementFormatter', () {
    test('keeps canonical metric values unchanged by default', () {
      const formatter = MeasurementFormatter(MeasurementPreferences());

      expect(
        formatter.weightToKg(formatter.weightFromKg(55)),
        closeTo(55, 1e-9),
      );
      expect(
        formatter.hydrationToLiters(formatter.hydrationFromLiters(2.5)),
        closeTo(2.5, 1e-9),
      );
      expect(
        formatter.distanceToKm(formatter.distanceFromKm(10)),
        closeTo(10, 1e-9),
      );
    });

    test('round-trips alternate display values to canonical metric values', () {
      const formatter = MeasurementFormatter(
        MeasurementPreferences(
          weight: WeightUnit.pound,
          hydration: HydrationUnit.usGallon,
          distance: DistanceUnit.meter,
          bodyLength: BodyLengthUnit.imperial,
          foodMass: FoodMassUnit.ounce,
        ),
      );

      expect(
        formatter.weightToKg(formatter.weightFromKg(55)),
        closeTo(55, 1e-9),
      );
      expect(
        formatter.hydrationToLiters(formatter.hydrationFromLiters(2.5)),
        closeTo(2.5, 1e-9),
      );
      expect(
        formatter.distanceToKm(formatter.distanceFromKm(10)),
        closeTo(10, 1e-9),
      );
      expect(
        formatter.bodyLengthToCm(formatter.bodyLengthFromCm(165)),
        closeTo(165, 1e-9),
      );
      expect(
        formatter.foodMassToGrams(formatter.foodMassFromGrams(100)),
        closeTo(100, 1e-9),
      );
      expect(formatter.formatHeight(165), '65 in');
      expect(formatter.formatWeight(1), '2.2 lb');
      expect(formatter.formatHydration(3.785411784), '1 gal');
      expect(formatter.formatDistance(1), '1000 m');
      expect(formatter.formatSpeedKmh(1.609344, unit: 'km/h'), '1.6 km/h');
      expect(formatter.formatBodyLength(2.54), '1 in');
      expect(formatter.formatFoodMass(28.349523125), '1 oz');
      expect(
        MeasurementPreferences.fromJson(formatter.preferences.toJson()),
        formatter.preferences,
      );
    });

    test('falls back to metric for obsolete cloud preferences', () {
      final preferences = MeasurementPreferences.fromJson({
        'weight': 'unknown',
        'distance': 'mile',
      });

      expect(preferences, const MeasurementPreferences());
    });

    test('persists preferences through the local user profile JSON', () {
      const preferences = MeasurementPreferences(
        weight: WeightUnit.pound,
        hydration: HydrationUnit.usGallon,
        distance: DistanceUnit.meter,
        bodyLength: BodyLengthUnit.imperial,
        foodMass: FoodMassUnit.ounce,
      );
      const profile = UserProfile(
        targetMacros: Macros(),
        detailedBodyMetrics: BodyMetrics(),
        measurementPreferences: preferences,
      );

      final restored = UserProfile.fromJson(
        jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>,
      );

      expect(restored.measurementPreferences, preferences);
    });
  });
}
