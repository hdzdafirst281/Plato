import 'package:injectable/injectable.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/repositories/gamification_repository.dart';

@injectable
class ResetGamificationUseCase {
  final GamificationRepository _gamificationRepo;
  final AuthRepository _authRepo;

  ResetGamificationUseCase(this._gamificationRepo, this._authRepo);

  Future<void> execute() async {
    await _gamificationRepo.calculateWeeklyStats(
      workoutsList: [],
      userProfileData: _authRepo.getProfile(),
    );
  }
}
