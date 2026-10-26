# 「家记」UI 设计语言规范 ——「暖居」（v1.0）

> 本文档是「家记」App 界面视觉的唯一口径。产品定位：**单个家庭共用的生活记录 App**（记账 + 猫咪 + 宝宝 + 提醒），
> 使用者是家人，场景是日常，情绪是「温暖的、可信的、有生活气的」。
> UI 语言因此命名为**「暖居」**：像家里的一盏暖灯——**温暖而不失克制，亲切而不失秩序**。
> 金钱需要清晰，生活需要温度，两者在本语言里以「暖调中性 + 温润类别色 + 圆润图标」一体实现。
>
> 适用范围：`app/lib/ui/**` 的所有界面。设计令牌落在 `ui/core/app_theme.dart` 与 `ui/core/category_palette.dart`，
> 组件级主题在 `ThemeData` 中统一实现，页面只做排版与留白微调，**不改任何业务逻辑与数据契约**
> （`color_index` / `icon_key` 的存储语义、页面路由、交互分支全部原样保留）。

---

## 1. 设计原则

| 原则 | 含义 |
| --- | --- |
| 暖调第一 | 一切颜色从「暖橙种子」出发，冷色只作为可辨识性的补充，且必须与暖色共享同一份「饱和度/明度」气质 |
| 记账先读数 | 金额永远是页面上的主角：大字号、等宽数字、语义色一眼可辨（支出暖红 / 收入主色橙 / 结余墨色） |
| 一屏一主次 | 每屏只有一个「大声量」元素（首页是本月的结余大字），其余区块安静、留白、靠层级不靠装饰 |
| 圆润亲和 | 图标全部使用圆润变体，圆角半径有统一刻度，卡片无硬阴影（用纸面色块 + 发丝描边替代） |
| 克制动效 | 不新增任何自定义动画；一切动效沿用 Material 3 默认（按压、翻页、开关），动效为理解服务，不为炫技 |

---

## 2. 色彩体系

### 2.1 品牌种子与方案

- **种子色（Seed）**：`#E8862E`（暖橙 / 琥珀）。
- **方案生成**：`ColorScheme.fromSeed(seedColor: #E8862E)`——用 **M3 默认的 `tonalSpot` 变体**，不指定
  `dynamicSchemeVariant`。走查记录：曾尝试 `expressive` 变体想让界面「更有生活感」，实测它会把这颗
  暖橙种子偏成**紫罗兰主色**（`#E8862E` → light primary ≈ `#635497`），与「暖调品牌」背道而驰，
  故弃用；`tonalSpot` 下 primary ≈ `#895120`（暖橙棕）、secondary ≈ `#745944`（暖棕），正是本语言要的调性。
- **动态取色**：Android 12+ 的系统壁纸配色（`dynamic_color` 的 `DynamicColorBuilder`）仍然优先，
  组件主题全部基于 `ColorScheme` 令牌而非硬编码色值构建，动态色与「暖居」落在同一套结构上，两者不打架。

### 2.2 中性基底（暖调纸感）

| 角色 | 令牌 | 用法 |
| --- | --- | --- |
| 页面底色 | `colorScheme.surface` | 所有 Scaffold 背景 |
| 卡片纸色 | `colorScheme.surfaceContainerLow` | Card 的面色（默认 M3 Card 就用它，本语言显式钉住） |
| 浮层色 | `colorScheme.surfaceContainerHighest` | 输入框填充、标签底、被选中的项目底色 |
| 文字主色 | `onSurface` | 标题、正文、金额 |
| 文字次色 | `onSurfaceVariant` | 说明、时间、标签、副标题 |
| 分隔与描边 | `outline` / `outlineVariant` | 发丝描边、未选中描边、占位 |

> 中性色全部由 M3 从种子派生——它天然带一点暖灰，不需要手工写一条「米白」。

### 2.3 语义色

| 语义 | 颜色 | 依据 |
| --- | --- | --- |
| 支出 | `colorScheme.error` | 暖红，与「家」语境里的温润红一致；全 App 支出用同一处令牌（首页摘要、列表金额、统计图例） |
| 收入 | `colorScheme.primary` | 品牌暖橙，收入即「家里的正向流入」 |
| 结余 / 强调 | `colorScheme.tertiary` 与 `secondary` | 趋势图、饼图强调，tonalSpot 派生为暖棕 / 橄榄大地色 |
| 预警（预算 WARNING） | `Colors.orange` | 与超支（error）拉开档位，档位判定见 `budget_copy.dart`，不入色板 |
| 超支（预算 EXCEEDED） | `colorScheme.error` | 同上 |
| 离线 / 缓存 | `secondaryContainer` + `onSecondaryContainer` | 离线横幅唯一用色，见 `ui/core/offline_banner.dart` |

