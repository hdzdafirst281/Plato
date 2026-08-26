import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  // Mặc định ban đầu dark theme
  ThemeCubit() : super(ThemeMode.dark) { 
    _loadTheme();
  }

  static const String _themeKey = 'app_theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Đọc key kiểu String mới
    final themeString = prefs.getString(_themeKey);

    if (themeString != null) {
      switch (themeString) {
        case 'light':
          emit(ThemeMode.light);
          break;
        case 'dark':
          emit(ThemeMode.dark);
          break;
        case 'system':
        default:
          emit(ThemeMode.system);
          break;
      }
    } else {
      // 2. Logic tương thích ngược (Migration)
      // Nếu không tìm thấy key chuỗi mới, thử tìm key boolean cũ của các user phiên bản trước
      final isDarkOld = prefs.getBool('is_dark_theme');
      if (isDarkOld != null) {
        final mappedMode = isDarkOld ? ThemeMode.dark : ThemeMode.light;
        emit(mappedMode);
        
        // Lưu lại theo chuẩn mới để lần sau không phải check key cũ nữa
        await changeTheme(mappedMode);
      }
    }
  }

  Future<void> changeTheme(ThemeMode mode) async {
    emit(mode);
    final prefs = await SharedPreferences.getInstance();
    
    // Chuyển đổi Enum thành String để lưu trữ
    String themeValue;
    switch (mode) {
      case ThemeMode.light:
        themeValue = 'light';
        break;
      case ThemeMode.dark:
        themeValue = 'dark';
        break;
      case ThemeMode.system:
        themeValue = 'system';
        break;
    }
    
    await prefs.setString(_themeKey, themeValue);
  }
}