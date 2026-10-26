import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/cat.dart';
import '../../../../data/models/cat_food_bag.dart';
import '../../../../data/models/cat_food_estimate.dart';
import '../../../../data/models/cat_statistics.dart';
import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/auth_image.dart';
import '../../../core/category_palette.dart';
import '../../../core/date_format.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../cat_badges.dart';
import '../cat_copy.dart';
import '../view_models/cat_overview_view_model.dart';

/// §4.3 的猫咪总览，也是猫模块的根页：从设置页 push 进来，模块内其余页面都从这里分发。
///
/// 一屏四块：档案横排、余量卡、到期倒计时、两条记录入口。四块共用一次加载
/// （`CatOverviewRepository.load()`），所以要么整屏转圈、要么整屏出数，不会出现「卡片有猫、余量还在转」。
class CatHomePage extends ConsumerWidget {
  const CatHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(catOverviewViewModelProvider);
    final notifier = ref.read(catOverviewViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('猫咪'),
        actions: [
          IconButton(
            tooltip: '统计',
            icon: const Icon(Icons.insert_chart_outlined),
            onPressed: () => context.push(RoutePath.catStatistics),
          ),
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RoutePath.catSettings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: overview.when(
          loading: () => _Centered(child: const CircularProgressIndicator()),
          error: (error, _) => _Centered(
            child: _Failure(
              message: errorCopy(error),
              onRetry: notifier.refresh,
            ),
          ),
          data: (state) => ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (state.fromCache) OfflineBanner(savedAt: state.savedAt),
              SectionHeader(
                title: '猫咪档案',
                trailing: TextButton(
                  onPressed: () => context.push(RoutePath.catCats),
                  child: Text(state.cats.isEmpty ? '去建档' : '全部'),
                ),
              ),
              _CatsRow(cats: state.cats),
              const SectionHeader(title: '猫粮余量'),
              _FoodCard(bag: state.bag, estimate: state.estimate),
              const SectionHeader(title: '到期倒计时'),
              _DewormingCountdown(items: state.dueCountdown),
              const SectionHeader(title: '记录'),
              // 记录入口每行一张独立小卡（问题单：卡片间有间距）。
              RowCard(
                child: _RecordTile(
                  icon: Icons.restaurant_outlined,
                  title: '猫粮袋',
                  subtitle: '时间线与日均',
                  onTap: () => context.push(RoutePath.catFoodBags),
                ),
              ),
              RowCard(
                child: _RecordTile(
                  icon: Icons.medication_outlined,
                  title: '驱虫记录',
                  subtitle: '内驱与外驱',
                  onTap: () => context.push(RoutePath.catDewormings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// loading 与 error 两支也要能被下拉。`RefreshIndicator` 挂在一个不可滚动的 `Center` 上时
/// 手势直接落空——症状是「转圈的时候反而刷新不了」。`minHeight` 那份约束让子项至少撑满一屏，
/// 于是 `Center` 仍然居中，而 `SingleChildScrollView` 永远可滚。
class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(child: child),
      ),
    ),
  );
}

/// 与 `statistics_page.dart` 里那一份同形状。**那边是私有类、跨文件拿不到**，这里照抄一份而不是提成
/// 公共组件：十五行、两个入参、零逻辑，而抽出去只有两条路——要么让猫模块反向依赖财务页，要么在
/// `ui/core/` 新开一个文件，后者要改需求文档 §6.1.1 那棵目录树，为一个错误态开一次文档变更不值。
class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onRetry, child: const Text('重试')),
      ],
    ),
  );
}

/// 横排。档案上限 10 只（§4.3.1），所以这一排最多十张卡 + 一张「建档」卡，
/// 不需要为「几百只猫」写虚拟化列表。
class _CatsRow extends StatelessWidget {
  const _CatsRow({required this.cats});

  final List<Cat> cats;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 128,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: cats.length + 1,
      separatorBuilder: (context, index) => const SizedBox(width: 10),
      itemBuilder: (context, index) => index == cats.length
          ? const _AddCatCard()
          : _CatCard(cat: cats[index], index: index),
    ),
  );
}

class _CatCard extends StatelessWidget {
  const _CatCard({required this.cat, required this.index});

  final Cat cat;