### 2.4 类别色板（本语言的核心）

**目标**：24 个类别色既要**互相可分**（记账选择、饼图扇区、成员对比柱），又要与暖橙界面**同一气质**——
不再是「满饱和度的彩虹」，而是一组**温润、低饱和、带暖度倾向**的颜色，摆在一起像「调过色的彩铅」，不像「荧光笔」。

**规则**（实现见 `ui/core/category_palette.dart`，签名与 §4.2.2 的需求文档契约完全一致）：

- 仍是「一个函数、按 `color_index` 取色」：`categoryColor(int index)`。
- 饱和度统一 **S = 0.55**，明度统一 **L = 0.55**（较原 0.62/0.55 降饱和提明度：去荧光感、加柔和感，白底与纸色上更透气）。
- 色相不再等距 15°，改用 **24 个手工编排的色相位**（下表的 `hue`），相邻格子色相差 ≥ 约 40°，保证同屏可分；
  编排原则：**最常用的支出预置类别优先分到暖区**（餐饮深橙红、居住赭棕、宠物暖金），收入类放到财意味浓的绿 / 金，
  冷色难辨的「其他」两个索引做成**中性灰**（见下）。
- 两个「其他」（index 10 与 16）是**中性暖灰**：S = 0.10、色相 228°，让它从彩色群里退一步——「其他」本来就该安静。
  支出「其他」浅一档（L 0.52）、收入「其他」深一档（L 0.42）：满足「24 色互不相同」的不变量测试，
  而两者永不同屏（收支两树的「其他」不会同时出现），深浅差不破坏中性观感。
- 越界绕回、确定性、24 色互不相同、`categoryTint` 只降透明度不改色相等不变量**全部保留**（`test/ui/core/category_palette_test.dart` 原样通过）。

**色相位表（index → hue，S=0.55 / L=0.55）**：

| index | hue | 主要用途 | index | hue | 主要用途 |
| --- | --- | --- | --- | --- | --- |
| 0 | 18 | 餐饮（橙红） | 12 | 30 | 奖金（琥珀橙，收入树） |
| 1 | 196 | 交通（青蓝） | 13 | 178 | 理财收益（薄荷青） |
| 2 | 316 | 购物（莓粉） | 14 | 226 | 兼职（靛蓝） |
| 3 | 40 | 居住（琥珀棕） | 15 | 338 | 红包礼金（蔷薇红） |
| 4 | 350 | 医疗（玫红） | 16 | 中性灰 | 收入·其他 |
| 5 | 212 | 教育（天蓝） | 17 | 70 | 自定义位（黄绿） |
| 6 | 262 | 娱乐（紫罗兰） | 18 | 92 | 自定义位（嫩绿） |
| 7 | 52 | 宠物（金黄） | 19 | 114 | 自定义位（青柠） |
| 8 | 296 | 宝宝（粉紫） | 20 | 136 | 自定义位（橄榄绿） |
| 9 | 2 | 人情往来（珊瑚红） | 21 | 165 | 自定义位（鼠尾草绿） |
| 10 | 中性灰 | 支出·其他 | 22 | 244 | 自定义位（蓝紫） |
| 11 | 152 | 工资（叶绿） | 23 | 278 | 自定义位（鸢尾紫） |

> 编排约束（已逐对校验）：同屏可见的任意两色（记账 5 列格子的同行/邻格、饼图扇区、成员对比柱）色相差 **≥ 12°**；
> 只有跨收支两树、永不同屏的成对色（如奖金 30 / 居住 40）允许更近——它们永远不在同一张图里出现。

**衍生规则**：

- `categoryTint(color)`：同色 `alpha 0.14` 的浅底。色块、列表行图标、档案卡头像共用，是全 App 类别色的第一形态。
- `categoryShade(base, i)`：饼图下钻小类时沿用大类色相、按序号调明度（`0.36 + 0.06 * (i % 7)`），规则不变。
- **图形中的使用**：饼图扇区、柱状图、图例色块、成员对比全走 `categoryColor`，因此本次改色**一处生效、全 App 同步**。

