import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_dialog.dart';
import 'package:plato_gymapp/core/designsystem/components/gym_top_notification.dart';
import 'package:plato_gymapp/core/designsystem/theme/app_theme.dart';
import 'package:plato_gymapp/core/designsystem/theme/colors.dart';
import 'package:plato_gymapp/core/designsystem/theme/shapes.dart';

const _screenKey = ValueKey('notification-review-screen');
const _goldenRoot = '../artifacts/notification_ui_review';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont('Roboto', r'C:\Windows\Fonts\Roboto-Regular.ttf');
    await _loadFont(
      'MaterialIcons',
      r'D:\develop\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
    );
  });

  setUp(() => GymTopNotification.clear());
  tearDown(() => GymTopNotification.clear());

  testWidgets('01 new streak achieved', (tester) async {
    await _captureBanner(
      tester,
      fileName: '01_new_streak_achieved.png',
      screenTitle: 'Tổng quan hôm nay',
      title: 'Streak của bạn bắt đầu rồi',
      body: 'Bạn đã hoàn thành một buổi tập đủ điều kiện trong tuần này.',
      action: 'Xem chi tiết',
      icon: Icons.celebration_outlined,
    );
  });

  testWidgets('02 streak milestone', (tester) async {
    await _captureBanner(
      tester,
      fileName: '02_streak_milestone.png',
      screenTitle: 'Tiến độ tập luyện',
      title: 'Một cột mốc đáng nhớ',
      body: '12 tuần duy trì tập luyện. Cùng ghi nhận hành trình của bạn!',
      action: 'Xem chi tiết',
      icon: Icons.celebration_outlined,
      accent: const Color(0xFFFF8A00),
    );
  });

  testWidgets('03 hydration goal completed', (tester) async {
    await _pumpScreen(
      tester,
      title: 'Nước uống',
      child: const _HydrationAchievementPreview(),
    );
    await _golden(tester, '03_hydration_goal_completed.png');
  });

  testWidgets('04 rank promotion', (tester) async {
    await _captureRankDialog(
      tester,
      fileName: '04_rank_promotion.png',
      title: 'Xếp hạng',
      dialogTitle: 'Thăng Hạng!',
      rankName: 'Bạc I',
      body: '',
      badgeAsset: 'assets/badges/silver1.webp',
      accent: const Color(0xFF78909C),
    );
  });

  testWidgets('05 rank maintained', (tester) async {
    await _captureRankDialog(
      tester,
      fileName: '05_rank_maintained.png',
      title: 'Xếp hạng',
      dialogTitle: 'Bạn đã giữ hạng',
      rankName: 'Bạc I',
      body: 'Bạn kết thúc chu kỳ ở hạng Bạc I. Xem mục tiêu tiếp theo nhé.',
      badgeAsset: 'assets/badges/silver1.webp',
      accent: const Color(0xFF78909C),
    );
  });

  testWidgets('06 rank demotion', (tester) async {
    await _captureRankDialog(
      tester,
      fileName: '06_rank_demotion.png',
      title: 'Xếp hạng',
      dialogTitle: 'Kết quả chu kỳ xếp hạng',
      rankName: 'Đồng I',
      body:
          'Hạng của bạn trong chu kỳ mới là Đồng I. Cùng đặt mục tiêu tập luyện tiếp theo.',
      badgeAsset: 'assets/badges/bronze1.webp',
      accent: const Color(0xFFB87333),
    );
  });

  testWidgets('07 workout milestone', (tester) async {
    await _captureBanner(
      tester,
      fileName: '07_workout_milestone.png',
      screenTitle: 'Lịch sử tập luyện',
      title: 'Cột mốc tập luyện mới',
      body: 'Bạn đã hoàn thành 100 buổi tập.',
      action: 'Xem chi tiết',
      icon: Icons.celebration_outlined,
      accent: const Color(0xFF7B61FF),
    );
  });

  testWidgets('08 recovery overview and recommendations', (tester) async {
    await _pumpScreen(
      tester,
      title: 'Phục hồi cơ bắp',
      child: const _RecoveryOverviewPreview(),
      allowScroll: true,
    );
    await _golden(tester, '08_recovery_overview.png');
  });

  testWidgets('09 recovery routine warning', (tester) async {
    await _pumpScreen(
      tester,
      title: 'Push Day',
      child: const _RecoveryWarningPreview(),
    );
    await _golden(tester, '09_recovery_routine_warning.png');
  });

  testWidgets('10 all routines ready stays limited to two', (tester) async {
    await _pumpScreen(
      tester,
      title: 'Phục hồi cơ bắp',
      child: const _RecoveryScenarioPreview(
        bars: [
          ('Ngực', .94),
          ('Lưng', .91),
          ('Vai', .88),
          ('Tay', .86),
          ('Đùi', .84),
          ('Bắp chân', .82),
        ],
        suggestions: [
          _SuggestionPreviewData(
            icon: Icons.check_circle_outline,
            color: Color(0xFF1976D2),
            title: 'Upper Body',
            body: 'Upper Body phù hợp với các nhóm cơ đã sẵn sàng tập.',
          ),
          _SuggestionPreviewData(
            icon: Icons.check_circle_outline,
            color: Color(0xFF1976D2),
            title: 'Full Body',
            body: 'Full Body phù hợp với các nhóm cơ đã sẵn sàng tập.',
          ),
        ],
      ),
      allowScroll: true,
    );
    await _golden(tester, '10_recovery_all_routines_ready.png');
  });

  testWidgets('11 no routine ready shows two safest choices', (tester) async {
    await _pumpScreen(
      tester,
      title: 'Phục hồi cơ bắp',
      child: const _RecoveryScenarioPreview(
        bars: [
          ('Ngực', .69),
          ('Lưng', .62),
          ('Vai', .55),
          ('Tay', .51),
          ('Đùi', .43),
          ('Bắp chân', .38),
        ],
        suggestions: [
          _SuggestionPreviewData(
            icon: Icons.schedule_outlined,
            color: Color(0xFFF9A825),
            title: 'Pull Day',
            body:
                'Lưng trong Pull Day vẫn đang hồi phục. Hãy cân nhắc tập muộn hơn hôm nay.',
          ),
          _SuggestionPreviewData(
            icon: Icons.do_not_disturb_alt_outlined,
            color: Color(0xFFD32F2F),
            title: 'Leg Day',
            body:
                'Đùi trong Leg Day cần thêm thời gian hồi phục. Hãy cân nhắc tập nhẹ hơn.',
          ),
        ],
      ),
      allowScroll: true,
    );
    await _golden(tester, '11_recovery_no_routine_ready.png');
  });
}

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

