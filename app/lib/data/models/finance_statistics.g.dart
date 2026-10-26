// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finance_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FinanceStatistics _$FinanceStatisticsFromJson(Map<String, dynamic> json) =>
    _FinanceStatistics(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      categoryBreakdown: (json['categoryBreakdown'] as List<dynamic>)
          .map((e) => CategorySlice.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthlyTrend: (json['monthlyTrend'] as List<dynamic>)
          .map((e) => MonthSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyTrend: (json['dailyTrend'] as List<dynamic>)
          .map((e) => DailyPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      accountBreakdown: (json['accountBreakdown'] as List<dynamic>)
          .map((e) => AccountSlice.fromJson(e as Map<String, dynamic>))
          .toList(),
      memberComparison: (json['memberComparison'] as List<dynamic>)
          .map((e) => MemberSlice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FinanceStatisticsToJson(_FinanceStatistics instance) =>
    <String, dynamic>{
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'categoryBreakdown': instance.categoryBreakdown,
      'monthlyTrend': instance.monthlyTrend,
      'dailyTrend': instance.dailyTrend,
      'accountBreakdown': instance.accountBreakdown,
      'memberComparison': instance.memberComparison,
    };

_CategorySlice _$CategorySliceFromJson(Map<String, dynamic> json) =>
    _CategorySlice(
      categoryId: (json['categoryId'] as num?)?.toInt(),
      name: json['name'] as String,
      amount: json['amount'] as String,
      percent: (json['percent'] as num).toInt(),
      subCategories:
          (json['subCategories'] as List<dynamic>?)
              ?.map((e) => CategorySlice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CategorySlice>[],
    );

Map<String, dynamic> _$CategorySliceToJson(_CategorySlice instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'name': instance.name,
      'amount': instance.amount,
      'percent': instance.percent,
      'subCategories': instance.subCategories,
    };

_DailyPoint _$DailyPointFromJson(Map<String, dynamic> json) => _DailyPoint(
  date: DateTime.parse(json['date'] as String),
  expense: json['expense'] as String,
);

Map<String, dynamic> _$DailyPointToJson(_DailyPoint instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'expense': instance.expense,
    };

_AccountSlice _$AccountSliceFromJson(Map<String, dynamic> json) =>
    _AccountSlice(
      accountId: (json['accountId'] as num).toInt(),
      name: json['name'] as String,
      amount: json['amount'] as String,
      percent: (json['percent'] as num).toInt(),
    );

Map<String, dynamic> _$AccountSliceToJson(_AccountSlice instance) =>
    <String, dynamic>{
      'accountId': instance.accountId,
      'name': instance.name,
      'amount': instance.amount,
      'percent': instance.percent,
    };

_CategoryAmount _$CategoryAmountFromJson(Map<String, dynamic> json) =>
    _CategoryAmount(
      categoryId: (json['categoryId'] as num?)?.toInt(),
      amount: json['amount'] as String,
    );

Map<String, dynamic> _$CategoryAmountToJson(_CategoryAmount instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'amount': instance.amount,
    };

_MemberSlice _$MemberSliceFromJson(Map<String, dynamic> json) => _MemberSlice(
  userId: (json['userId'] as num).toInt(),
  nickname: json['nickname'] as String,
  total: json['total'] as String,
  byCategory: (json['byCategory'] as List<dynamic>)
      .map((e) => CategoryAmount.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MemberSliceToJson(_MemberSlice instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'nickname': instance.nickname,
      'total': instance.total,
      'byCategory': instance.byCategory,
    };

_StatisticsQuery _$StatisticsQueryFromJson(Map<String, dynamic> json) =>
    _StatisticsQuery(
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      createdBy: (json['createdBy'] as num?)?.toInt(),
    );

Map<String, dynamic> _$StatisticsQueryToJson(_StatisticsQuery instance) =>
    <String, dynamic>{
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'createdBy': instance.createdBy,
    };
