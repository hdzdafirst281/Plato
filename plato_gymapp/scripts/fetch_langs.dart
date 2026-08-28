import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';

void _unflatten(Map<String, dynamic> target, String key, dynamic value) {
  final parts = key.split('.');
  Map<String, dynamic> current = target;
  for (int i = 0; i < parts.length - 1; i++) {
    final part = parts[i];
    if (!current.containsKey(part) || current[part] is! Map) {
      current[part] = <String, dynamic>{};
    }
    current = current[part] as Map<String, dynamic>;
  }
  current[parts.last] = value;
}

Map<String, String> _flatten(Map<String, dynamic> json, [String prefix = '']) {
  final result = <String, String>{};
  for (final entry in json.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (entry.value is Map) {
      result.addAll(_flatten(entry.value as Map<String, dynamic>, key));
    } else {
      result[key] = entry.value.toString();
    }
  }
  return result;
}

void main() async {
  const url = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vTC6KX4whrXqy8p0W5IAaVJeZ72Ugcnasau_araWD6OsYwAgN6qz4WgqrvBzd6PJ5IlluOFYVLfYAB5/pub?output=csv';
  
  print('Đang tải bản dịch mới từ Google Sheets...');
  
  try {
    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final csvString = await response.transform(utf8.decoder).join();
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);
      
      if (rows.isEmpty || rows.first.length < 3) {
        print('Định dạng CSV không đúng. Cần ít nhất 3 cột (key, en, vi)');
        return;
      }
      
      final enJson = <String, dynamic>{};
      final viJson = <String, dynamic>{};
      final newEnFlat = <String, String>{};
      final newViFlat = <String, String>{};
      
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row[0] == null || row[0].toString().trim().isEmpty) continue;
        final key = row[0].toString().trim();
        if (key.startsWith('#')) continue;
        
        final enVal = row.length > 1 ? row[1].toString() : '';
        final viVal = row.length > 2 ? row[2].toString() : '';
        
        _unflatten(enJson, key, enVal);
        _unflatten(viJson, key, viVal);
        newEnFlat[key] = enVal;
        newViFlat[key] = viVal;
      }

      // Diff logic
      Map<String, String> oldEnFlat = {};
      final enFile = File('lib/i18n/strings_en.i18n.json');
      if (enFile.existsSync()) {
        final oldData = jsonDecode(enFile.readAsStringSync());
        oldEnFlat = _flatten(oldData);
      }

      final addedKeys = <String>[];
      final removedKeys = <String>[];
      final updatedKeys = <String>[];

      for (final key in newEnFlat.keys) {
        if (!oldEnFlat.containsKey(key)) {
          addedKeys.add(key);
        } else if (oldEnFlat[key] != newEnFlat[key]) {
          updatedKeys.add(key);
        }
      }
      
      for (final key in oldEnFlat.keys) {
        if (!newEnFlat.containsKey(key)) {
          removedKeys.add(key);
        }
      }

      print('-----------------------------------------');
      print('Báo cáo đồng bộ Đa ngôn ngữ:');
      print('\x1B[32m🟢 Thêm mới: ${addedKeys.length} keys\x1B[0m');
      if (addedKeys.isNotEmpty) print('   ${addedKeys.join(", ")}');
      
      print('\x1B[33m🟡 Cập nhật: ${updatedKeys.length} keys\x1B[0m');
      if (updatedKeys.isNotEmpty) print('   ${updatedKeys.join(", ")}');
      
      print('\x1B[31m🔴 Xóa bỏ: ${removedKeys.length} keys\x1B[0m');
      if (removedKeys.isNotEmpty) print('   ${removedKeys.join(", ")}');
      print('-----------------------------------------');
      
      enFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(enJson));
      File('lib/i18n/strings_vi.i18n.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(viJson));
      
      print('Phân tích CSV thành công! Đang tự động gen code...');
      
      final process = Process.runSync('dart', ['run', 'slang']);
      if (process.exitCode == 0) {
        print('Hoàn tất! Các file ngôn ngữ đã được cập nhật chính xác.');
      } else {
        print('Lỗi khi chạy slang:\\n\${process.stderr}');
      }
    } else {
      print('Lỗi khi tải file. Status code: \${response.statusCode}');
    }
  } catch (e) {
    print('Đã có lỗi xảy ra: \$e');
  }
}