Future<void> _setPhoneSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required String title,
  required Widget child,
  bool allowScroll = false,
}) async {
  await _setPhoneSurface(tester);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _screenKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _reviewTheme,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, appChild) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 24),
            textScaler: TextScaler.noScaling,
          ),
          child: appChild!,
        ),
        home: _ReviewScreen(
          title: title,
          allowScroll: allowScroll,
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ThemeData get _reviewTheme {
  final base = ThemeData.light(useMaterial3: true).textTheme.copyWith(
    displayLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 57),
    headlineMedium: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
    titleLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
    titleMedium: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    bodyLarge: const TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 16,
      height: 1.5,
    ),
    bodyMedium: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
    bodySmall: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
    labelLarge: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
    labelMedium: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    labelSmall: const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 11,
      letterSpacing: .5,
    ),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryBlueLight,
      surface: bgLight,
      surfaceContainer: surfaceLight,
      surfaceContainerHighest: const Color(0xFFEEEEEE),
      onPrimary: textWhite,
      onSurface: textBlack,
      onSurfaceVariant: textGrayLight,
      outline: const Color(0xFF72777A),
      outlineVariant: Colors.grey.shade300,
      error: errorRedLight,
      onError: textWhite,
      errorContainer: errorRedLight.withValues(alpha: .1),
      onErrorContainer: errorRedLight,
    ),
    textTheme: base.apply(
      fontFamily: 'Roboto',
      bodyColor: textBlack,
      displayColor: textBlack,
    ),
    extensions: const [gymColorsLight],
    cardTheme: CardThemeData(shape: AppShapes.medium, color: surfaceLight),
    dialogTheme: DialogThemeData(
      shape: AppShapes.large,
      backgroundColor: surfaceLight,
    ),
  );
}

