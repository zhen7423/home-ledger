import 'package:homeledger/data/models/cat.dart';
import 'package:homeledger/data/models/cat_food_bag.dart';
import 'package:homeledger/data/models/cat_food_estimate.dart';
import 'package:homeledger/data/models/cat_statistics.dart';

/// S6 的样例数据。六个模型的字段几乎全是必填的，手搓一份能用的响应要二十行，
/// 这里给一套默认值齐全的帮手，要别的形态在调用处覆盖（形状照 s5_fixtures.dart）。
///
/// `dailyAverage` 在 [CatFoodEstimate] 与 [CatFoodConsumption] 里同名而口径不同：
/// 前者是「当前袋按历史袋折算出来的日均」，后者是「区间总克数 ÷ 区间天数」。
/// 两份样例故意给成 50 与 65 两个不同的数，任何把它们混用的测试都会在断言里红出来。

Cat catFixture({
  int id = 1,
  String name = '咪咪',
  DateTime? birthday,
  bool birthdayEstimated = false,
  bool archived = false,
}) => Cat(
  id: id,
  name: name,
  gender: 'FEMALE',
  birthday: birthday,
  birthdayEstimated: birthdayEstimated,
  breed: '中华田园猫',
  weightKg: '4.25',
  neutered: 'YES',
  archived: archived,
  createdAt: DateTime(2026, 9, 1),
);

/// 一袋猫粮。默认那份是**已完成**的（`current: false` 且两个派生字段有值），
/// 因为要拿它拼统计页的用例更多；当前袋在调用处给 `current: true, usageDays: null, dailyAverage: null`。
CatFoodBag bagFixture({
  int id = 10,
  String brand = '测试牌',
  int packGrams = 2000,
  DateTime? startedDate,
  int? usageDays = 40,
  int? dailyAverage = 50,
  bool current = false,
}) => CatFoodBag(
  id: id,
  brand: brand,
  packGrams: packGrams,
  startedDate: startedDate ?? DateTime(2026, 8, 1),
  usageDays: usageDays,
  dailyAverage: dailyAverage,
  current: current,
);

CatFoodEstimate estimateFixture({
  int remainingGrams = 1450,
  int daysLeft = 29,
  int dailyAverage = 50,
}) => CatFoodEstimate(
  usedDays: 11,
  dailyAverage: dailyAverage,
  consumedGrams: 550,
  remainingGrams: remainingGrams,
  remainingPercent: 73,
  daysLeft: daysLeft,
  depletionDate: DateTime(2026, 10, 14),
  fromHistory: true,
  overEstimate: false,
);

CatDueCountdownItem countdownFixture({
  int catId = 1,
  String catName = '咪咪',
  String type = 'EXTERNAL',
  int? daysToDue,
  int? overdueDays,
}) => CatDueCountdownItem(
  catId: catId,
  catName: catName,
  type: type,
  nextDate: DateTime(2026, 10, 15),
  daysToDue: daysToDue,
  overdueDays: overdueDays,
);

CatDewormingCompletion completionFixture({
  int catId = 1,
  String catName = '咪咪',
  String type = 'EXTERNAL',
  int due = 4,
  int done = 3,
  int rate = 75,
  int? overdueDays,
}) => CatDewormingCompletion(
  catId: catId,
  catName: catName,
  type: type,
  due: due,
  done: done,
  rate: rate,
  overdueDays: overdueDays,
);

/// 猫粮消耗那一整块。默认区间与 `days` 对得上：9 月 1 日到 9 月 30 日共 30 天，
/// 2000 g ÷ 30 天 ≈ 65 g（服务端是整数除，样例里不必凑得比它更准）。
CatFoodConsumption consumptionFixture({
  int totalGrams = 2000,
  int dailyAverage = 65,
  int finishedBags = 1,
  List<CatBrandSlice> brands = const [],
  List<CatMonthGrams> months = const [],
  List<CatFoodBag> bags = const [],
  DateTime? startDate,
  DateTime? endDate,
}) => CatFoodConsumption(
  startDate: startDate ?? DateTime(2026, 9, 1),
  endDate: endDate ?? DateTime(2026, 9, 30),
  days: 30,
  totalGrams: totalGrams,
  dailyAverage: dailyAverage,
  finishedBags: finishedBags,
  brandBreakdown: brands,
  monthlyTrend: months,
  bagUsages: bags,
);
