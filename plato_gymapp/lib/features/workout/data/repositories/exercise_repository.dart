import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos.dart';
import '../../../../core/database/entities.dart';

@lazySingleton
class ExerciseRepository {
  final AppDatabase _db;

  ExerciseDao get _exerciseDao => _db.exerciseDao;

  ExerciseRepository(this._db);

  // 1. OFFLINE-FIRST: Lấy luồng dữ liệu (Stream) từ Floor Database
  Stream<List<Exercise>> get exercisesStream => _exerciseDao.watchAllExercises();

  // 2. TÌM KIẾM OFFLINE 
  Future<List<Exercise>> searchExercises(String query) async {
    return _exerciseDao.searchExercisesLocal("%$query%");
  }

  // 3. TẠO / CẬP NHẬT BÀI TẬP CUSTOM (Chỉ lưu Local)
  Future<void> saveCustomExercise(Exercise exercise) async {
    try {
      await _exerciseDao.insertExercise(exercise);
    } catch (e) {
      // Log lỗi nếu cần
    }
  }

  // 4. XÓA BÀI TẬP CUSTOM
  // ĐÃ THÊM: Gọi DAO xóa bài tập tự tạo (An toàn nhờ câu lệnh SQL có 'is_custom = 1')
  Future<void> deleteCustomExercise(String id) async {
    try {
      await _exerciseDao.deleteCustomExerciseById(id);
    } catch (e) {
      // Log lỗi nếu cần
    }
  }

  Future<void> updateUserNoteGlobal(String exerciseId, String note) async {
    try {
      await _exerciseDao.updateUserNote(exerciseId, note);
    } catch (e) {
      // Bỏ qua log lỗi hoặc xử lý tùy logic của bạn
    }
  }
}