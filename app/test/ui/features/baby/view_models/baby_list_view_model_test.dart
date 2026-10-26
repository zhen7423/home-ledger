import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/baby_growth.dart';
import 'package:homeledger/data/models/baby_vaccine.dart';
import 'package:homeledger/data/repositories/baby_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_curve_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_home_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_list_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_statistics_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_vaccine_view_model.dart';

import '../../../../support/fake_baby_repository.dart';
import '../../../../support/s7_fixtures.dart';

/// 档案那一组。它是宝宝模块唯一的**写入口**（建档、改档、归档、删除），所以这一份的重点是
/// 失效范围的头一行：哪几个写各自把谁拽起来重取。
///
/// 表格里「改生日要额外失效曲线与应种清单」是两条写之间**唯一**的分别，而它取决于
/// `save()` 里那次日期比较——只写「改了生日」这一条是看不出比较写反了的，所以两条都写。
///
/// 被失效的四个目标不是用假仓库计数的：`babyHome` 与 `babyStatistics` 读的是**同两条**
/// 统计端点，仓库计数分不出是谁重读了一次。这里用重写 `build()` 的计数替身，
/// 数的就是「这个 provider 被重算了几次」，正是失效表要断的那件事。
void main() {
  late _Builds builds;
  late FakeBabyRepository repo;

  BabyDraft draft({DateTime? birthDate, String name = '小明'}) => BabyDraft(
    name: name,
    gender: 'MALE',
    birthDate: birthDate ?? DateTime(2025, 9, 16),
  );

  ProviderContainer open() {
    builds = _Builds();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
        babyRepositoryProvider.overrideWithValue(repo),
        babyHomeViewModelProvider.overrideWith(() => _StubHome(builds)),
        babyStatisticsViewModelProvider.overrideWith2(
          (_) => _StubStatistics(builds),
        ),
        babyVaccineViewModelProvider.overrideWith(() => _StubVaccine(builds)),
        babyCurveViewModelProvider.overrideWith2(
          (query) => _StubCurve(builds, query),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// 先把四张下游和自己的清单都读一遍，把基准定在 1。不读的话 `invalidate` 落在一个
  /// 还没建起来的 provider 上是空动作，后面的计数不论失没失效都是 1。
  Future<void> warm(ProviderContainer container) async {
    await container.read(babyListViewModelProvider.future);
    await container.read(babyHomeViewModelProvider.future);
    await container.read(babyStatisticsViewModelProvider(null).future);
    await container.read(babyVaccineViewModelProvider.future);
    await container.read(
      babyCurveViewModelProvider(curveQueryFor(1, null)).future,
    );
    expect(
      [builds.home, builds.statistics, builds.vaccine, builds.curve],
      [1, 1, 1, 1],
    );
  }

  /// 重新读一遍四个目标，让被置脏的那些当场重算。没被失效的那些照旧回缓存的值。
  Future<void> rereadAll(ProviderContainer container) async {
    await container.read(babyHomeViewModelProvider.future);
    await container.read(babyStatisticsViewModelProvider(null).future);
    await container.read(babyVaccineViewModelProvider.future);
    await container.read(
      babyCurveViewModelProvider(curveQueryFor(1, null)).future,
    );
  }

  BabyListViewModel listNotifier(ProviderContainer container) =>
      container.read(babyListViewModelProvider.notifier);

  setUp(() => repo = FakeBabyRepository(rows: [babyFixture()]));

  group('写完之后谁被拽起来', () {
    test('建档：总览与统计要重取，应种清单整份生成也跟着重取，曲线不动', () async {
      final container = open();
      await warm(container);

      expect(await listNotifier(container).create(draft()), isNull);
      await rereadAll(container);

      expect(builds.home, 2);
      expect(builds.statistics, 2);
      expect(builds.vaccine, 2);
      expect(builds.curve, 1, reason: '新宝宝还没有身高体重，曲线没变');
    });

    test('改名字：只动总览与统计，清单与曲线都不动', () async {
      final container = open();
      await warm(container);

      expect(await listNotifier(container).save(1, draft(name: '小明明')), isNull);
      await rereadAll(container);

      expect(builds.home, 2);
      expect(builds.statistics, 2);
      expect(builds.vaccine, 1);
      expect(builds.curve, 1);
    });

    test('改生日：应种清单整份重算、曲线横轴全变，四个一起重取', () async {
      final container = open();
      await warm(container);

      expect(
        await listNotifier(
          container,
        ).save(1, draft(birthDate: DateTime(2025, 10, 1))),
        isNull,
      );
      await rereadAll(container);

      expect(builds.home, 2);
      expect(builds.statistics, 2);
      expect(builds.vaccine, 2, reason: '应种日期跟着生日平移');
      expect(builds.curve, 2, reason: '横轴是月龄，生日一移整条横轴都变');
    });

    test('归档：清单不重算，但统计按宝宝分组会少一行', () async {
      final container = open();
      await warm(container);

      expect(await listNotifier(container).toggle(1), isNull);
      await rereadAll(container);

      expect(builds.home, 2);
      expect(builds.statistics, 2);
      expect(builds.vaccine, 1);
      expect(builds.curve, 1);
    });

    test('删除：应种清单随档案软删，四个一起重取', () async {
      final container = open();
      await warm(container);

      expect(await listNotifier(container).remove(1), isNull);
      await rereadAll(container);

      expect(builds.home, 2);
      expect(builds.statistics, 2);
      expect(builds.vaccine, 2);
      expect(builds.curve, 1);
    });

    test('服务端拒了那次写：一个都不重取，错误原样交给调用方', () async {
      final container = open();
      await warm(container);
      repo.writeError = const ApiException(
        code: 'VALIDATION_ERROR',
        message: '最多只能建 5 个在册宝宝',
      );

      final error = await listNotifier(container).create(draft());
      await rereadAll(container);

      expect(error, '最多只能建 5 个在册宝宝');
      expect(
        [builds.home, builds.statistics, builds.vaccine, builds.curve],
        [1, 1, 1, 1],
      );
    });
  });

  group('写了再重拉', () {
    test('四个写各自重拉一次整份，且每一次都要归档那一份', () async {
      final container = open();
      await container.read(babyListViewModelProvider.future);
      final notifier = listNotifier(container);

      await notifier.create(draft());
      await notifier.save(1, draft());
      await notifier.toggle(1);
      await notifier.remove(1);

      // 一次首次加载 + 四次写完的重拉
      expect(repo.listCalls, 5);
      // 归档的宝宝同样要能编辑、能恢复，所以每次都带上它们（§4.4.1）。
      expect(repo.listQueries.every((include) => include), isTrue);
    });

    test('写成功了但重拉失败：状态改成错误，调用方照样拿到那句文案', () async {
      final container = open();
      await container.read(babyListViewModelProvider.future);
      repo.listError = const ApiException(
        code: ClientErrorCode.network,
        message: '',
      );

      final error = await listNotifier(container).toggle(1);

      // 不把状态改成错误的话，「写成功了但列表没刷新」会静留在屏上。
      expect(error, '连不上服务器，请检查网络后重试');
      expect(container.read(babyListViewModelProvider).hasError, isTrue);
    });
  });

  group('档案照片（S10）', () {
    test('传照片：走仓库上传、重拉整份清单，总览与统计重取，清单曲线不动', () async {
      final container = open();
      await warm(container);

      final error = await listNotifier(container).setPhoto(
        1,
        Uint8List.fromList([1, 2, 3]),
        'profile.jpg',
      );
      await rereadAll(container);

      expect(error, isNull);
      expect(repo.photoUploads, hasLength(1));
      expect(repo.photoUploads.single.id, 1);
      // warm 里首载过一次，写完重拉是第二次
      expect(repo.listCalls, 2, reason: '写成功后清单整份重拉');
      expect(builds.home, 2);
      expect(builds.statistics, 2);
      expect(builds.vaccine, 1);
      expect(builds.curve, 1);
    });

    test('清照片：走仓库清除并重拉，四个下游同传照片', () async {
      final container = open();
      await warm(container);

      expect(await listNotifier(container).clearPhoto(1), isNull);
      await rereadAll(container);

      expect(repo.photoClears, [1]);
      expect(repo.listCalls, 2);
      expect(builds.home, 2);
      expect(builds.statistics, 2);
    });

    test('传照片被后端拒绝：不重拉、不重取，错误原样交回', () async {
      final container = open();
      await warm(container);
      repo.writeError = const ApiException(
        code: 'BAD_REQUEST',
        message: '照片不能超过 5 MB',
      );

      final error = await listNotifier(container).setPhoto(
        1,
        Uint8List.fromList([1, 2, 3]),
        'profile.jpg',
      );
      await rereadAll(container);

      expect(error, '照片不能超过 5 MB');
      expect(repo.photoUploads, hasLength(1), reason: '仓库确实被调用过');
      expect(
        [builds.home, builds.statistics, builds.vaccine, builds.curve],
        [1, 1, 1, 1],
      );
    });
  });

  group('两份清单合在一处', () {
    test('active() 只给在册的，byId() 两份里都找', () async {
      repo = FakeBabyRepository(
        rows: [
          babyFixture(),
          babyFixture(id: 2, name: '小红', archived: true),
        ],
      );
      final container = open();
      await container.read(babyListViewModelProvider.future);
      final notifier = listNotifier(container);

      // 记录表单的宝宝选择器只要在册的：归档就是把宝宝从表单里摘掉（§4.4.1）。
      expect(notifier.active().map((b) => b.id), [1]);
      // 归档的同样要能编辑、能恢复，所以按 id 找得到它。
      expect(notifier.byId(2)?.name, '小红');
      expect(notifier.byId(99), isNull, reason: '找不到就回 null，不兜成第一个');
    });
  });
}

/// 四个下游这次被重算了几次。
class _Builds {
  int home = 0;
  int statistics = 0;
  int vaccine = 0;
  int curve = 0;
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

class _StubVaccine extends BabyVaccineViewModel {
  _StubVaccine(this.builds);

  final _Builds builds;

  @override
  Future<List<BabyVaccinePlan>> build() async {
    builds.vaccine++;
    return const [];
  }
}

class _StubCurve extends BabyCurveViewModel {
  _StubCurve(this.builds, BabyCurveQuery query) : super(query);

  final _Builds builds;

  @override
  Future<BabyCurve?> build() async {
    builds.curve++;
    return null;
  }
}
