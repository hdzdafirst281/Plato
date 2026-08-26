import 'package:injectable/injectable.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/repositories/gamification_repository.dart';

@injectable
class ClaimQuestRewardUseCase {
  final GamificationRepository _gamificationRepo;
  final AuthRepository _authRepo;

  ClaimQuestRewardUseCase(this._gamificationRepo, this._authRepo);

  Future<void> execute(String questId) async {
    final earnedXp = await _gamificationRepo.claimQuestReward(questId);
    if (earnedXp > 0) {
      final currentProfile = _authRepo.getProfile();
      final updatedProfile = currentProfile.copyWith(
        experiencePoints: currentProfile.experiencePoints + earnedXp,
      );
      await _authRepo.saveProfile(updatedProfile);
      _gamificationRepo.updateStatsAfterXpGain(updatedProfile);
    }
  }
}
