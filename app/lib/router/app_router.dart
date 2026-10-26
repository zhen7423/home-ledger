import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/family.dart';
import '../data/models/finance_statistics.dart';
import '../ui/core/splash_page.dart';
import '../ui/core/tab_shell.dart';
import '../ui/features/auth/view_models/auth_view_model.dart';
import '../ui/features/auth/views/login_page.dart';
import '../ui/features/auth/views/register_page.dart';
import '../ui/features/baby/views/baby_edit_page.dart';
import '../ui/features/baby/views/baby_formula_bag_edit_page.dart';
import '../ui/features/baby/views/baby_formula_bag_list_page.dart';
import '../ui/features/baby/views/baby_growth_curve_page.dart';
import '../ui/features/baby/views/baby_growth_edit_page.dart';
import '../ui/features/baby/views/baby_growth_list_page.dart';
import '../ui/features/baby/views/baby_home_page.dart';
import '../ui/features/baby/views/baby_list_page.dart';
import '../ui/features/baby/views/baby_record_page.dart';
import '../ui/features/baby/views/baby_statistics_page.dart';
import '../ui/features/baby/views/baby_vaccine_page.dart';
import '../ui/features/baby/views/baby_vaccine_record_edit_page.dart';
import '../ui/features/cat/views/cat_deworming_edit_page.dart';
import '../ui/features/cat/views/cat_deworming_list_page.dart';
import '../ui/features/cat/views/cat_edit_page.dart';
import '../ui/features/cat/views/cat_food_bag_edit_page.dart';
import '../ui/features/cat/views/cat_food_bag_list_page.dart';
import '../ui/features/cat/views/cat_home_page.dart';
import '../ui/features/cat/views/cat_list_page.dart';
import '../ui/features/cat/views/cat_setting_page.dart';
import '../ui/features/cat/views/cat_statistics_page.dart';
import '../ui/features/family/view_models/family_view_model.dart';
import '../ui/features/family/views/family_page.dart';
import '../ui/features/family/views/onboarding_page.dart';
import '../ui/features/finance/views/budget_page.dart';
import '../ui/features/finance/views/category_page.dart';
import '../ui/features/finance/views/export_page.dart';
import '../ui/features/finance/views/payment_account_page.dart';
import '../ui/features/finance/views/recurring_rule_detail_page.dart';
import '../ui/features/finance/views/recurring_rule_edit_page.dart';
import '../ui/features/finance/views/recurring_rule_list_page.dart';
import '../ui/features/finance/views/statistics_page.dart';
import '../ui/features/finance/views/transaction_detail_page.dart';
import '../ui/features/finance/views/transaction_edit_page.dart';
import '../ui/features/finance/views/transaction_list_page.dart';
import '../ui/features/home/views/home_page.dart';
import '../ui/features/settings/legal_copy.dart';
import '../ui/features/settings/views/about_page.dart';
import '../ui/features/settings/views/account_page.dart';
import '../ui/features/settings/views/legal_page.dart';
import '../ui/features/settings/views/module_page.dart';
import '../ui/features/settings/views/notification_page.dart';
import '../ui/features/settings/views/settings_page.dart';

abstract class RoutePath {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String family = '/family';
  static const String account = '/account';

  static const String finance = '/finance';
  static const String transactionNew = '/finance/transaction/new';

  /// 下面两条是路由模板，带 `:id`，跳转要用 `transactionOf` / `editTransaction` 填好 id。
  static const String transactionDetail = '/finance/transaction/:id';
  static const String transactionEdit = '/finance/transaction/:id/edit';
  static const String categories = '/finance/categories';
  static const String paymentAccounts = '/finance/payment-accounts';

  /// 统计页与导出页。都不带路径参数：统计的条件活在 `StatisticsViewModel` 里，
  /// 导出的条件走查询串（见 `exportWith`），没有哪个 id 需要编进路径。
  static const String statistics = '/finance/statistics';
  static const String export = '/finance/export';

  static const String budgets = '/finance/budgets';
  static const String recurringRules = '/finance/recurring-rules';
  static const String recurringRuleNew = '/finance/recurring-rules/new';

