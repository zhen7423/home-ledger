import 'package:homeledger/data/models/baby_statistics.dart';
import 'package:homeledger/data/repositories/baby_statistics_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';

/// 宝宝统计仓库替身。两条端点各记一份调用参数：`?babyId=` 是全 App 唯一能区分
/// 「一个宝宝」与「全家庭」的东西，而它在两个 ViewModel 里走的都是同一条 family 参数，
/// 只有把收件箱里的那个值拿出来看才验得出来。
///
/// 形状照 `fake_baby_repository.dart`，两份都与 `fake_statistics_repository.dart` 同形。
class FakeBabyStatisticsRepository implements BabyStatisticsRepository {
  FakeBabyStatisticsRepository({
    BabyGrowthStatistics? growth,
    BabyVaccineStatistics? vaccine,
  }) : growthResult = growth ?? const BabyGrowthStatistics(),
       vaccineResult = vaccine ?? const BabyVaccineStatistics();

  /// 每次 `growth` 都回它。
  BabyGrowthStatistics growthResult;

  /// 每次 `vaccine` 都回它。
  BabyVaccineStatistics vaccineResult;

  /// 非 null 时两条端点都抛它。离线横幅上的「重试」那一条从这里进来。
  ApiException? error;

  final List<int?> growthQueries = [];
  final List<int?> vaccineQueries = [];

  int get growthCalls => growthQueries.length;

  int get vaccineCalls => vaccineQueries.length;

  @override
  Future<BabyGrowthStatistics> growth({int? babyId}) async {
    growthQueries.add(babyId);
    final thrown = error;
    if (thrown != null) {
      throw thrown;
    }
    return growthResult;
  }

  @override
  Future<BabyVaccineStatistics> vaccine({int? babyId}) async {
    vaccineQueries.add(babyId);
    final thrown = error;
    if (thrown != null) {
      throw thrown;
    }
    return vaccineResult;
  }
}
