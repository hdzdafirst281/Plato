import 'package:injectable/injectable.dart';
import '../../data/models/gamification_models.dart';
import '../../data/repositories/gamification_repository.dart';

@injectable
class GetLeaderboardUseCase {
  final GamificationRepository _repository;

  GetLeaderboardUseCase(this._repository);

  Future<List<LeaderboardEntry>> execute({bool forceRefresh = false}) async {
    return await _repository.getLeaderboard(forceRefresh: forceRefresh);
  }
}