  /// 执行记录不单独开路由：它是规则详情页里的一个区块，做成一页要多一条路由、
  /// 多一个返回键，换来的是一个只有几行字的页面。
  static const String recurringRuleDetail = '/finance/recurring-rules/:id';
  static const String recurringRuleEdit = '/finance/recurring-rules/:id/edit';
  static const String notifications = '/settings/notifications';

  /// S9 的三条：模块与 Tab（开关 + 拖拽排序）、关于、用户协议与隐私政策。
  /// 后两条是可直接滚动的正文页而不是对话框——「备份说明」那种几行字的用对话框，
  /// 一份要读几分钟的文本塞进对话框是在跟用户的滚动条较劲。
  static const String modules = '/settings/modules';
  static const String about = '/settings/about';
  static const String terms = '/settings/terms';
  static const String privacy = '/settings/privacy';

  /// 猫咪模块的九条路径（§9 那张页面树）。常量先登记、路由表后补：页面要
  /// `context.push(RoutePath.catCats)`，缺常量的话当场就编译不过。
  static const String catHome = '/cat';
  static const String catCats = '/cat/cats';
  static const String catCatEdit = '/cat/cats/edit';
  static const String catFoodBags = '/cat/food-bags';
  static const String catFoodBagEdit = '/cat/food-bags/edit';
  static const String catDewormings = '/cat/dewormings';
  static const String catDewormingEdit = '/cat/dewormings/edit';
  static const String catSettings = '/cat/settings';
  static const String catStatistics = '/cat/statistics';

  static String catCatEditOf(int id) => '$catCatEdit?id=$id';

  static String catFoodBagEditOf(int id) => '$catFoodBagEdit?id=$id';

  static String catDewormingEditOf(int id) => '$catDewormingEdit?id=$id';

  /// 总览与统计页的倒计时行点进去的那条：只看这一只猫的驱虫史。
  static String catDewormingsOf(int catId) => '$catDewormings?catId=$catId';

  /// 从倒计时某一行直接进「给这只猫记一次驱虫」。`catId` 是唯一的预填项。
  /// 用 `Uri` 而不是字符串拼：不带 catId 时要交出一个干净的 `/cat/dewormings/edit`，
  /// 而不是一个末尾吊着 `?` 的路径（同一个类里 `exportWith` 已经踩过一次）。
  static String catDewormingNew({int? catId}) => Uri(
    path: catDewormingEdit,
    queryParameters: catId == null ? null : {'catId': '$catId'},
  ).toString();

  /// 宝宝模块的十条路径（§9 那张页面树）。与猫那九条同一条规矩：常量先登记、路由表后补。
  static const String babyHome = '/baby';
  static const String babyList = '/baby/list';
  static const String babyEdit = '/baby/edit';
  static const String babyGrowths = '/baby/growths';
  static const String babyGrowthEdit = '/baby/growths/edit';
  static const String babyGrowthCurve = '/baby/growths/curve';
  static const String babyVaccines = '/baby/vaccines';
  static const String babyVaccineRecordEdit = '/baby/vaccines/record';
  static const String babyRecords = '/baby/records';
  static const String babyStatistics = '/baby/stats';

  /// 奶粉开罐记录（§4.5.3，第 32 轮）：列表 + 记一罐/改一罐。
  static const String babyFormulas = '/baby/formulas';
  static const String babyFormulaEdit = '/baby/formulas/edit';

  static String babyFormulaEditOf(int id) => '$babyFormulaEdit?id=$id';

  /// 档案、身高体重、接种记录三个编辑页都用 `?id=` 分新增与编辑：不带上它就是新增，
  /// 所以下面这三条只服务「点某一行进编辑」。
  static String babyEditOf(int id) => '$babyEdit?id=$id';

  static String babyGrowthEditOf(int id) => '$babyGrowthEdit?id=$id';

  static String babyVaccineRecordEditOf(int id) =>
      '$babyVaccineRecordEdit?id=$id';

