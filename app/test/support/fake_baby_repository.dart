import 'dart:typed_data';

import 'package:homeledger/data/models/baby.dart';
import 'package:homeledger/data/repositories/baby_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';

/// 宝宝档案仓库替身。四个写动作的**次数与参数**都留着，因为写完之后「该重取的那些有没有
/// 被拽起来」只能这么断——只看结果状态的话，漏掉一次 invalidate 是看不出来的。
///
/// 形状照 `fake_statistics_repository.dart`：可注入实现 + 记录调用。`implements` 一个具体类
/// 是本项目既有做法，Dart 只要求实现公开成员，那个私有的 `_api` 不构成接口的一部分。
class FakeBabyRepository implements BabyRepository {
  FakeBabyRepository({this.rows = const <Baby>[]});

  /// 每次 `list` 都回它。`includeArchived` 不在这里过滤：真仓库把那一项拼成查询串交给服务端，
  /// 替身这一层要断的是「传没传」，不是「筛得对不对」——后者在后端用例里验。
  List<Baby> rows;

  /// 非 null 时四个写动作抛它。用它断页面上的失败分支：`_write` 只接 `ApiException`。
  ApiException? writeError;

  /// 非 null 时 `list` 抛它。断「写成功了但重拉失败要把状态改成 error」那一条。
  ApiException? listError;

  final List<bool> listQueries = [];
  final List<BabyDraft> creates = [];
  final List<({int id, BabyDraft draft})> updates = [];
  final List<int> toggles = [];
  final List<int> removes = [];

  int get listCalls => listQueries.length;

  @override
  Future<List<Baby>> list({bool includeArchived = false}) async {
    listQueries.add(includeArchived);
    final thrown = listError;
    if (thrown != null) {
      throw thrown;
    }
    return rows;
  }

  @override
  Future<void> create(BabyDraft draft) async {
    creates.add(draft);
    _failIfAsked();
  }

  @override
  Future<void> update(int id, BabyDraft draft) async {
    updates.add((id: id, draft: draft));
    _failIfAsked();
  }

  @override
  Future<void> toggle(int id) async {
    toggles.add(id);
    _failIfAsked();
  }

  @override
  Future<void> remove(int id) async {
    removes.add(id);
    _failIfAsked();
  }

  /// S10 档案照片：两个写动作也进调用记录，语义同其余写操作（可注入失败）。
  final List<({int id, Uint8List bytes, String filename})> photoUploads = [];
  final List<int> photoClears = [];

  @override
  Future<void> uploadPhoto(int id, Uint8List bytes, String filename) async {
    photoUploads.add((id: id, bytes: bytes, filename: filename));
    _failIfAsked();
  }

  @override
  Future<void> clearPhoto(int id) async {
    photoClears.add(id);
    _failIfAsked();
  }

  void _failIfAsked() {
    final thrown = writeError;
    if (thrown != null) {
      throw thrown;
    }
  }
}
