import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/core/date_format.dart';
import '../models/cat.dart';
import '../services/api_client.dart';

/// 猫昵称、性别、生日…一份还没提交成功的表单值。手写而不是 freezed：它只被拼成请求体，
/// 从不被解析，`copyWith` 与 `==` 对它没有意义（口径同 `RecurringRuleDraft`）。
///
/// 新增与改动共用这一份：后端 `CatCreateRequest` 与 `CatUpdateRequest` 九个字段逐字相同。
class CatDraft {
  const CatDraft({
    required this.name,
    required this.gender,
    this.birthday,
    required this.birthdayEstimated,
    this.breed,
    this.weightKg,
    required this.neutered,
    this.remark,
  });

  final String name;
  final String gender;
  final DateTime? birthday;

  /// 必填的布尔：后端那一栏是原始 `boolean`，请求体里缺这个键会被反序列化直接拒掉（400），
  /// 所以它不能做成可空字段让调用方漏传。
  final bool birthdayEstimated;

  final String? breed;

  /// 字符串原样发出，与金额同一条理由：后端是 `BigDecimal`，补零归一化只是多一处口径。
  final String? weightKg;

  final String neutered;
  final String? remark;

  /// 可空字段**照样带进 body**：`PATCH` 在本项目是整份表单覆盖，漏传等于「保留旧值」，
  /// 而用户把生日或备注删空了就该真的删空（§8）。
  Map<String, dynamic> toJson() {
    final born = birthday;
    return {
      'name': name,
      'gender': gender,
      'birthday': born == null ? null : formatDate(born),
      'birthdayEstimated': birthdayEstimated,
      'breed': breed,
      'weightKg': weightKg,
      'neutered': neutered,
      'remark': remark,
    };
  }
}

/// §4.3.1 的猫档案。**不接本地缓存**——离线时那份旧档案列表由总览快照负责（`CatOverviewRepository`），
/// 这里再造一个缓存就会出现两个「上次成功加载」的时间戳。
class CatRepository {
  CatRepository({required this._api});

  final ApiClient _api;

  /// 缺省只回未归档的（§8 原话）。归档列表那一屏自己传 `includeArchived: true`。
  Future<List<Cat>> list({bool includeArchived = false}) async {
    final rows = await _api.getList(
      '/cats',
      query: {'includeArchived': includeArchived},
    );
    return rows.map(Cat.fromJson).toList();
  }

  Future<void> create(CatDraft draft) => _api.post('/cats', body: draft.toJson());

  Future<void> update(int id, CatDraft draft) =>
      _api.patch('/cats/$id', body: draft.toJson());

  /// 归档与恢复是同一条端点：后端按当前状态判方向，所以这里没有一个 `bool archived` 参数，
  /// 界面上那句按钮文案得自己根据 `Cat.archived` 出。
  Future<void> toggle(int id) => _api.patch('/cats/$id/archive');

  Future<void> remove(int id) => _api.delete('/cats/$id');

  /// §4.3.1 / S10 档案照片：上传端点回整份更新后的档案，这里与创建一样只确认成功。
  /// 字节来自客户端压缩后的文件（image_picker + flutter_image_compress），≤ 5 MB。
  Future<void> uploadPhoto(int id, Uint8List bytes, String filename) =>
      _api.upload('/cats/$id/photo', bytes: bytes, filename: filename);

  /// 清掉照片并删服务端文件。
  Future<void> clearPhoto(int id) => _api.delete('/cats/$id/photo');
}

final catRepositoryProvider = Provider<CatRepository>(
  (ref) => CatRepository(api: ref.watch(apiClientProvider)),
);
