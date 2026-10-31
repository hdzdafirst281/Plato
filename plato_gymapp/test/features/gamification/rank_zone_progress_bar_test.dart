import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/gamification/domain/rank_calculator.dart';
import 'package:plato_gymapp/features/gamification/presentation/components/rank_zone_progress_bar.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';

Widget _app(int rankId) => TranslationProvider(
  child: MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: RankZoneProgressBar(
            rank: RankConfig.getRankById(rankId),
            points: 200,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('rank progress bar renders the workout reward zones', (
    tester,
  ) async {
    await tester.pumpWidget(_app(3));

    expect(find.byKey(const ValueKey('rank-zone-demote')), findsOneWidget);
    expect(find.byKey(const ValueKey('rank-zone-maintain')), findsOneWidget);
    expect(find.byKey(const ValueKey('rank-zone-promote')), findsOneWidget);
    expect(find.byKey(const ValueKey('rp-marker')), findsOneWidget);
    expect(find.text('120 RP'), findsOneWidget);
    expect(find.text('280 RP'), findsOneWidget);
    expect(find.text(t.workout_rewards.zone_demote), findsNothing);
    expect(find.text(t.workout_rewards.zone_maintain), findsNothing);
    expect(find.text(t.workout_rewards.zone_promote), findsNothing);
  });

  testWidgets('first rank only shows its promotion threshold', (tester) async {
    await tester.pumpWidget(_app(1));

    expect(find.byKey(const ValueKey('rank-maintain-threshold')), findsNothing);
    expect(
      find.byKey(const ValueKey('rank-promote-threshold')),
      findsOneWidget,
    );
    expect(find.text('80 RP'), findsOneWidget);
  });
}