  /// 身高体重列表按宝宝筛（总览的每张宝宝卡片带着 `babyId` 进来）。用 `Uri` 生成而不是
  /// 字符串拼，与 `exportWith` 同一做法：路径里的 `?` 由它自己管，不靠人肉检查。
  static String babyGrowthsOf(int babyId) =>
      Uri(path: babyGrowths, queryParameters: {'babyId': '$babyId'}).toString();

  /// 应种清单与里程碑就诊同样按宝宝筛，入口都在总览的宝宝卡片上；不带 `babyId` 的两条
  /// （待办卡的「全部」、AppBar 的统计）直接用常量，那两处要的是全家庭那一份。
  static String babyVaccinesOf(int babyId) => Uri(
    path: babyVaccines,
    queryParameters: {'babyId': '$babyId'},
  ).toString();

  static String babyRecordsOf(int babyId) =>
      Uri(path: babyRecords, queryParameters: {'babyId': '$babyId'}).toString();

  /// 曲线页的两个条件：哪个宝宝、哪个指标。`metric` 不带时由服务端定（身高），
  /// 所以这里缺省不传，屏上那排 chips 选中哪一格就传哪一格。
  static String babyCurveOf({required int babyId, String? metric}) {
    final params = <String, String>{'babyId': '$babyId'};
    if (metric != null) {
      params['metric'] = metric;
    }
    return Uri(path: babyGrowthCurve, queryParameters: params).toString();
  }

  static const Set<String> anonymous = {login, register};

  static String transactionOf(int id) => '/finance/transaction/$id';

  static String editTransaction(int id) => '/finance/transaction/$id/edit';

  static String recurringRuleOf(int id) => '/finance/recurring-rules/$id';

  static String editRecurringRule(int id) =>
      '/finance/recurring-rules/$id/edit';