### 2.5 深色模式

- `ColorScheme.fromSeed(seedColor, brightness: dark)`（tonalSpot）自动派生，不单独设计。
- 类别色板在深色下沿用同一套色相 / 饱和度，明度由 `ColorScheme` 的深色容器令牌兜底——图表的深色对比靠扇区之间的
  明度差 + 图例文字，不靠颜色本身变浅。
- 所有组件主题（卡片描边、输入填充、悬浮层）都已按 `brightness` 取值，深色下自动换为深色纸感。

---

## 3. 图标风格

| 规则 | 内容 |
| --- | --- |
| 图标族 | **Material 圆润变体（`*_rounded`）**。类别图标池 24 项全部从 `Icons.*` 换成 `Icons.*_rounded`：语义不变，笔画变圆、气质变亲，与「暖居」的圆角体系呼应。映射不到的 key 回落 `Icons.label_outline_rounded`。 |
| 类别图标呈现 | 一律「浅色圆底 + 本色图标」：`44–48dp` 圆形，`categoryTint` 填充，图标 22dp、用类别本色。选中态换实色圆底 + 白图标 + 同类色柔光环（见 §6.10）。 |
| 列表行图标 | 40dp 圆、`categoryTint` 填充、22dp 本色图标——记账列表、类别管理、流水详情三处同形。 |
| 模块 / 功能图标 | 沿用既有 Material 图标（`pets_outlined`、`child_care_outlined` 等），已足够亲圆，不做替换。 |
| 图标尺寸刻度 | 行内 18 / 22；区块 24；空态 88dp 柔色圆底 + 40dp 图标；AppBar 动作 24。 |
| App 图标 / 品牌角标（启动页、登录注册） | **家里的猫**（`app/assets/app_icon_source.jpg`）。桌面图标与页内角标同一张图、同一个裁切框——裁切框松了 48px 下糊成一团，紧了耳朵被切，当前 `x100 y70 1024` 是比较过四组候选定的。桌面：legacy 用圆角方块（占画布 0.94、圆角 0.26），自适应图标的背景做成「中央 2/3 = 裁切区 + 外圈放大虚化」，手机遮罩裁完看到的正是这块构图；页内角标是同一个方块（`ui/core/app_widgets.dart` 的 `BrandMark`）。各密度资源已生成并提交，换图后按 `app/pubspec.yaml` 里 `flutter_launcher_icons` 的注释重新生成一遍。 |

---

## 4. 间距与圆角

### 4.1 间距刻度（4dp 基准）

| 刻度 | 值 | 用途 |
| --- | --- | --- |
| `xs` | 4 | 图标与文字之间、标签内边距 |
| `sm` | 8 | 卡片内文字间、网格间距 |
| `md` | 12–16 | 卡片内边距、区块间留白、页面左右边距 |
| `lg` | 20–24 | 区块标题与内容之间、上下大留白 |
| `xl` | 32 | 空态、表单底部 |

- 页面内容左右边距统一 **16dp**；可横向滚动的行（chips、档案卡）左右各留 **16dp** 起始。
- 区块与区块之间 ≥ **20dp**；区块标题距其内容 **4–8dp**。

### 4.2 圆角刻度

| 刻度 | 值 | 引用物 |
| --- | --- | --- |
| 小圆角 | 8–12 | 输入框、chip、进度条帽 |
| 中圆角 | 16 | 卡片、按钮、对话层面板 |
| 大圆角 | 20–24 | 底部面板顶部、品牌角标 |
| 全圆 | 999 / stadium | 胶囊按钮、图标圆、FAB |

---

## 5. 字体排版

不引入外部字体（中文依赖系统字体回退），用**字重与数字特征**建立层级：

| 角色 | 样式 | 说明 |
| --- | --- | --- |
| 页面标题（AppBar） | `titleLarge` w600 | 左对齐，沉浸 |
| 区块标题 | `titleMedium` w600 + `AppAccentBar` 强调条 | 见 §6.1 |
| 主金额（统计结余 / 详情金额） | `headlineMedium` w700 + 表格数字(tabular figures) | 每屏唯一的大声量元素 |
| 摘要三列金额（首页） | `titleMedium` w700 + 表格数字 | 支出暖红 / 收入主色橙 / 结余墨色，标签降为小字 + 同色小圆点 |
| 行内金额（列表 / 图例） | `titleMedium` w700，支出用 error 色、收入用 primary 色，`+/-` 前缀保留 | 扫一眼即知收与支 |
| 说明 / 时间 / 标签 | `bodySmall` / `labelMedium`，onSurfaceVariant | 永远低于内容一等 |
| 输入框大数字 | 记一笔 34dp / 周期规则 28dp，均 **w700** + 表格数字 | 键盘弹出时仍醒目 |

