import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/baby_vaccine.dart';
import 'package:homeledger/data/models/pending_reminder.dart';
import 'package:homeledger/data/repositories/baby_vaccine_plan_repository.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_home_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_statistics_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_vaccine_record_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_vaccine_view_model.dart';
import 'package:homeledger/ui/features/settings/view_models/reminder_view_model.dart';

import '../../../../support/fake_http.dart';
import '../../../../support/fake_token_storage.dart';
import '../../../../support/s7_fixtures.dart';

/// 应种清单这一层的写入方。它的失效清单是**四处**，比身高体重那一层多一处接种记录
/// ——标记态是接种记录回写的前提（§4.4.4）。四处一漏的症状是「标了跳过，回去看清单还是灰的」。
void main() {
  late _Builds builds;
  late ScriptedHttp http;

  /// 见 `baby_growth_view_model_test.dart` 里同名变量的说明。
  late ResponseBody Function(RequestOptions) script;

  ResponseBody online(RequestOptions options) =>
      options.method == 'GET' &&
          options.uri.path == '/api/v1/baby-vaccine-plans'
      ? envelope(
          data: [
            planFixture().toJson(),
            planFixture(id: 201, doseNo: '2').toJson(),
          ],
        )
      : envelope(data: null);

  ProviderContainer open() {
    builds = _Builds();
    script = online;
    http = ScriptedHttp((options) => script(options));
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
        babyVaccinePlanRepositoryProvider.overrideWithValue(
          BabyVaccinePlanRepository(
            api: ApiClient(
              storage: FakeTokenStorage(),
              adapter: http,
              origin: 'http://test.local',
            ),
          ),
        ),
        babyHomeViewModelProvider.overrideWith(() => _StubHome(builds)),
        babyStatisticsViewModelProvider.overrideWith2(
          (_) => _StubStatistics(builds),
        ),
        babyVaccineRecordViewModelProvider.overrideWith(
          () => _StubVaccineRecord(builds),
        ),
        pendingReminderViewModelProvider.overrideWith(
          () => _StubPending(builds),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> rereadAll(ProviderContainer container) async {
    await container.read(babyHomeViewModelProvider.future);
    await container.read(babyStatisticsViewModelProvider(null).future);
    await container.read(babyVaccineRecordViewModelProvider.future);
    await container.read(pendingReminderViewModelProvider.future);
  }

  Future<void> warm(ProviderContainer container) async {
    await container.read(babyVaccineViewModelProvider.future);
    await rereadAll(container);
    expect(
      [builds.home, builds.statistics, builds.record, builds.pending],
      [1, 1, 1, 1],
    );
  }

  Future<List<int>> downstream(ProviderContainer container) async {
    await rereadAll(container);
    return [builds.home, builds.statistics, builds.record, builds.pending];
  }

  BabyVaccineViewModel notifier(ProviderContainer container) =>
      container.read(babyVaccineViewModelProvider.notifier);

  ManualPlanDraft draft() => ManualPlanDraft(
    babyId: 1,
    vaccineName: '肺炎疫苗',
    doseNo: '1',
    dueDate: DateTime(2026, 10, 1),
  );

  group('四处下游一个都不能漏', () {
    test('标记跳过：总览、统计、接种记录、待提醒全重取', () async {
      final container = open();
      await warm(container);

      expect(await notifier(container).mark(200, 'SKIPPED', '医生建议延后'), isNull);

      expect(await downstream(container), [2, 2, 2, 2]);
    });

    test('撤销标记：与标记走同一条路，同样四处', () async {
      // 撤销把那一行退回 PENDING，接种记录的回写前提、完成率与提醒都跟着变。
      final container = open();
      await warm(container);

      expect(await notifier(container).mark(200, 'PENDING', null), isNull);

      expect(await downstream(container), [2, 2, 2, 2]);
    });

    test('手动新增自费项：四处全重取', () async {
      final container = open();
      await warm(container);

      expect(await notifier(container).createManual(draft()), isNull);

      expect(await downstream(container), [2, 2, 2, 2]);
    });

    test('删一条：四处也全重取', () async {
      final container = open();
      await warm(container);

      expect(await notifier(container).remove(201), isNull);

      expect(await downstream(container), [2, 2, 2, 2]);
    });

    test('服务端拒了那次写：一处都不重取，错误原样交给调用方', () async {
      final container = open();
      await warm(container);
      script = (_) => envelope(code: 'VALIDATION_ERROR', message: '已在应种清单里');

      final error = await notifier(container).createManual(draft());

      expect(error, '已在应种清单里');
      expect(await downstream(container), [1, 1, 1, 1]);
    });
  });

  group('写了再重拉', () {
    test('写成功后重拉的是**全量**那份，不带 babyId', () async {
      final container = open();
      await container.read(babyVaccineViewModelProvider.future);

      await notifier(container).remove(201);

      // 首拉、删除、删完重拉三次都不带查询串：重拉要的是全家庭那份。
      expect(http.calls.map((c) => c.query), [
        <String, String>{},
        <String, String>{},
        <String, String>{},
      ]);
      expect(
        container.read(babyVaccineViewModelProvider).requireValue,
        hasLength(2),
      );
    });

    test('没有单行端点，那一行从这份全量里按 id 找', () async {
      final container = open();
      await container.read(babyVaccineViewModelProvider.future);

      expect(notifier(container).byId(200)?.vaccineName, '乙肝疫苗');
      expect(notifier(container).byId(999), isNull);
    });

    test('重拉失败：状态改成错误，调用方照样拿到那句文案', () async {
      final container = open();
      await container.read(babyVaccineViewModelProvider.future);
      script = (options) =>
          options.method == 'GET' ? gateway() : envelope(data: null);

      final error = await notifier(container).mark(200, 'SKIPPED', '医生建议延后');

      expect(error, '服务器暂时不可用，请稍后重试');
      expect(container.read(babyVaccineViewModelProvider).hasError, isTrue);
    });
  });

  group('预置整串保存（createManualSeries）', () {
    List<ManualPlanDraft> series(int count) => [
      for (var i = 1; i <= count; i++)
        ManualPlanDraft(
          babyId: 1,
          vaccineName: '五联疫苗',
          doseNo: '$i',
          dueDate: DateTime(2026, 9 + i),
        ),
    ];

    Iterable<HttpCall> posts(List<HttpCall> calls) =>
        calls.where((c) => c.method == 'POST');
    Iterable<HttpCall> lists(List<HttpCall> calls) => calls.where(
      (c) => c.method == 'GET' && c.path == '/api/v1/baby-vaccine-plans',
    );

    test('四剂全成功：逐条 POST，清单只重拉一次', () async {
      final container = open();
      await container.read(babyVaccineViewModelProvider.future);
      final base = http.calls.length;

      expect(await notifier(container).createManualSeries(series(4)), isNull);

      final writes = http.calls.sublist(base);
      expect(posts(writes).length, 4);
      expect(lists(writes).length, 1);
      // POST 的体确实是那四剂，顺序不乱。
      expect(
        [for (final c in posts(writes)) (c.body as Map)['doseNo']],
        ['1', '2', '3', '4'],
      );
    });

    test('第 3 剂被拒：已落库的前两剂必须被重拉显出，错误文案照旧返回', () async {
      // 回归：半途失败不重拉的话，弹层的「已在清单」读的还是陈旧列表，
      // 用户重试必被 assertKeyFree 拒回第 1 剂，永远补不完。
      final container = open();
      await warm(container); // 先建四处下游的基线，再对比扇出后的计数
      var creates = 0;
      script = (options) {
        if (options.method == 'POST') {
          creates++;
          return creates == 3
              ? envelope(code: 'VALIDATION_ERROR', message: '该疫苗第 3 剂已在应种清单里')
              : envelope(data: null);
        }
        return online(options);
      };

      final error = await notifier(container).createManualSeries(series(4));

      expect(error, '该疫苗第 3 剂已在应种清单里');
      expect(creates, 3); // 第 4 剂不再发
      expect(lists(http.calls).length, 2); // 首拉 + 失败后重拉
      expect(container.read(babyVaccineViewModelProvider).hasValue, isTrue);
      // 失败也是写：四处下游同样要扇出一次。
      expect(await downstream(container), [2, 2, 2, 2]);
    });

    test('全写成功后重拉挂了：拿到重拉的文案且状态变错误', () async {
      final container = open();
      await container.read(babyVaccineViewModelProvider.future);
      script = (options) =>
          options.method == 'GET' ? gateway() : envelope(data: null);

      final error = await notifier(container).createManualSeries(series(2));

      expect(error, '服务器暂时不可用，请稍后重试');
      expect(container.read(babyVaccineViewModelProvider).hasError, isTrue);
    });
  });
}

class _Builds {
  int home = 0;
  int statistics = 0;
  int record = 0;
  int pending = 0;
}

class _AlwaysSignedIn extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

class _StubHome extends BabyHomeViewModel {
  _StubHome(this.builds);

  final _Builds builds;

  @override
  Future<BabyHomeState> build() async {
    builds.home++;
    return const BabyHomeState();
  }
}

class _StubStatistics extends BabyStatisticsViewModel {
  _StubStatistics(this.builds) : super(null);

  final _Builds builds;

  @override
  Future<BabyStatisticsState> build() async {
    builds.statistics++;
    return const BabyStatisticsState();
  }
}

class _StubVaccineRecord extends BabyVaccineRecordViewModel {
  _StubVaccineRecord(this.builds);

  final _Builds builds;

  @override
  Future<List<BabyVaccineRecord>> build() async {
    builds.record++;
    return const [];
  }
}

class _StubPending extends PendingReminderViewModel {
  _StubPending(this.builds);

  final _Builds builds;

  @override
  Future<List<PendingReminder>> build() async {
    builds.pending++;
    return const [];
  }
}