  /// 从统计页进导出页时把当前那套条件带过去（§4.2.7：「导出条件默认带上统计页当前的
  /// 时间范围与记录人」）。用查询参数而不是路径参数：三个条件都是可选的，编进路径就成了
  /// `/finance/export/2026-09-01/2026-09-30/3` 这种要数斜杠、还得处理空段的东西，
  /// 而 `TransactionListPage` 已经在用 `?source=AUTO` 这套做法了。
  ///
  /// 从设置页进则直接 `context.push(RoutePath.export)` 不带参数，`_queryOf` 解出来三个
  /// 字段全是 null，也就是「导出全部」。
  static String exportWith(StatisticsQuery query) {
    final params = {
      if (query.startDate != null) 'startDate': query.startDate!,
      if (query.endDate != null) 'endDate': query.endDate!,
      if (query.createdBy != null) 'createdBy': '${query.createdBy}',
    };
    // 全空时要给 null 而不是空 map：`Uri` 只要 `queryParameters` 不是 null 就认定「带查询串」，
    // 于是末尾吊出一个光秃秃的 `?`。
    return Uri(
      path: export,
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }
}

/// 登录态守卫。页面一律不自己跳转，全部由这里按登录态与家庭状态决定落点。
String? resolveRedirect({
  required SessionStatus status,
  required AsyncValue<Family?> family,
  required String location,
}) {
  final isAnonymous = RoutePath.anonymous.contains(location);

  // 冷启动还没读出本地令牌，先停在启动页，免得闪一下登录页再跳回首页
  if (status == SessionStatus.unknown) {
    return location == RoutePath.splash ? null : RoutePath.splash;
  }

  if (status == SessionStatus.signedOut) {
    return isAnonymous ? null : RoutePath.login;
  }

  if (family.isLoading) {
    // 家庭数据重载中（如首页下拉刷新会 invalidate familyViewModelProvider）：
    // 若已经站在壳内业务页上就直接放行，别再弹回启动页——那正是
    // 「下拉刷新跳出 logo 页」的根因。只有启动页/登录/引导这类未落地位置才等启动页。
    final alreadyOnAPage =
        location != RoutePath.splash &&
        !isAnonymous &&
        location != RoutePath.onboarding;
    if (alreadyOnAPage) {
      return null;
    }
    return location == RoutePath.splash ? null : RoutePath.splash;
  }

  if (family.value == null) {
    // 没有家庭时也要能进账号页与通知设置页：退出登录、注销、关通知都不依赖家庭
    final allowed =
        location == RoutePath.onboarding ||
        location == RoutePath.account ||
        location == RoutePath.notifications;
    return allowed ? null : RoutePath.onboarding;
  }

  if (location == RoutePath.splash ||
      location == RoutePath.onboarding ||
      isAnonymous) {
    return RoutePath.home;
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.onDispose(refresh.dispose);

  ref.listen(
    authViewModelProvider.select((state) => state.status),
    (_, _) => refresh.value++,
  );
  ref.listen(familyViewModelProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: RoutePath.splash,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      status: ref.read(authViewModelProvider).status,
      family: ref.read(familyViewModelProvider),
      location: state.matchedLocation,
    ),
    // 未知路由/畸形深链落这里而不是 go_router 的英文默认页，与全中文 App 保持一致；
    // 守卫会把未登录的访客送去该去的地方，已登录的回首页。
    errorBuilder: (context, state) =>
        _RouteErrorPage(location: state.uri.toString()),
    routes: [
      GoRoute(
        path: RoutePath.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePath.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePath.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RoutePath.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => TabShell(shell: shell),
        // 五个分支固定挂在这里：底栏画哪几个、按什么顺序，由 TabShell 按用户的模块偏好决定
        // （§3.2）。分支本身不动态增删——重建整棵 GoRouter 会把当前位置重置回启动页，
        // 而「刚关掉猫咪模块就被弹回首页」不比多两条已注册的路由好。
        // 分支序号 0–4 是 TabShell 与这里唯一的约定，挪动顺序要同时改那边。
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePath.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePath.finance,
                builder: (context, state) => TransactionListPage(
                  initialSource: state.uri.queryParameters['source'],
                ),
              ),
            ],
          ),
          // 猫咪与宝宝在 S6 / S7 是「设置 → 某模块」的壳外 push 页，S9 起它们同时是 Tab 分支的根。
          // 设置页那个入口原样保留，两条入口指向同一条 `/cat` / `/baby`（§9）。
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePath.catHome,
                builder: (context, state) => const CatHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePath.babyHome,
                builder: (context, state) => const BabyHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePath.settings,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePath.family,
        builder: (context, state) => const FamilyPage(),
      ),
      GoRoute(
        path: RoutePath.account,
        builder: (context, state) => const AccountPage(),
      ),
      // 记账与通知的这些二级页都在壳外：它们是从任一 Tab 全屏推开的任务页，不是 Tab
      GoRoute(
        path: RoutePath.transactionNew,
        builder: (context, state) => const TransactionEditPage(),
      ),
      GoRoute(
        path: RoutePath.transactionDetail,
        builder: (context, state) => TransactionDetailPage(id: _idOf(state)),
      ),
      GoRoute(
        path: RoutePath.transactionEdit,
        builder: (context, state) => TransactionEditPage(id: _idOf(state)),
      ),
      GoRoute(
        path: RoutePath.categories,
        builder: (context, state) => const CategoryPage(),
      ),
      GoRoute(
        path: RoutePath.paymentAccounts,
        builder: (context, state) => const PaymentAccountPage(),
      ),
      GoRoute(
        path: RoutePath.recurringRules,
        builder: (context, state) => const RecurringRuleListPage(),
      ),
      // 新建这条要排在带 :id 的两条前面：GoRouter 按声明顺序匹配，晚一步
      // `/finance/recurring-rules/new` 就会被参数路由吃掉，把 'new' 当成 id 去查。
      GoRoute(
        path: RoutePath.recurringRuleNew,
        builder: (context, state) => const RecurringRuleEditPage(),
      ),
      GoRoute(
        path: RoutePath.recurringRuleDetail,
        builder: (context, state) => RecurringRuleDetailPage(id: _idOf(state)),
      ),
      GoRoute(
        path: RoutePath.recurringRuleEdit,
        builder: (context, state) => RecurringRuleEditPage(id: _idOf(state)),
      ),
      GoRoute(
        path: RoutePath.budgets,
        builder: (context, state) => const BudgetPage(),
      ),
      GoRoute(
        path: RoutePath.statistics,
        builder: (context, state) => const StatisticsPage(),
      ),
      GoRoute(
        path: RoutePath.export,
        builder: (context, state) => ExportPage(query: _queryOf(state.uri)),
      ),
      GoRoute(
        path: RoutePath.notifications,
        builder: (context, state) => const NotificationPage(),
      ),
      GoRoute(
        path: RoutePath.modules,
        builder: (context, state) => const ModulePage(),
      ),
      GoRoute(
        path: RoutePath.about,
        builder: (context, state) => const AboutPage(),
      ),
      // 用户协议与隐私政策共用一页：只有标题与正文两张表不同，为它们各写一个文件等于把
      // 同一套滚动排版抄两遍。正文是常量，不落库、不走接口。
      GoRoute(
        path: RoutePath.terms,
        builder: (context, state) =>
            const LegalPage(title: legalTermsTitle, paragraphs: legalTerms),
      ),
      GoRoute(
        path: RoutePath.privacy,
        builder: (context, state) =>
            const LegalPage(title: legalPrivacyTitle, paragraphs: legalPrivacy),
      ),
      // 猫咪模块的九条（§9）。`/cat` 本身已是 Tab 分支的根（见上面的 branches），
      // 其余八条仍在壳外，是从总览页推开的任务页。
      GoRoute(
        path: RoutePath.catCats,
        builder: (context, state) => const CatListPage(),
      ),
      GoRoute(
        path: RoutePath.catCatEdit,
        builder: (context, state) => CatEditPage(id: _idParamOf(state.uri)),
      ),
      GoRoute(
        path: RoutePath.catFoodBags,
        builder: (context, state) => const CatFoodBagListPage(),
      ),
      GoRoute(
        path: RoutePath.catFoodBagEdit,
        builder: (context, state) =>
            CatFoodBagEditPage(id: _idParamOf(state.uri)),
      ),
      GoRoute(
        path: RoutePath.catDewormings,
        builder: (context, state) =>
            CatDewormingListPage(catId: _catIdParamOf(state.uri)),
      ),
      GoRoute(
        path: RoutePath.catDewormingEdit,
        builder: (context, state) => CatDewormingEditPage(
          id: _idParamOf(state.uri),
          catId: _catIdParamOf(state.uri),
        ),
      ),
      GoRoute(
        path: RoutePath.catSettings,
        builder: (context, state) => const CatSettingPage(),
      ),
      GoRoute(
        path: RoutePath.catStatistics,
        builder: (context, state) => const CatStatisticsPage(),
      ),
      // 宝宝模块的十条（§9）。`/baby` 已是 Tab 分支的根，其余九条在壳外。
      // 九条都是字面量路径、没有一条带 `:id`，所以声明顺序不影响匹配；
      // 顺序照 §1.3 那张页面表，为的是「哪一条是哪一页」一眼能对上。
      GoRoute(
        path: RoutePath.babyList,
        builder: (context, state) => const BabyListPage(),
      ),
      GoRoute(
        path: RoutePath.babyEdit,
        builder: (context, state) => BabyEditPage(id: _idParamOf(state.uri)),
      ),
      GoRoute(
        path: RoutePath.babyGrowths,
        builder: (context, state) =>
            BabyGrowthListPage(babyId: _babyIdParamOf(state.uri)),
      ),
      GoRoute(
        path: RoutePath.babyGrowthEdit,
        builder: (context, state) =>
            BabyGrowthEditPage(id: _idParamOf(state.uri)),
      ),
      GoRoute(
        path: RoutePath.babyGrowthCurve,
        // 曲线页的 `babyId` 是非空的，而查询串解不出来时会是 null——这里补 `?? 0`，与 `_idOf`
        // 同一个思路：交给后端回「宝宝不存在」，比在路由层崩一个白屏好。一条曲线没有
        // 「不指定宝宝」这个含义，所以这一步不能像列表页那样把 null 传下去。
        builder: (context, state) => BabyGrowthCurvePage(
          babyId: _babyIdParamOf(state.uri) ?? 0,
          metric: _metricOf(state.uri),
        ),
      ),
      GoRoute(
        path: RoutePath.babyVaccines,
        builder: (context, state) =>
            BabyVaccinePage(babyId: _babyIdParamOf(state.uri)),
      ),
      GoRoute(
        path: RoutePath.babyVaccineRecordEdit,
        builder: (context, state) =>
            BabyVaccineRecordEditPage(id: _idParamOf(state.uri)),
      ),
      GoRoute(
        path: RoutePath.babyRecords,
        builder: (context, state) =>
            BabyRecordPage(babyId: _babyIdParamOf(state.uri)),
      ),
      GoRoute(
        path: RoutePath.babyStatistics,
        builder: (context, state) =>
            BabyStatisticsPage(babyId: _babyIdParamOf(state.uri)),
      ),
      GoRoute(
        path: RoutePath.babyFormulas,
        builder: (context, state) => const BabyFormulaBagListPage(),
      ),
      GoRoute(
        path: RoutePath.babyFormulaEdit,
        builder: (context, state) =>
            BabyFormulaBagEditPage(id: _idParamOf(state.uri)),
      ),
    ],
  );
});

