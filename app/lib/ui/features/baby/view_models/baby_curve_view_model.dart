import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/baby_growth.dart';
import '../../../../data/repositories/baby_curve_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../auth/view_models/auth_view_model.dart';

/// 曲线页要的那一次读：哪个宝宝、哪个指标。参数化成 record 是为了让切指标只换一个键，
/// 而不去 `invalidate` 整页——换指标只是换一条线，页面上那五个 chips 不该跟着闪一下加载态。
typedef BabyCurveQuery = ({int babyId, String metric});

/// 界面上那排 chips 的取值，顺序即显示顺序。
///
/// **`WEIGHT_LENGTH` 不在其中**（§1.4 第 23 条）：它是服务端按年龄选的表（2 岁以下用身长），
/// 不是用户能选的指标——响应里的 `standardMetric` 会说清实际用了哪一张。
const List<String> growthMetrics = <String>[
  'HEIGHT',
  'WEIGHT',
  'WEIGHT_HEIGHT',
  'BMI',
  'HEAD_CIRCUMFERENCE',
];

/// 路由不带 `?metric=` 时用它，与后端的缺省一致。
const String defaultGrowthMetric = 'HEIGHT';

BabyCurveQuery curveQueryFor(int babyId, String? metric) =>
    (babyId: babyId, metric: metric ?? defaultGrowthMetric);

/// §4.4.3 的生长曲线。只读一条：实测点、每点的百分位档与整张标准表都由服务端算好送来，
/// 这里只把响应交给页面——前端一个百分位都不许自己算（§3.10 第 7 条）。
class BabyCurveViewModel extends AsyncNotifier<BabyCurve?> {
  BabyCurveViewModel(this.query);

  final BabyCurveQuery query;

  @override
  Future<BabyCurve?> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return null;
    }
    return _load();
  }

  /// 离线横幅上的「重试」。曲线页不做快照（§5.4），所以这里没有缓存回落可走。
  Future<void> refresh() async {
    try {
      state = AsyncData(await _load());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<BabyCurve> _load() =>
      _repository.load(babyId: query.babyId, metric: query.metric);

  BabyCurveRepository get _repository =>
      ref.read(babyCurveRepositoryProvider);
}

final babyCurveViewModelProvider =
    AsyncNotifierProvider.family<
      BabyCurveViewModel,
      BabyCurve?,
      BabyCurveQuery
    >(BabyCurveViewModel.new);
