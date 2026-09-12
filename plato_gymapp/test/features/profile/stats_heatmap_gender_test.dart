import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/database/enums.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/auth/data/models/user_models.dart';
import 'package:plato_gymapp/features/nutrition/data/models/nutrition_models.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/stats_cubit.dart';
import 'package:plato_gymapp/features/profile/presentation/components/bodymap/body_map_painter.dart';
import 'package:plato_gymapp/features/profile/presentation/components/bodymap/body_map_repository.dart';
import 'package:plato_gymapp/features/profile/presentation/screens/stats/heatmap_detail_screen.dart';
import 'package:plato_gymapp/features/profile/presentation/screens/stats_screen.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';

// Use real Cubit streams without starting database or repository subscriptions.
class _ProfileCubit extends Cubit<ProfileState> implements ProfileCubit {
  _ProfileCubit(Gender gender)
    : super(
        ProfileState(
          userProfile: UserProfile(
            gender: gender,
            targetMacros: const Macros(),
            detailedBodyMetrics: const BodyMetrics(),
          ),
        ),
      );

  void changeGender(Gender gender) {
    emit(
      state.copyWith(userProfile: state.userProfile.copyWith(gender: gender)),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StatsCubit extends Cubit<StatsState> implements StatsCubit {
  _StatsCubit() : super(const StatsState(isLoading: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final initialGender in Gender.values) {
    testWidgets(
      'stats uses $initialGender and reacts to profile gender changes',
      (tester) async {
        final profile = _ProfileCubit(initialGender);
        final stats = _StatsCubit();
        addTearDown(profile.close);
        addTearDown(stats.close);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<ProfileCubit>.value(value: profile),
              BlocProvider<StatsCubit>.value(value: stats),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const StatsScreen(
                initialScreen: StatsScreenType.HEATMAP_DETAIL,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        void expectGeometry(Gender gender, HeatmapMode mode) {
          expect(
            tester
                .widget<HeatmapDetailScreen>(find.byType(HeatmapDetailScreen))
                .gender,
            gender,
          );
          for (final front in [true, false]) {
            final finder = find.byKey(
              ValueKey(front ? 'body-map-front' : 'body-map-back'),
            );
            final painter =
                tester.widget<CustomPaint>(finder).painter! as BodyMapPainter;
            final geometry = BodyMapRepository.resolve(gender, front: front);
            expect(painter.borderPath, same(geometry.border));
            expect(painter.hairFront, same(geometry.hairFront));
            expect(painter.hairBack, same(geometry.hairBack));
            expect(painter.mode, mode);
          }
          expect(tester.takeException(), isNull);
        }

        expectGeometry(initialGender, HeatmapMode.FREQUENCY);
        await tester.tap(find.text(t.stats.lbl_heatmap_mode_intensity));
        await tester.pumpAndSettle();
        final screenState = tester.state(find.byType(HeatmapDetailScreen));
        final otherGender = initialGender == Gender.MALE
            ? Gender.FEMALE
            : Gender.MALE;
        profile.changeGender(otherGender);
        await tester.pumpAndSettle();
        expectGeometry(otherGender, HeatmapMode.INTENSITY);
        expect(
          tester.state(find.byType(HeatmapDetailScreen)),
          same(screenState),
        );

        profile.changeGender(initialGender);
        await tester.pumpAndSettle();
        expectGeometry(initialGender, HeatmapMode.INTENSITY);
      },
    );
  }
}
