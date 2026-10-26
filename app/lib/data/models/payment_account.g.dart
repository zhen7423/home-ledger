// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentAccount _$PaymentAccountFromJson(Map<String, dynamic> json) =>
    _PaymentAccount(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      sortNo: (json['sortNo'] as num).toInt(),
      isDefault: json['isDefault'] as bool,
      enabled: json['enabled'] as bool,
    );

Map<String, dynamic> _$PaymentAccountToJson(_PaymentAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sortNo': instance.sortNo,
      'isDefault': instance.isDefault,
      'enabled': instance.enabled,
    };