> 表格数字通过 `FontFeature.tabularFigures()` 让所有金额数字等宽对齐——列表里「¥12.00」与「¥1,234.00」
> 个位对齐，是记账应用最容易出质感、也最常被忽略的细节。

---

## 6. 组件样式

所有组件样式统一在 `AppTheme._build` 中落为 `ThemeData` 的组件主题，页面代码不再各自定义外观。

### 6.1 区块标题 `SectionHeader` 与强调条 `AppAccentBar`（共享组件 `ui/core/app_widgets.dart`）

```
■ 待处理                    （右：操作项）
```
左侧 **4 × 16dp 圆角暖橙强调条**（`AppAccentBar`，`colorScheme.primary`）+ `titleMedium` w600 标题 + 右侧可选操作。
首页、猫/宝首页、统计页、设置页分组标题统一使用，替代各处手写的 `Row + Text`；流水列表的月份吸顶头
也用 `AppAccentBar`（紧凑行高 14dp）——强调条只在这一个组件里定义。

### 6.2 卡片 `Card`

- 圆角 **16**、`elevation 0`、面色 `surfaceContainerLow`、1dp 发丝描边 `outlineVariant @ 40%`。
- 效果：纸色面板、无硬阴影、深色下自动换深纸色——比默认 M3 悬浮卡「更贴纸、更安静」。

### 6.3 顶栏 `AppBar`

- 背景 `surface`、`surfaceTintColor: transparent`、无投影；向下滚动压过内容时 `scrolledUnderElevation: 1` 出一丝纸层。
- `titleTextStyle: titleLarge w600`；动作图标 24dp、onSurfaceVariant。

### 6.4 底部导航 `NavigationBar`

- 高度 **72**；选中指示 `secondaryContainer`（暖调）；标签 `labelMedium`，选中 w600；图标一律圆润变体（沿用现有 `*_outlined` / 实心成对切换）。

### 6.5 悬浮按钮 `FloatingActionButton.extended`

- 胶囊形、`primary` 底、`onPrimary` 图标与文字、`elevation 1 / 3`（按下）。

### 6.6 分段选择 `SegmentedButton`

- 全宽等分（`expandedInsets: EdgeInsets.zero`）、圆角 12、选中段 `secondaryContainer` 底 + `onSecondaryContainer` 文字、
  未选中段透明 + `outlineVariant` 发丝边。记账页、周期规则页、类别页的「支出 / 收入」切换共用。

### 6.7 Chips（`ChoiceChip` / `ActionChip` / `InputChip` / `FilterChip`）

- 圆角 **8**，选中底 `secondaryContainer`、选中文字 `onSecondaryContainer`、勾选图标主色；
  未选中 `surfaceContainerHighest` 底。统计页条件栏、小类选择、支付方式选择、筛选条全部由主题统一。

### 6.8 输入框 `InputDecoration`

- **Filled 风格**：`filled: true`，填充 `surfaceContainerHighest`，无边框（忘记时只升不描）；
  聚焦时描 1.5dp 主色边 + 浅底色，圆角 **12**。
- 页面里原来手写的 `border: OutlineInputBorder()` 一律删掉，交回主题（记一笔、备注、登录注册、对话框输入）。

### 6.9 按钮

- `FilledButton`：胶囊全圆角（或 16）、`minimumSize` 高度 48（主按钮）、w600 文字。
- `OutlinedButton`：胶囊、发丝描边、聚焦时 1.5dp 主色边。
- `TextButton`：主色文字、w600；禁用态一律 `onSurface @ 38%`。

### 6.10 类别格子 `CategoryCell`（记账页与周期规则编辑器共用）