Future<void> _captureBanner(
  WidgetTester tester, {
  required String fileName,
  required String screenTitle,
  required String title,
  required String body,
  required String action,
  required IconData icon,
  Color? accent,
}) async {
  await _pumpScreen(
    tester,
    title: screenTitle,
    child: const _DashboardBackdrop(),
  );
  final context = tester.element(find.byType(_DashboardBackdrop));
  GymTopNotification.show(
    context,
    icon: icon,
    accentColor: accent ?? Theme.of(context).colorScheme.primary,
    semanticLabel: '$title. $body',
    customBody: Text('$title\n$body', textAlign: TextAlign.left),
    actionLabel: action,
    onAction: () {},
    duration: const Duration(hours: 1),
    haptic: false,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await _golden(tester, fileName);
  GymTopNotification.clear();
  await tester.pump();
}

Future<void> _captureRankDialog(
  WidgetTester tester, {
  required String fileName,
  required String title,
  required String dialogTitle,
  required String rankName,
  required String body,
  required String badgeAsset,
  required Color accent,
}) async {
  await _pumpScreen(tester, title: title, child: const _DashboardBackdrop());
  final context = tester.element(find.byType(_DashboardBackdrop));
  await tester.runAsync(() => precacheImage(AssetImage(badgeAsset), context));
  final dialog = GymDialog.showCustom<bool>(
    context: context,
    barrierDismissible: false,
    titleWidget: Text(
      dialogTitle,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge,
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 132,
          height: 132,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .1),
            shape: BoxShape.circle,
          ),
          child: Image.asset(badgeAsset, fit: BoxFit.contain),
        ),
        const SizedBox(height: 16),
        Text(
          rankName,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: accent),
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
        child: const Text('Đóng'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
        child: const Text('Xem xếp hạng'),
      ),
    ],
  );
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1));
  await _golden(tester, fileName);
  Navigator.of(context, rootNavigator: true).pop(false);
  await tester.pumpAndSettle();
  await dialog;
}

Future<void> _golden(WidgetTester tester, String fileName) => expectLater(
  find.byKey(_screenKey),
  matchesGoldenFile('$_goldenRoot/$fileName'),
);

class _ReviewScreen extends StatelessWidget {
  const _ReviewScreen({
    required this.title,
    required this.child,
    required this.allowScroll,
  });

  final String title;
  final Widget child;
  final bool allowScroll;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: const EdgeInsets.all(16), child: child);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: allowScroll ? SingleChildScrollView(child: content) : content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Nhà'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Tập'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}

class _DashboardBackdrop extends StatelessWidget {
  const _DashboardBackdrop();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Xin chào, Minh', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      Text(
        'Sẵn sàng cho buổi tập hôm nay?',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mục tiêu tuần',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const LinearProgressIndicator(value: .72),
              const SizedBox(height: 8),
              const Text('3/4 buổi tập đã hoàn thành'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Card(
        child: ListTile(
          leading: Icon(Icons.calendar_today_outlined),
          title: Text('Buổi tập tiếp theo'),
          subtitle: Text('Upper Body · 18:30'),
          trailing: Icon(Icons.chevron_right),
        ),
      ),
    ],
  );
}

class _HydrationAchievementPreview extends StatelessWidget {
  const _HydrationAchievementPreview();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.water_drop, size: 42, color: Color(0xFF2196F3)),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Đã đạt mục tiêu nước',
                    style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.check_circle, size: 18, color: Color(0xFF1976D2)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '2,5 / 2,5 L',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const LinearProgressIndicator(value: 1),
            ],
          ),
        ),
      ),
    ],
  );
}

