import 'package:homeledger/data/models/cat.dart';
import 'package:homeledger/data/models/cat_statistics.dart';
import 'package:homeledger/data/repositories/cat_overview_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';

/// 总览仓库的替身。视图模型只认 `load()` 一个动词，所以这一份只管把调用方要的那一态吐回去：
/// 在线、来自快照、或者干脆抛——「断网且无快照」在界面上是错误态而不是空态，那条分支
/// 只能从抛异常这一侧进来。
class FakeCatOverviewRepository implements CatOverviewRepository {
  FakeCatOverviewRepository({this.result, this.error});

  final CatOverviewLoadResult? result;

  /// 非 null 时 `load()` 抛它。用 `ApiException` 而不是随便一个异常：
  /// 视图模型的 `refresh()` 只接 `ApiException`，抛别的会让整屏红在测试里而不是在被测代码里。
  final ApiException? error;

  int loadCalls = 0;

  @override
  Future<CatOverviewLoadResult> load() async {
    loadCalls++;
    if (error != null) {
      throw error!;
    }
    return result ?? _emptyResult;
  }
}

const CatOverviewLoadResult _emptyResult = CatOverviewLoadResult(
  <Cat>[],
  null,
  null,
  <CatDueCountdownItem>[],
  fromCache: false,
);
