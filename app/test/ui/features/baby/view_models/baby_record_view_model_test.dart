import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/repositories/baby_record_repository.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_home_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_record_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_statistics_view_model.dart';

import '../../../../support/fake_http.dart';
import '../../../../support/fake_token_storage.dart';
import '../../../../support/s7_fixtures.dart';

/// 里程碑与就诊同住一个仓库却分成两个 provider，正是因为失效范围不一样：里程碑的时间轴
/// 挂在疫苗那条统计上，就诊记录**谁都不读**（费用只是记录，不同步生成流水，§4.4.5）。
/// 两者合成一个 provider 就会让「记一次看病」白白拽起三张图。
void main() {
  late _Builds builds;
  late ScriptedHttp http;

  /// 见 `baby_growth_view_model_test.dart` 里同名变量的说明。
  late ResponseBody Function(RequestOptions) script;

  /// 写操作先拦下来：后端写完只回一个空 `data`，按路径把读那份列表回给写请求，
  /// 客户端会拿它当写响应去解析，报「服务器返回的内容无法识别」。
  ResponseBody online(RequestOptions options) {
    if (options.method != 'GET') return envelope(data: null);

    return switch (options.uri.path) {
      '/api/v1/baby-milestones' => envelope(
        data: [
          milestoneFixture().toJson(),
          milestoneFixture(id: 401, title: '第一颗牙').toJson(),
        ],
      ),
      '/api/v1/baby-medicals' => envelope(data: [medicalFixture().toJson()]),
      _ => envelope(data: null),
    };
  }

  ProviderContainer open() {
    builds = _Builds();
    script = online;
    http = ScriptedHttp((options) => script(options));
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
        babyRecordRepositoryProvider.overrideWithValue(
          BabyRecordRepository(
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
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> rereadOthers(ProviderContainer container) async {
    await container.read(babyHomeViewModelProvider.future);
    await container.read(babyStatisticsViewModelProvider(null).future);
  }

  Future<void> warm(ProviderContainer container) async {
    await container.read(babyMilestoneViewModelProvider.future);
    await container.read(babyMedicalViewModelProvider.future);
    await rereadOthers(container);
    expect([builds.home, builds.statistics], [1, 1]);
  }

  BabyMilestoneViewModel milestones(ProviderContainer container) =>
      container.read(babyMilestoneViewModelProvider.notifier);

  BabyMedicalViewModel medicals(ProviderContainer container) =>
      container.read(babyMedicalViewModelProvider.notifier);

  MilestoneDraft milestoneDraft() =>
      MilestoneDraft(babyId: 1, occurDate: DateTime(2026, 9, 12), title: '会走了');

  MedicalDraft medicalDraft() => MedicalDraft(
    babyId: 1,
    visitDate: DateTime(2026, 9, 12),
    hospital: '市妇幼保健院',
  );

  group('里程碑只影响统计那一条时间轴', () {
    test('记一条：统计重取，总览一动也不动', () async {
      final container = open();
      await warm(container);

      expect(await milestones(container).create(milestoneDraft()), isNull);
      await rereadOthers(container);

      expect(builds.statistics, 2);
      expect(builds.home, 1, reason: '总览上没有里程碑这一块');
    });

    test('改一条与删一条走同一条路', () async {
      final container = open();
      await warm(container);

      await milestones(container).save(400, milestoneDraft());
      await milestones(container).remove(400);
      await rereadOthers(container);

      expect(builds.statistics, 2, reason: '两次写各失效一次，读回来只重算一次');
      expect(builds.home, 1);
    });

    test('服务端拒了那次写：一个都不重取，错误原样交给调用方', () async {
      final container = open();
      await warm(container);
      script = (_) => envelope(code: 'VALIDATION_ERROR', message: '发生日期不能晚于今天');

      final error = await milestones(container).create(milestoneDraft());
      await rereadOthers(container);

      expect(error, '发生日期不能晚于今天');
      expect([builds.home, builds.statistics], [1, 1]);
    });

    test('写成功后重拉的是**全量**那份，不带 babyId', () async {
      final container = open();
      await container.read(babyMilestoneViewModelProvider.future);

      await milestones(container).create(milestoneDraft());

      // 首拉、新建、写完重拉三次都不带查询串：重拉要的是全家庭那份。
      expect(http.calls.map((c) => c.query), [
        <String, String>{},
        <String, String>{},
        <String, String>{},
      ]);
      expect(
        container.read(babyMilestoneViewModelProvider).requireValue,
        hasLength(2),
      );
    });

    test('重拉失败：状态改成错误，调用方照样拿到那句文案', () async {
      final container = open();
      await container.read(babyMilestoneViewModelProvider.future);
      script = (options) =>
          options.method == 'GET' ? gateway() : envelope(data: null);

      final error = await milestones(container).create(milestoneDraft());

      expect(error, '服务器暂时不可用，请稍后重试');
      expect(container.read(babyMilestoneViewModelProvider).hasError, isTrue);
    });
  });

  group('就诊记录谁都不影响', () {
    test('增改删三条写完全不动别的 provider', () async {
      final container = open();
      await warm(container);

      expect(await medicals(container).create(medicalDraft()), isNull);
      expect(await medicals(container).save(500, medicalDraft()), isNull);
      expect(await medicals(container).remove(500), isNull);
      await rereadOthers(container);

      // 费用只是记录，不同步生成流水（§4.4.5）——记一次看病不该拽起统计页那两张图。
      expect([builds.home, builds.statistics], [1, 1]);
    });

    test('写成功后重拉全量，编辑表单靠它按 id 回填', () async {
      final container = open();
      await container.read(babyMedicalViewModelProvider.future);

      await medicals(container).save(500, medicalDraft());

      // 首拉、保存、写完重拉三次都不带查询串：重拉要的是全家庭那份。
      expect(http.calls.map((c) => c.query), [
        <String, String>{},
        <String, String>{},
        <String, String>{},
      ]);
      expect(medicals(container).byId(500)?.costAmount, '128.50');
      expect(medicals(container).byId(999), isNull);
    });
  });
}

class _Builds {
  int home = 0;
  int statistics = 0;
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
