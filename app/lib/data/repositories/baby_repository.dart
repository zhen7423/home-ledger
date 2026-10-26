import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/core/date_format.dart';
import '../models/baby.dart';
import '../services/api_client.dart';

/// 宝宝档案的一份表单值。手写而不是 freezed：它只被拼成请求体，从不被解析，
/// `copyWith` 与 `==` 对一个还没提交成功的表单没有意义（口径同 `CatDraft`）。
///
/// 新增与编辑共用这一份：后端 `BabyCreateRequest` 与 `BabyUpdateRequest` 六个字段逐字相同。
class BabyDraft {
  const BabyDraft({
    required this.name,
    required this.gender,
    required this.birthDate,
    this.birthHeight,
    this.birthWeight,
    this.remark,
  });

  final String name;
  final String gender;
  final DateTime birthDate;

  /// 三个度量都按字符串原样发出，与金额同一条理由：后端是 `BigDecimal`，
  /// 补零归一化只是多一处口径。
  final String? birthHeight;
  final String? birthWeight;
  final String? remark;

  /// 可空字段**照样带进 body**：`PATCH` 在本项目是整份表单覆盖，漏传等于「保留旧值」，
  /// 而用户把备注删空了就该真的删空（§8）。
  Map<String, dynamic> toJson() => {
    'name': name,
    'gender': gender,
    'birthDate': formatDate(birthDate),
    'birthHeight': birthHeight,
    'birthWeight': birthWeight,
    'remark': remark,
  };
}

/// §4.4.1 的宝宝档案。**不接本地缓存**——离线时那份旧清单由总览快照负责
/// （`BabyOverviewCacheStore`），这里再造一个就会出现两个「上次成功加载」的时间戳。
class BabyRepository {
  BabyRepository({required this._api});

  final ApiClient _api;

  /// 缺省只回未归档的。档案列表的「全部」视图自己传 `includeArchived: true`。
  Future<List<Baby>> list({bool includeArchived = false}) async {
    final rows = await _api.getList(
      '/babies',
      query: {'includeArchived': includeArchived},
    );
    return rows.map(Baby.fromJson).toList();
  }

  Future<void> create(BabyDraft draft) =>
      _api.post('/babies', body: draft.toJson());

  /// 整份覆盖。改了出生日期，服务端在同一事务里整份重算该宝宝的应种清单。
  Future<void> update(int id, BabyDraft draft) =>
      _api.patch('/babies/$id', body: draft.toJson());

  /// 归档与恢复是同一条端点：后端按当前状态判方向，所以这里没有一个 `bool archived` 参数，
  /// 界面上那句按钮文案得自己根据 `Baby.archived` 出。
  Future<void> toggle(int id) => _api.patch('/babies/$id/archive');

  /// 四张记录表里有过任何记录就删不掉，只能归档（§4.4.1）。
  Future<void> remove(int id) => _api.delete('/babies/$id');

  /// §4.4.1 / S10 档案照片，语义同 `CatRepository.uploadPhoto`。
  Future<void> uploadPhoto(int id, Uint8List bytes, String filename) =>
      _api.upload('/babies/$id/photo', bytes: bytes, filename: filename);

  Future<void> clearPhoto(int id) => _api.delete('/babies/$id/photo');
}

final babyRepositoryProvider = Provider<BabyRepository>(
  (ref) => BabyRepository(api: ref.watch(apiClientProvider)),
);