| 状态 | 造型 |
| --- | --- |
| 未选中 | 44dp 圆，`categoryTint` 浅底，22dp 圆润本色图标；名称 `bodySmall` |
| 选中 | 同类色柔光环（52dp **绘制溢出**，`categoryColor @ 18%`）+ 44dp 实色圆 + 22dp 白图标；名称 w600 加深 |
| 按压 | InkWell 圆角涟漪，无额外自定义 |

> 光环用 `Stack + Clip.none` 绘制、不占布局尺寸：格子的高度与原实现完全一致，
> 小屏窄格与系统大字体下不会把五列网格挤出 overflow。

> 柔光环替代原来的 primary 描边：环色与类别色同源，蓝类别不会套一个橙圈，图标与边框不再「撞色违和」——这正是本次设计要解决的第一个问题。

### 6.11 对话框 / 底部面板 / 快照条

- `AlertDialog`：圆角 **24**、面色 `surface`、标题 `titleLarge`、内容 `bodyMedium`。沿用现有 `dialogTheme` 默认可达性。
- `BottomSheet`：顶部圆角 **20**（小类管理面板、筛选面板统一）。
- `SnackBar`：floating、圆角 12、`behavior: floating`、inset 16、反色底（`inverseSurface`）。

### 6.12 列表行 `ListTile`

- 图标色 `onSurfaceVariant`、副标题 `bodyMedium` onSurfaceVariant、行高由内容决定（dense 行除外）。

---

## 7. 页面排版规则

| 页面 | 排版要点（视觉层，不改交互） |
| --- | --- |
| 启动页 / 登录注册 | 品牌角标（`BrandMark`，家里的猫，圆角方块照片）+ 名称 + 副标题，单列居中，底色为纸面（`surface`）；注册与登录共用外壳 |
| 首页 | 顶部成员条 → 本月摘要卡（**结余大字** + 支出/收入/结余三列）→ 预算进度 → 待办横卡 → 快捷区 → 最近动态；区块标题统一用 §6.1 |
| 记账列表 | 月份吸顶头：月名 + 收/支/余（表格数字）；行：类别圆 + 名称 + 副信息 + **着色金额**；空态图标进柔圆底 |
| 记一笔 | 「支出/收入」分段 → 34dp 金额 → 5 列类别格子（§6.10）→ 小类 chips → 支付方式 chips → 日期 → 备注 → 全宽保存按钮 |
| 统计 | 结余大头卡 → 六大区块（§6.1 标题）；概览卡的支出合计就在饼图上方，故饼环中心**不加**文字（也避免与测试钉住的金额文本撞车）；图例行金额对齐 |
| 设置 | 分组用 §6.1 标题替代裸分割线，行保持 ListTile |

---

## 8. 动效与质感

- 不加任何自定义动画；`ThemeData` 沿用 M3 默认的 `splashFactory`、`pageTransitionsTheme`。
- 唯一「动」的是按压反馈（涟漪）与刷新指示器（`RefreshIndicator` 主色），保持安静。

---

## 9. 落地映射（本文档 → 代码）

| 规范条目 | 代码位置 |
| --- | --- |
| §2.1 种子 / 方案 | `ui/core/app_theme.dart` 的 `seedColor` / `ColorScheme.fromSeed`（默认 tonalSpot；expressive 被否的走查记录见 §2.1） |
| §2.4 类别色板 | `ui/core/category_palette.dart`（色相表 + S/L 常量 + 中性灰分支） |
| §3 图标族 | `ui/core/category_icons.dart`（全部 `*_rounded`） |
| §4 间距 / 圆角 | 页面留白微调 + `ui/core/app_widgets.dart` 组件内常量 |
| §5 字体排版 | 页面金额样式（`FontFeature.tabularFigures()`） |
| §6 组件样式 | `ui/core/app_theme.dart` 的组件主题 + `ui/core/category_cell.dart` + `ui/core/app_widgets.dart` |
| §3 App 图标 / 品牌角标 | `app/assets/`（图标源图与各密度产物）+ `ui/core/app_widgets.dart` 的 `BrandMark`；重新生成见 `app/pubspec.yaml` 的 `flutter_launcher_icons` 注释 |
| §7 页面排版 | 首页 / 记账编辑 / 记账列表 / 流水详情 / 统计 / 登录注册 / 启动 / 设置 等页的视觉微调 |

**验收口径**：不新增任何路由、不改变任何状态管理、不改变任何后端契约；`flutter analyze` 无 error，
`flutter test` 全绿（含 `category_palette_test.dart` 的 4 条不变量）。
