// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transaction _$TransactionFromJson(Map<String, dynamic> json) => _Transaction(
  id: (json['id'] as num).toInt(),
  type: json['type'] as String,
  amount: json['amount'] as String,
  categoryId: (json['categoryId'] as num).toInt(),
  categoryName: json['categoryName'] as String,
  subCategoryId: (json['subCategoryId'] as num?)?.toInt(),
  subCategoryName: json['subCategoryName'] as String?,
  accountId: (json['accountId'] as num).toInt(),
  accountName: json['accountName'] as String,
  bizDate: DateTime.parse(json['bizDate'] as String),
  remark: json['remark'] as String?,
  createdBy: (json['createdBy'] as num).toInt(),
  recorderName: json['recorderName'] as String,
  ruleId: (json['ruleId'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TransactionToJson(_Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amount': instance.amount,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'subCategoryId': instance.subCategoryId,
      'subCategoryName': instance.subCategoryName,
      'accountId': instance.accountId,
      'accountName': instance.accountName,
      'bizDate': instance.bizDate.toIso8601String(),
      'remark': instance.remark,
      'createdBy': instance.createdBy,
      'recorderName': instance.recorderName,
      'ruleId': instance.ruleId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