class _RecoveryOverviewPreview extends StatelessWidget {
  const _RecoveryOverviewPreview();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _SectionHeaderPreview(title: 'Trạng thái Phục hồi', showInfo: true),
      const SizedBox(height: 12),
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: const [
              _RecoveryBarPreview(label: 'Ngực', value: .92),
              _RecoveryBarPreview(label: 'Lưng', value: .81),
              _RecoveryBarPreview(label: 'Vai', value: .73),
              _RecoveryBarPreview(label: 'Tay', value: .64),
              _RecoveryBarPreview(label: 'Đùi', value: .47),
              _RecoveryBarPreview(label: 'Bắp chân', value: .38),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      _RecoveryRecommendationPreview(
        suggestions: [
          const _SuggestionPreviewData(
            icon: Icons.check_circle_outline,
            color: Color(0xFF2E7D32),
            title: 'Upper Body',
            body: 'Upper Body phù hợp với các nhóm cơ đã sẵn sàng tập.',
          ),
          _SuggestionPreviewData(
            icon: Icons.do_not_disturb_alt_outlined,
            color: Theme.of(context).colorScheme.error,
            title: 'Leg Day',
            body:
                'Đùi trong Leg Day cần thêm thời gian hồi phục. Hãy cân nhắc tập nhẹ hơn hoặc đổi nhóm cơ.',
          ),
        ],
      ),
    ],
  );
}

class _RecoveryBarPreview extends StatelessWidget {
  const _RecoveryBarPreview({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final color = value >= .8
        ? const Color(0xFF2E7D32)
        : value >= .5
        ? const Color(0xFFF9A825)
        : Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: value,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 34, child: Text('${(value * 100).round()}%')),
        ],
      ),
    );
  }
}

class _RecommendationPreviewTile extends StatelessWidget {
  const _RecommendationPreviewTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right, color: color, size: 24),
      ],
    ),
  );
}

class _SuggestionPreviewData {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _SuggestionPreviewData({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

class _SectionHeaderPreview extends StatelessWidget {
  final String title;
  final bool showInfo;

  const _SectionHeaderPreview({required this.title, this.showInfo = false});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 4,
        height: 34,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1976D2), Color(0xFF00A896)],
          ),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      if (showInfo)
        IconButton(
          tooltip: 'Chi tiết',
          onPressed: () {},
          icon: const Icon(Icons.info_outline, color: Color(0xFF1976D2)),
        ),
    ],
  );
}

class _RecoveryRecommendationPreview extends StatelessWidget {
  final List<_SuggestionPreviewData> suggestions;

  const _RecoveryRecommendationPreview({required this.suggestions});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _SectionHeaderPreview(
        title: 'Routine phù hợp với mức phục hồi',
        showInfo: true,
      ),
      const SizedBox(height: 12),
      for (var index = 0; index < suggestions.length; index++) ...[
        if (index > 0) const SizedBox(height: 10),
        _RecommendationPreviewTile(
          icon: suggestions[index].icon,
          color: suggestions[index].color,
          title: suggestions[index].title,
          body: suggestions[index].body,
        ),
      ],
    ],
  );
}

class _RecoveryScenarioPreview extends StatelessWidget {
  final List<(String, double)> bars;
  final List<_SuggestionPreviewData> suggestions;

  const _RecoveryScenarioPreview({
    required this.bars,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _SectionHeaderPreview(title: 'Trạng thái Phục hồi', showInfo: true),
      const SizedBox(height: 12),
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (final bar in bars)
                _RecoveryBarPreview(label: bar.$1, value: bar.$2),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      _RecoveryRecommendationPreview(suggestions: suggestions),
    ],
  );
}

class _RecoveryWarningPreview extends StatelessWidget {
  const _RecoveryWarningPreview();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Push Day', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('7 bài tập · Khoảng 55 phút'),
              const SizedBox(height: 16),
              const LinearProgressIndicator(value: .58),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      const _RecommendationPreviewTile(
        icon: Icons.swap_horiz,
        color: Color(0xFF1976D2),
        title: 'Pull Day',
        body:
            'Ngực, vai cần thêm thời gian hồi phục. Pull Day phù hợp hơn cho hôm nay.',
      ),
    ],
  );
}