/// GoRouter 的兜底错误页（扫描报告 2026-10-26 P3-5）。`go()` 而不是 `push()`：
/// 错误页没有上一级可回，清空栈直接落地由守卫决定的位置。
class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('页面不存在')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.travel_explore_outlined, size: 48),
            const SizedBox(height: 12),
            Text('没有找到这个页面：$location', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(RoutePath.home),
              child: const Text('回首页'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 路径里的 id 只由我们自己拼，理论上不会是别的；真解析不出来就当 0，
/// 让后端回「流水不存在」，比在路由层崩一个白屏好。
int _idOf(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '') ?? 0;

/// 编辑页的 `?id=`。返回 null 是**新增**，不是「id 缺失的坏请求」，所以这里没有 `_idOf` 那个 `?? 0`。
///
/// 两条规矩分开是有原因的：`_idOf` 服务的是 `/:id` 路径参数——那条位置上有值是无条件的，
/// 解不出来就是坏了，当 0 交给后端回「不存在」；这一条服务的是 `?id=`，而「不带 id」是
/// 三个新增入口的常态（`RoutePath.catCatEdit` 原样 push 就是不带的）。
/// 照抄 `?? 0` 的症状是：点「新增一只猫」进的是一个 id=0 的编辑页，回填读不到、保存改不动，
/// 而界面看上去完全正常。
int? _idParamOf(Uri uri) => int.tryParse(uri.queryParameters['id'] ?? '');

/// 驱虫列表与驱虫表单共用的 `?catId=`（总览的倒计时那一行、统计页的那一行都带它过来）。
int? _catIdParamOf(Uri uri) => int.tryParse(uri.queryParameters['catId'] ?? '');

/// 宝宝模块四条列表／表单页共用的 `?babyId=`。与 `_idParamOf` 同一条规矩：解不出来就是
/// **不带**，「全部宝宝」是这个参数的正经取值（身高体重列表、疫苗清单、里程碑就诊四页的空态
/// 与「跨宝宝那份」都靠它）。
int? _babyIdParamOf(Uri uri) =>
    int.tryParse(uri.queryParameters['babyId'] ?? '');

/// 曲线页的 `?metric=`。它是五个指标名之一，不是数字，所以不做解析——服务端认不出就退成
/// 它自己的缺省（身高），与「不带这个参数」同一结果。
String? _metricOf(Uri uri) => uri.queryParameters['metric'];

/// 导出页继承的条件。`int.tryParse` 解不出来就当没带记录人，与 `_idOf` 的兜底同一个思路：
/// 查询串只由 `exportWith` 自己拼，真解不出来也不该在路由层崩一个白屏。
StatisticsQuery _queryOf(Uri uri) => StatisticsQuery(
  startDate: uri.queryParameters['startDate'],
  endDate: uri.queryParameters['endDate'],
  createdBy: int.tryParse(uri.queryParameters['createdBy'] ?? ''),
);
