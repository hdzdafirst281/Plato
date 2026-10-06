import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/designsystem/components/gym_top_bar.dart';
import '../../application/notification_coordinator.dart';
import '../../data/notification_copy.dart';

class NotificationDiagnosticsScreen extends StatefulWidget {
  const NotificationDiagnosticsScreen({super.key});

  @override
  State<NotificationDiagnosticsScreen> createState() =>
      _NotificationDiagnosticsScreenState();
}

class _NotificationDiagnosticsScreenState
    extends State<NotificationDiagnosticsScreen> {
  Map<String, dynamic>? _data;
  bool _busy = false;

  NotificationCoordinator get _service => NotificationCoordinator.instance!;
  String _copy(String key) => NotificationCopy.text(key) ?? '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final data = await _service.diagnostics();
    if (mounted) setState(() => _data = data);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _time(Object? millis) {
    if (millis is! int) return _copy('notifications.status_never');
    final value = DateTime.fromMillisecondsSinceEpoch(millis);
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  String _reason(String value) => _copy(switch (value) {
    'masterDisabled' => 'notifications.suppressed_master_disabled',
    'systemPermissionDenied' => 'notifications.suppressed_permission_denied',
    'categoryDisabled' => 'notifications.suppressed_category_disabled',
    'goalReached' => 'notifications.suppressed_goal_reached',
    'activeWorkout' => 'notifications.suppressed_active_workout',
    'recoveryUnchanged' => 'notifications.suppressed_recovery_unchanged',
    'mergedWorkout' => 'notifications.suppressed_merged_workout',
    'duplicateAutomaticKind' => 'notifications.suppressed_duplicate_kind',
    'dailyLimit' => 'notifications.suppressed_daily_limit',
    'deadlineExpired' => 'notifications.suppressed_deadline_expired',
    'pendingQueueLimit' => 'notifications.suppressed_queue_limit',
    _ => 'notifications.suppressed_deadline_expired',
  });

  String _kindLabel(String value) => _copy(switch (value) {
    'workout' => 'notifications.title_workout_reminder',
    'hydration' => 'notifications.title_hydration_reminder',
    'recovery' => 'notifications.title_recovery_recommendation',
    'streak' => 'notifications.title_streak_at_risk',
    'rank' => 'notifications.title_rank_ending',
    'inactivity' => 'notifications.title_inactivity',
    _ => 'notifications.title_diagnostics',
  });

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final plan = data?['lastPlan'] as Map<String, dynamic>?;
    final suppressed = (plan?['suppressed'] as List?) ?? const [];
    return Scaffold(
      appBar: GymTopBar(
        title: _copy('notifications.title_diagnostics'),
        onBackClick: Navigator.of(context).pop,
      ),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Column(
                      children: [
                        _row(
                          'notifications.lbl_last_reconcile',
                          _time(data['lastReconciledAt']),
                        ),
                        _row(
                          'notifications.lbl_last_background_worker',
                          _time(data['lastBackgroundAt']),
                        ),
                        _row(
                          'notifications.lbl_pending_requests',
                          '${data['pendingCount']}',
                        ),
                        _row(
                          'notifications.lbl_system_permission',
                          _copy(
                            data['permissionGranted'] == true
                                ? 'notifications.status_permission_allowed'
                                : 'notifications.status_permission_blocked',
                          ),
                        ),
                        _row(
                          'notifications.lbl_reconcile_duration',
                          '${data['durationMs'] ?? 0} ms',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _copy('notifications.lbl_suppressed'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (suppressed.isEmpty)
                    const Card(child: ListTile(title: Text('—')))
                  else
                    Card(
                      child: Column(
                        children: [
                          for (final raw in suppressed.take(12))
                            Builder(
                              builder: (context) {
                                final item = Map<String, dynamic>.from(
                                  raw as Map,
                                );
                                return ListTile(
                                  leading: const Icon(Icons.info_outline),
                                  title: Text(
                                    _reason(item['reason'] as String? ?? ''),
                                  ),
                                  subtitle: item['kind'] == null
                                      ? null
                                      : Text(
                                          _kindLabel(item['kind'] as String),
                                        ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _run(_service.reconcileNow),
                    icon: const Icon(Icons.refresh),
                    label: Text(_copy('notifications.btn_rebuild_schedule')),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            if (!await _service.showDiagnosticTestNow()) {
                              await openAppSettings();
                            }
                          }),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(_copy('notifications.btn_test_now')),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            final messenger = ScaffoldMessenger.of(context);
                            final scheduled = await _service
                                .scheduleDiagnosticTest();
                            if (!scheduled) {
                              await openAppSettings();
                              return;
                            }
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _copy('notifications.msg_test_scheduled'),
                                  ),
                                ),
                              );
                            }
                          }),
                    icon: const Icon(Icons.schedule),
                    label: Text(_copy('notifications.btn_test_scheduled')),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _row(String labelKey, String value) => ListTile(
    title: Text(_copy(labelKey)),
    trailing: Text(value, textAlign: TextAlign.end),
  );
}