  /// 只用于取头像色（§4.3.1 一期无照片：颜色按列表下标取，不落库、不随属性变）。
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 132,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // 点卡片进档案列表，不进编辑页：这一屏是「我家有哪些猫」，
          // 要改哪一只得先看全名单，直接跳编辑会让返回键变多一层
          onTap: () => context.push(RoutePath.catCats),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 有档案照片就显示（S10）：带鉴权下载的 AuthImage，圆形裁切；
                // 没照片仍用「色块 + 首字」占位。
                ClipOval(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: AuthImage(
                      photoUrl: cat.photoUrl,
                      fit: BoxFit.cover,
                      // 44 逻辑 px × 2 高 DPI：小头像按 1200px 全解码白占内存
                      cacheWidth: 88,
                      placeholder: CircleAvatar(
                        radius: 22,
                        backgroundColor: categoryTint(categoryColor(index)),
                        child: Text(
                          cat.name.characters.first,
                          style: TextStyle(
                            color: categoryColor(index),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  catSummaryLine(cat),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (cat.archived)
                  Text(
                    '已归档',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddCatCard extends StatelessWidget {
  const _AddCatCard();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 92,
    child: Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(RoutePath.catCatEdit),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(Icons.add), SizedBox(height: 6), Text('建档')],
          ),
        ),
      ),
    ),
  );
}

/// 三块卡片状态各画各的，**没有第四块**：`bag == null && estimate != null` 在后端不可能出现
/// （estimate 只从当前袋算出来），所以第一格只判 `bag`，那一支同时 cover 了「一袋都没开」与
/// 「什么都还没算」；为那个不可能的组合写分支等于承认那条端点有两个答案。
class _FoodCard extends StatelessWidget {
  const _FoodCard({required this.bag, required this.estimate});

  final CatFoodBag? bag;
  final CatFoodEstimate? estimate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bag = this.bag;
    final estimate = this.estimate;

    if (bag == null) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('还没有开过的猫粮袋', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '记一袋什么时候开始喂，之后余量、日均与耗尽日都自动推算。',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.push(RoutePath.catFoodBagEdit),
              child: const Text('开一袋'),
            ),
          ],
        ),
      );
    }

    if (estimate == null) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${bag.brand} 使用中', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('完成第一袋后自动开始估算，或先填写预估日均克数。', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push(RoutePath.catSettings),
              child: const Text('去填预估日均'),
            ),
          ],
        ),
      );
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  bag.brand,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                '${formatDate(bag.startedDate)} 开始',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: estimate.remainingPercent / 100,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '剩余 ${gramsText(estimate.remainingGrams)}'
            '（${estimate.remainingPercent}%）· 预计还能吃 ${estimate.daysLeft} 天',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            '预计 ${formatDate(estimate.depletionDate)} 耗尽 · '
            '日均 ${gramsText(estimate.dailyAverage)} · 已用 ${estimate.usedDays} 天',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            estimate.fromHistory
                ? '日均取自已完成袋的历史。估算基于家庭整体消耗，不区分哪只猫。'
                : '日均用的是你填的预估。估算基于家庭整体消耗，不区分哪只猫。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (estimate.overEstimate)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '已超出预计用量，请确认是否已开新袋。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(RoutePath.catFoodBagEdit),
              child: const Text('开新袋'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: child,
    ),
  );
}

class _DewormingCountdown extends StatelessWidget {
  const _DewormingCountdown({required this.items});

  final List<CatDueCountdownItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      // 没有猫、或猫都还没有驱虫记录时都走这里。文案要给出下一步，
      // 因为这一格在页面上占了四行高，光一句「暂无」会让人以为加载坏了。
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(catCountdownEmptyHint),
      );
    }

    return Column(
      children: [
        for (final item in items)
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: CatTypeBadge(type: item.type),
            title: Text(item.catName),
            subtitle: Text(formatDate(item.nextDate)),
            trailing: Text(
              dueLabel(
                daysToDue: item.daysToDue,
                overdueDays: item.overdueDays,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: item.overdueDays != null
                    ? theme.colorScheme.error
                    : null,
              ),
            ),
            // item.catId 是 required int（那一行必然属于一只在册的猫），所以这里没有 null 分支
            onTap: () => context.push(RoutePath.catDewormingsOf(item.catId)),
          ),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
