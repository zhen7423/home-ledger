import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/ui/core/category_palette.dart';

void main() {
  group('类别色板（§4.2.2）', () {
    test('24 个色位互不相同', () {
      final colors = [for (var i = 0; i < 24; i++) categoryColor(i)];
      expect(colors.toSet().length, 24);
    });

    // 后端取号只在家庭内排，正常不会越过 23；越界也不能崩，宁可颜色重复
    test('越过 23 绕回第一轮，负数也不抛', () {
      expect(categoryColor(24), categoryColor(0));
      expect(categoryColor(47), categoryColor(23));
      expect(categoryColor(-1), categoryColor(23));
    });

    test('同一个索引每次算出来都一样', () {
      expect(categoryColor(7), categoryColor(7));
    });

    test('色块底只降不透明度，不改色相', () {
      final base = categoryColor(5);
      final tint = categoryTint(base);
      expect(tint.a, closeTo(0.14, 0.005));
      expect(tint.r, base.r);
      expect(tint.g, base.g);
      expect(tint.b, base.b);
    });
  });
}
