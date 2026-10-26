import 'package:flutter/material.dart';

/// 三个模块的 key，与服务端 `ModuleKey` 的枚举名逐字对应（§3.2）。
///
/// 客户端的用途只有两处：把角标挂到对应的 Tab、给最近动态挑图标。**不在这里翻译中文标签**——
/// 标签跟着 `ModulePreferenceResponse.label` 走，加第四个模块时不必发一次 App。
const String moduleFinance = 'FINANCE';

const String moduleCat = 'CAT';

const String moduleBaby = 'BABY';

/// 模块的图标。图标是纯展示，服务端不给：它没有义务知道我们用哪一套图标。
IconData moduleIcon(String moduleKey, {bool selected = false}) =>
    switch (moduleKey) {
      moduleFinance => selected
          ? Icons.receipt_long
          : Icons.receipt_long_outlined,
      moduleCat => selected ? Icons.pets : Icons.pets_outlined,
      moduleBaby => selected ? Icons.child_care : Icons.child_care_outlined,
      _ => Icons.circle_outlined,
    };
