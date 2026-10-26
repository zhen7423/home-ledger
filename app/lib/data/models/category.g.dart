// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Category _$CategoryFromJson(Map<String, dynamic> json) => _Category(
  id: (json['id'] as num).toInt(),
  type: json['type'] as String,
  name: json['name'] as String,
  iconKey: json['iconKey'] as String?,
  colorIndex: (json['colorIndex'] as num?)?.toInt(),
  sortNo: (json['sortNo'] as num).toInt(),
  enabled: json['enabled'] as bool,
  preset: json['preset'] as bool,
  children:
      (json['children'] as List<dynamic>?)
          ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Category>[],
);

Map<String, dynamic> _$CategoryToJson(_Category instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'name': instance.name,
  'iconKey': instance.iconKey,
  'colorIndex': instance.colorIndex,
  'sortNo': instance.sortNo,
  'enabled': instance.enabled,
  'preset': instance.preset,
  'children': instance.children,
};
