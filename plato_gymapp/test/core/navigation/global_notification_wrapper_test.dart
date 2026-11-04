import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_notification.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/features/auth/data/models/user_models.dart';
import 'package:plato_gymapp/features/nutrition/data/models/nutrition_models.dart';
import 'package:plato_gymapp/features/gamification/data/models/gamification_models.dart';
import 'package:plato_gymapp/features/gamification/presentation/bloc/gamification_cubit.dart';
import 'package:plato_gymapp/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:plato_gymapp/main.dart';

class _FakeGamificationCubit extends Cubit<GamificationState>
    implements GamificationCubit {
  _FakeGamificationCubit([int initialLevel = 1])
      : super(GamificationState(
          stats: UserGamificationStats(level: initialLevel),
        ));

  void setLevel(int newLevel) {
    emit(state.copyWith(
      stats: state.stats.copyWith(level: newLevel),
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileCubit extends Cubit<ProfileState>
    implements ProfileCubit {
  _FakeProfileCubit([int initialRankId = 1])
      : super(ProfileState(
          userProfile: UserProfile(
            activeRankId: initialRankId,
            targetMacros: const Macros(
              calories: 2000,
              protein: 150,
              carbs: 200,
              fat: 60,
            ),
            detailedBodyMetrics: const BodyMetrics(),
          ),
        ));

  void setRankId(int newRankId) {
    emit(state.copyWith(
      userProfile: state.userProfile.copyWith(activeRankId: newRankId),
    ));
  }

  void setProfile({int? rankId, int? xp}) {
    emit(state.copyWith(
      userProfile: state.userProfile.copyWith(
        activeRankId: rankId ?? state.userProfile.activeRankId,
        experiencePoints: xp ?? state.userProfile.experiencePoints,
      ),
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    LocaleSettings.setLocale(AppLocale.en);
  });

  tearDown(GymTopNotification.clear);

  Widget createTestWidget({
    required _FakeGamificationCubit gamificationCubit,
    required _FakeProfileCubit profileCubit,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GamificationCubit>.value(value: gamificationCubit),
        BlocProvider<ProfileCubit>.value(value: profileCubit),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const GlobalNotificationWrapper(
          child: Scaffold(body: Center(child: Text('Home'))),
        ),
      ),
    );
  }

  testWidgets('initial startup does not show notification', (tester) async {
    final gamificationCubit = _FakeGamificationCubit(1);
    final profileCubit = _FakeProfileCubit(1);

    await tester.pumpWidget(createTestWidget(
      gamificationCubit: gamificationCubit,
      profileCubit: profileCubit,
    ));
    await tester.pumpAndSettle();

    expect(GymTopNotification.isShowing, isFalse);
  });

  testWidgets('level up only triggers level up top notification', (tester) async {
    final gamificationCubit = _FakeGamificationCubit(1);
    final profileCubit = _FakeProfileCubit(1);

    await tester.pumpWidget(createTestWidget(
      gamificationCubit: gamificationCubit,
      profileCubit: profileCubit,
    ));
    await tester.pumpAndSettle();

    // Simulate level up (e.g. quest claimed)
    gamificationCubit.setLevel(2);
    await tester.pump(const Duration(milliseconds: 100));
    // During debounce, not showing yet
    expect(GymTopNotification.isShowing, isFalse);

    // After debounce (350ms)
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(GymTopNotification.isShowing, isTrue);
    expect(find.text('Level Up!'), findsOneWidget);
    expect(find.text('Lv. 1 ➔ 2'), findsOneWidget);
  });

  testWidgets('rank up only triggers rank up top notification', (tester) async {
    final gamificationCubit = _FakeGamificationCubit(3);
    final profileCubit = _FakeProfileCubit(1);

    await tester.pumpWidget(createTestWidget(
      gamificationCubit: gamificationCubit,
      profileCubit: profileCubit,
    ));
    await tester.pumpAndSettle();

    profileCubit.setRankId(2);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(GymTopNotification.isShowing, isTrue);
    expect(find.text('Rank Up!'), findsOneWidget);
    expect(find.text('Bronze I ➔ Bronze II'), findsOneWidget);
  });

  testWidgets('both level and rank up triggers combined top notification', (tester) async {
    final gamificationCubit = _FakeGamificationCubit(1);
    final profileCubit = _FakeProfileCubit(1);

    await tester.pumpWidget(createTestWidget(
      gamificationCubit: gamificationCubit,
      profileCubit: profileCubit,
    ));
    await tester.pumpAndSettle();

    // Simulate login sync with higher level and higher rank
    profileCubit.setRankId(3);
    await tester.pump(const Duration(milliseconds: 50));
    gamificationCubit.setLevel(5);

    // Wait for debounce to settle both emissions
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(GymTopNotification.isShowing, isTrue);
    expect(find.text('Level Up! & Rank Up!'), findsOneWidget);
    expect(find.text('Lv. 1 ➔ 5'), findsOneWidget);
    expect(find.text('Bronze I ➔ Silver I'), findsOneWidget);
  });

  testWidgets('lower level or rank (downgrade / logout) does not trigger notification', (tester) async {
    final gamificationCubit = _FakeGamificationCubit(5);
    final profileCubit = _FakeProfileCubit(3);

    await tester.pumpWidget(createTestWidget(
      gamificationCubit: gamificationCubit,
      profileCubit: profileCubit,
    ));
    await tester.pumpAndSettle();

    // User switches to lower level account
    profileCubit.setRankId(1);
    gamificationCubit.setLevel(2);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(GymTopNotification.isShowing, isFalse);
  });

  testWidgets('login profile sync with higher XP and rank triggers combined notification even without gamification emit', (tester) async {
    final gamificationCubit = _FakeGamificationCubit(1);
    final profileCubit = _FakeProfileCubit(1);

    await tester.pumpWidget(createTestWidget(
      gamificationCubit: gamificationCubit,
      profileCubit: profileCubit,
    ));
    await tester.pumpAndSettle();

    // 5000 XP corresponds to Level 5 in RewardXpProgress
    profileCubit.setProfile(rankId: 3, xp: 5000);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(GymTopNotification.isShowing, isTrue);
    expect(find.text('Level Up! & Rank Up!'), findsOneWidget);
    expect(find.text('Lv. 1 ➔ 5'), findsOneWidget);
    expect(find.text('Bronze I ➔ Silver I'), findsOneWidget);
  });
}
