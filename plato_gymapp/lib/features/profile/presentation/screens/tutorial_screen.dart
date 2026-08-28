import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';
import 'package:plato_gymapp/i18n/strings.g.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/designsystem/components/gym_top_bar.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 4, // ĐÃ SỬA: Tăng từ 3 lên 4
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: GymTopBar(
          title: t.common.tutorial_title,
          onBackClick: () => context.pop(),
        ),
        body: SafeArea(
          child: Column(
            children: [
              TabBar(
                isScrollable: true, // Thêm isScrollable để tránh bị ép chữ nếu màn hình nhỏ
                tabAlignment: TabAlignment.start, // Căn lề trái khi scrollable
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorColor: colorScheme.primary,
                dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
                tabs: [
                  Tab(text: t.workout.title_main),
                  Tab(text: t.workout.title_log_main), // NEW: Tab Log Workout
                  Tab(text: t.nutrition.title_main),
                  Tab(text: t.profile.btn_menu_cal),
                ],
              ),
              Expanded(
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _TutorialTabContent(
                      videoPath: 'assets/videos/workout_vid.mp4',
                      title: t.settings.tutorial_workout_title,
                      description: t.settings.tutorial_workout_desc,
                    ),
                    // NEW: Nội dung hướng dẫn Log Workout
                    _TutorialTabContent(
                      videoPath: 'assets/videos/logworkout_vid.mp4',
                      title: t.settings.tutorial_logworkout_title,
                      description: t.settings.tutorial_logworkout_desc,
                    ),
                    _TutorialTabContent(
                      videoPath: 'assets/videos/nutrition_vid.mp4',
                      title: t.settings.tutorial_nutrition_title,
                      description: t.settings.tutorial_nutrition_desc,
                    ),
                    _TutorialTabContent(
                      videoPath: 'assets/videos/calendar_vid.mp4',
                      title: t.settings.tutorial_cal_title,
                      description: t.settings.tutorial_cal_desc,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialTabContent extends StatefulWidget {
  final String videoPath;
  final String title;
  final String description;

  const _TutorialTabContent({
    required this.videoPath,
    required this.title,
    required this.description,
  });

  @override
  State<_TutorialTabContent> createState() => _TutorialTabContentState();
}

class _TutorialTabContentState extends State<_TutorialTabContent> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.setLooping(true);
          // Auto-play khi vào tab
          _controller.play();
        }
      }).catchError((error) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      });
  }

  @override
  void dispose() {
    // Giải phóng bộ nhớ ngay lập tức khi chuyển tab
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height; // Lấy chiều cao màn hình

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            widget.description,
            style: TextStyle(fontSize: 15, height: 1.5, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          
          // Container chứa Video Player ĐÃ FIX CHIỀU CAO
          Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.75, // Giới hạn chiều cao tối đa là 35% màn hình
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 8))
              ]
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: colorScheme.surface,
                child: Center( // Căn giữa video để không bị méo khi thu nhỏ
                  child: AspectRatio(
                    aspectRatio: _isInitialized ? _controller.value.aspectRatio : 16 / 9,
                    child: RepaintBoundary(
                      child: _buildVideoContent(colorScheme),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildVideoContent(ColorScheme colorScheme) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.error_outline, color: colorScheme.error, size: 32),
            const SizedBox(height: 8),
            Text(
              t.common.video_err,
              style: TextStyle(color: colorScheme.error),
            ),
          ],
        ),
      );
    }

    if (_isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          Positioned(
            bottom: 12,
            right: 12,
            child: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, VideoPlayerValue value, child) {
                return GestureDetector(
                  onTap: () {
                    value.isPlaying ? _controller.pause() : _controller.play();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      value.isPlaying ? Symbols.pause : Symbols.play_arrow,
                      color: Colors.white,
                      size: 24,
                      fill: 1.0,
                    ),
                  ),
                );
              },
            ),
          )
        ],
      );
    }

    return Center(
      child: CircularProgressIndicator(color: colorScheme.primary),
    );
  }
}