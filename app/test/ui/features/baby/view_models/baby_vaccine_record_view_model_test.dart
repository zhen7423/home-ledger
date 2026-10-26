import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/baby_vaccine.dart';
import 'package:homeledger/data/models/pending_reminder.dart';
import 'package:homeledger/data/repositories/baby_vaccine_record_repository.dart';
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

/// 接种记录这一层。它的失效清单与应种清单那一层是**同一批四处**，只是方向相反：
/// 录一条要把应种项回写成 `DONE`，删一条要把它退回 `PENDING`（§4.4.4）。
void main() {
  late _Builds builds;
  late ScriptedHttp http;

  /// 见 `baby_growth_view_model_test.dart` 里同名变量的说明。
  late ResponseBody Function(RequestOptions) script;

  ResponseBody online(RequestOptions options) =>
      options.method == 'GET' &&
          options.uri.path == '/api/v1/baby-vaccine-records'
      ? envelope(
          data: [
            vaccineRecordFixture().toJson(),
            vaccineRecordFixture(id: 301, planId: null, doseNo: '2').toJson(),
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
        babyVaccineRecordRepositoryProvider.overrideWithValue(
          BabyVaccineRecordRepository(
            api: ApiClient(
              storage: FakeTokenStorage(),
              adapter: http,
              origin: 'http://test.local',
            ),
          ),
        ),
        babyVaccineViewModelProvider.overrideWith(() => _StubVaccine(builds)),
        babyHomeViewModelProvider.overrideWith(() => _StubHome(builds)),
        babyStatisticsViewModelProvider.overrideWith2(
          (_) => _StubStatistics(builds),
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
    await container.read(babyVaccineViewModelProvider.future);
    await container.read(babyHomeViewModelProvider.future);
    await container.read(babyStatisticsViewModelProvider(null).future);
    await container.read(pendingReminderViewModelProvider.future);
  }

  Future<void> warm(ProviderContainer container) async {
    await container.read(babyVaccineRecordViewModelProvider.future);
    await rereadAll(container);
    expect(
      [builds.vaccine, builds.home, builds.statistics, builds.pending],
      [1, 1, 1, 1],
    );
  }

  Future<List<int>> downstream(ProviderContainer container) async {
    await rereadAll(container);
    return [builds.vaccine, builds.home, builds.statistics, builds.pending];
  }

  BabyVaccineRecordViewModel notifier(ProviderContainer container) =>
      container.read(babyVaccineRecordViewModelProvider.notifier);

  VaccineRecordDraft draft({int? planId = 200}) => VaccineRecordDraft(
    babyId: 1,
    vaccineName: '乙肝疫苗',
    doseNo: '1',
    givenDate: DateTime(2026, 9, 20),
    planId: planId,
  );

  group('四处下游一个都不能漏', () {
    test('录一条：应种清单被回写成 DONE，四处全重取', () async {
      final container = open();
      await warm(container);

      expect(await notifier(container).create(draft()), isNull);

      expect(await downstream(container), [2, 2, 2, 2]);
    });

    test('改一条：服务端先撤销旧绑定再重新匹配，四处照样全重取', () async {
      // 改疫苗名称或剂次会换一个应种项回写，旧的退回 PENDING——两行都变了。
      final container = open();
      await warm(container);

      expect(await notifier(container).save(300, draft(planId: 201)), isNull);

      expect(await downstream(container), [2, 2, 2, 2]);
    });

    test('删一条：应种项退回 PENDING，四处也全重取', () async {
      final container = open();
      await warm(container);

      expect(await notifier(container).remove(300), isNull);

      expect(await downstream(container), [2, 2, 2, 2]);
    });

    test('服务端拒了那次写：一处都不重取，错误原样交给调用方', () async {
      final container = open();
      await warm(container);
      script = (_) => envelope(code: 'VALIDATION_ERROR', message: '接种日期不能晚于今天');

      final error = await notifier(container).create(draft());

      expect(error, '接种日期不能晚于今天');
      expect(await downstream(container), [1, 1, 1, 1]);
    });
  });

  group('写了再重拉', () {
    test('写成功后重拉的是**全量**那份，不带 babyId', () async {
      final container = open();
      await container.read(babyVaccineRecordViewModelProvider.future);

      await notifier(container).remove(300);

      // 首拉、删除、删完重拉三次都不带查询串：重拉要的是全家庭那份。
      expect(http.calls.map((c) => c.query), [
        <String, String>{},
        <String, String>{},
        <String, String>{},
      ]);
      expect(
        container.read(babyVaccineRecordViewModelProvider).requireValue,
        hasLength(2),
      );
    });

    test('没有单行端点，编辑表单从这份全量里按 id 回填', () async {
      final container = open();
      await container.read(babyVaccineRecordViewModelProvider.future);

      expect(notifier(container).byId(300)?.vaccineName, '乙肝疫苗');
      expect(notifier(container).byId(999), isNull);
    });

    test('重拉失败：状态改成错误，调用方照样拿到那句文案', () async {
      final container = open();
      await container.read(babyVaccineRecordViewModelProvider.future);
      script = (options) =>
          options.method == 'GET' ? gateway() : envelope(data: null);

      final error = await notifier(container).create(draft());

      expect(error, '服务器暂时不可用，请稍后重试');
      expect(
        container.read(babyVaccineRecordViewModelProvider).hasError,
        isTrue,
      );
    });
  });
}

class _Builds {
  int vaccine = 0;
  int home = 0;
  int statistics = 0;
  int pending = 0;
}

class _AlwaysSignedIn extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

class _StubVaccine extends BabyVaccineViewModel {
  _StubVaccine(this.builds);

  final _Builds builds;

  @override
  Future<List<BabyVaccinePlan>> build() async {
    builds.vaccine++;
    return const [];
  }
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

class _StubPending extends PendingReminderViewModel {
  _StubPending(this.builds);

  final _Builds builds;

  @override
  Future<List<PendingReminder>> build() async {
    builds.pending++;
    return const [];
  }
}
