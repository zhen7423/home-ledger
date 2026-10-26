import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/module_preference.dart';
import '../../data/models/pending_reminder.dart';
import '../../router/app_router.dart';
import '../features/settings/view_models/module_preference_view_model.dart';
import '../features/settings/view_models/reminder_view_model.dart';
import 'module_copy.dart';

/// 底部栏的外壳（§3.2）。固定项「首页」与「设置」始终占首尾，中间按用户的模块开关动态填充，
/// 顺序就是他拖出来的那个顺序。
///
/// 路由表里的五个分支是固定的（见 `app_router.dart` 的 branches），这里只决定<b>画哪几个、按什么顺序</b>。
/// 不动态增删分支：重建整棵 GoRouter 会把当前位置重置回启动页，而「刚关掉猫咪模块就被弹回首页」
/// 不比多两条已注册的路由好。
///
/// 它同时替首页承担两件与底栏同寿的事：红点角标，以及「从后台回到前台就重拉一次待提醒」
/// （§4.5.2 的三条时机之一）。两件都不能挂在首页里——用户可能停在记账 Tab 上切出去又回来。
class TabShell extends ConsumerStatefulWidget {
  const TabShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<TabShell> createState() => _TabShellState();
}

class _TabShellState extends ConsumerState<TabShell> {
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () => ref.invalidate(pendingReminderViewModelProvider),
  );

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 这一眼 watch 就是「启动时把待提醒拉一遍」的驱动源：没有谁 watch 它，build 就不跑，
    // 通知一条都排不上、红点也永远不亮
    final pending =
        ref.watch(pendingReminderViewModelProvider).value ??
        const <PendingReminder>[];
    final modules = ref.watch(enabledModulesProvider);

    final destinations = <_Destination>[
      _Destination(
        branch: _branchOfHome,
        label: '首页',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        badge: pending.length,
      ),
      for (final module in modules)
        if (_destinationOf(module, pending) case final row when row.drawable)
          row,
      const _Destination(
        branch: _branchOfSettings,
        label: '设置',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
      ),
    ];
    final selected = destinations.indexWhere(
      (row) => row.branch == widget.shell.currentIndex,
    );

    return Scaffold(
      body: widget.shell,
      // §3.2：FAB 不再全局占位，只出现在「当前 Tab 有对应记账动作」时：
      // 记账页是「记一笔」、猫咪页是「记猫粮」、宝宝页是「记身高体重」，且只画加号图标，
      // 不画扩展标签——扩展标签在多屏宽度下会盖住页面元素，而这枚按钮本来就有 tooltip 说明。
      floatingActionButton: _fabOf(widget.shell.currentIndex),
      bottomNavigationBar: NavigationBar(
        // 走到一个已关闭模块的页面时（设置页那两个入口仍在），这一项不在底栏里，
        // 于是没有任何一格该被选中。退成首页那一格：底栏是个纯导航控件，
        // 为这一种情况去动态加一格「临时 Tab」比高亮错一格更让人困惑
        selectedIndex: selected < 0 ? 0 : selected,
        onDestinationSelected: _select(destinations),
        destinations: [
          for (final row in destinations)
            NavigationDestination(
              icon: _BadgedIcon(count: row.badge, icon: row.icon),
              selectedIcon: _BadgedIcon(
                count: row.badge,
                icon: row.selectedIcon,
              ),
              label: row.label,
            ),
        ],
      ),
    );
  }

  /// 当前 Tab 的浮起入口。分支不在下列三个里（首页 / 设置）就没有浮起按钮。
  /// 只画加号图标：扩展标签横排「图标 + 文字」在这几个入口上会占掉整行宽度，
  /// 缩小到图标后不再遮挡下面的页面元素，具体动作写在 tooltip 里。
  Widget? _fabOf(int branch) {
    final String tooltip;
    final String route;
    switch (branch) {
      case _branchOfFinance:
        tooltip = '记一笔';
        route = RoutePath.transactionNew;
      case _branchOfCat:
        tooltip = '记猫粮';
        route = RoutePath.catFoodBagEdit;
      case _branchOfBaby:
        tooltip = '记身高体重';
        route = RoutePath.babyGrowthEdit;
      default:
        return null;
    }
    return FloatingActionButton(
      heroTag: null,
      tooltip: tooltip,
      onPressed: () => context.push(route),
      child: const Icon(Icons.add),
    );
  }

  /// 重复点当前 Tab 时回到该分支的根页面，与 Material 的导航约定一致。
  void Function(int) _select(List<_Destination> destinations) => (index) {
    final branch = destinations[index].branch;
    widget.shell.goBranch(
      branch,
      initialLocation: branch == widget.shell.currentIndex,
    );
  };
}

/// 路由表里五个分支的序号，与 `app_router.dart` 的 branches 顺序一一对应。
/// 只有这一处认数字，认错了的症状是「点猫咪进了宝宝」。
const int _branchOfHome = 0;

const int _branchOfFinance = 1;

const int _branchOfCat = 2;

const int _branchOfBaby = 3;

const int _branchOfSettings = 4;

_Destination _destinationOf(
  ModulePreference module,
  List<PendingReminder> pending,
) {
  final count = pending.where((row) => row.module == module.moduleKey).length;
  return switch (module.moduleKey) {
    moduleFinance => _Destination(
      branch: _branchOfFinance,
      label: module.label,
      icon: moduleIcon(moduleFinance),
      selectedIcon: moduleIcon(moduleFinance, selected: true),
      badge: count,
    ),
    moduleCat => _Destination(
      branch: _branchOfCat,
      label: module.label,
      icon: moduleIcon(moduleCat),
      selectedIcon: moduleIcon(moduleCat, selected: true),
      badge: count,
    ),
    moduleBaby => _Destination(
      branch: _branchOfBaby,
      label: module.label,
      icon: moduleIcon(moduleBaby),
      selectedIcon: moduleIcon(moduleBaby, selected: true),
      badge: count,
    ),
    // 不认识的模块（服务端加了新的、这台设备还没更新）：整格不画，而不是画一个点不动的死 Tab
    _ => const _Destination(
      branch: _branchOfHome,
      label: '',
      icon: Icons.help_outline,
      selectedIcon: Icons.help,
    ),
  };
}

/// 底栏上的一格。`branch` 是它在路由表里的分支序号，`badge` 为 0 时角标整个不显示。
class _Destination {
  const _Destination({
    required this.branch,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badge = 0,
  });

  final int branch;

  final String label;

  final IconData icon;

  final IconData selectedIcon;

  final int badge;

  /// 认不出来的模块整格不画：给它一个空标签的格子比少一格更糟。
  bool get drawable => label.isNotEmpty;
}

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.count, required this.icon});

  final int count;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Badge.count(
      count: count,
      isLabelVisible: count > 0,
      child: Icon(icon),
    );
  }
}
