// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final filesToUpdate = [
    'lib/features/workout/presentation/screens/log_workout_screen.dart',
    'lib/features/workout/presentation/screens/routine_screen.dart',
    'lib/features/workout/presentation/screens/exercise_library_screen.dart',
    'lib/features/workout/presentation/components/workout_shared_ui.dart',
    'lib/features/profile/presentation/screens/settings_screen.dart',
    'lib/features/profile/presentation/screens/profile_screen.dart',
    'lib/features/profile/presentation/screens/account_management_screen.dart',
    'lib/features/nutrition/presentation/screens/nutrition_screen.dart',
    'lib/features/nutrition/presentation/screens/food_encyclopedia_screen.dart',
  ];

  for (final path in filesToUpdate) {
    final file = File(path);
    if (!file.existsSync()) {
      print('File not found: $path');
      continue;
    }

    String content = file.readAsStringSync();

    bool hasChanges = false;
    
    if (content.contains('GymTopNotification.show')) {
      content = content.replaceAll('GymTopNotification.show', 'GymSnackbar.show');
      hasChanges = true;
    }

    if (hasChanges) {
      if (!content.contains('gym_snackbar.dart')) {
        // Add import at the top
        content = "import 'package:plato_gymapp/core/designsystem/components/gym_snackbar.dart';\n$content";
      }
      
      if (!content.contains('GymTopNotification') && content.contains('gym_top_notification.dart')) {
         content = content.replaceAll(RegExp(r"import 'package:plato_gymapp/core/designsystem/components/gym_top_notification.dart';\n?"), "");
         content = content.replaceAll(RegExp(r"import 'package:plato_gymapp/core/designsystem/components/gym_top_notification.dart';\r\n?"), "");
      }
      
      file.writeAsStringSync(content);
      print('Updated $path');
    }
  }
}
