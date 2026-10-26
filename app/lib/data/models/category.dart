import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

/// 收支类别，对应后端的 CategoryNode：接口只把大类列在最外层，小类挂在 children 里。
///
/// iconKey / colorIndex 只有大类有，小类后端回 null——下钻时沿用大类色相调明度，不另占色位。
/// 这两样是存在库里的，不按 sortNo 现算：现算会让拖拽排序改掉历史类别的颜色，
/// 饼图跨月对比时同一个类别显示成两种颜色（需求文档 §4.2.2）。
@freezed
abstract class Category with _$Category {
  const factory Category({
    required int id,
    required String type,
    required String name,
    String? iconKey,
    int? colorIndex,
    required int sortNo,
    required bool enabled,
    required bool preset,
    @Default(<Category>[]) List<Category> children,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
