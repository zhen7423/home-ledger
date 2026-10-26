import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/baby_growth.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';

/// §4.4.3 的生长曲线。只读一条：曲线是实测点与标准表的合成结果，没有「保存」这个动作。
///
/// 插值、百分位档与标准表的行选取都在服务端，这一层只把响应原样交给页面去画。
class BabyCurveRepository {
  BabyCurveRepository({required this._api});

  final ApiClient _api;

  /// `metric` 取 `HEIGHT` / `WEIGHT` / `WEIGHT_HEIGHT` / `BMI` / `HEAD_CIRCUMFERENCE`。
  /// 响应里的 `standardMetric` 是服务端实际选中的表名（体重别身高按年龄落到 `WEIGHT_LENGTH`
  /// 或 `WEIGHT_HEIGHT`），界面据它写「2 岁以下按身长」这类说明，所以不拿入参回显。
  Future<BabyCurve> load({required int babyId, required String metric}) async =>
      BabyCurve.fromJson(
        requireData(
          await _api.get(
            '/baby-growths/curve',
            query: {'babyId': babyId, 'metric': metric},
          ),
        ),
      );
}

final babyCurveRepositoryProvider = Provider<BabyCurveRepository>(
  (ref) => BabyCurveRepository(api: ref.watch(apiClientProvider)),
);
