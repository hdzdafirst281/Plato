import 'package:injectable/injectable.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/repositories/gamification_repository.dart';

@injectable
class RefreshGamificationStateUseCase {
  final GamificationRepository _gamificationRepo;
  final AuthRepository _authRepo;

  RefreshGamificationStateUseCase(this._gamificationRepo, this._authRepo);

  Future<void> execute() async {
    await _gamificationRepo.refreshStateFromDb();
    _gamificationRepo.updateStatsAfterXpGain(_authRepo.getProfile());
  }
}
