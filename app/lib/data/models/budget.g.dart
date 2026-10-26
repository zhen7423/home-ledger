// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Budget _$BudgetFromJson(Map<String, dynamic> json) => _Budget(
  id: (json['id'] as num).toInt(),
  scope: json['scope'] as String,
  categoryId: (json['categoryId'] as num?)?.toInt(),
  categoryName: json['categoryName'] as String?,
  memberUserId: (json['memberUserId'] as num?)?.toInt(),
  memberName: json['memberName'] as String?,
  amount: json['amount'] as String,
);

Map<String, dynamic> _$BudgetToJson(_Budget instance) => <String, dynamic>{
  'id': instance.id,
  'scope': instance.scope,
  'categoryId': instance.categoryId,
  'categoryName': instance.categoryName,
  'memberUserId': instance.memberUserId,
  'memberName': instance.memberName,
  'amount': instance.amount,
};
