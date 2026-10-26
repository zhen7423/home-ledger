import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/models/transaction.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/date_format.dart';
import '../../../core/error_copy.dart';

part 'transaction_edit_view_model.freezed.dart';

/// 记一笔 / 改一笔共用的表单状态。
///
/// 这里只留两件必须活过 widget 重建的事：原值回填与提交中的按钮状态。
/// 金额、所选类别、日期仍由页面自己的 controller 与局部状态管——表单每敲一个字
/// 就重建一次 provider，换来的只有样板代码。
@freezed
abstract class TransactionEditState with _$TransactionEditState {
  const factory TransactionEditState({
    @Default(false) bool loading,
    @Default(false) bool submitting,
    Transaction? original,
  }) = _TransactionEditState;
}

/// 类别与支付方式的字典不从这里走：页面直接 watch `categoryViewModelProvider`
/// 与 `paymentAccountViewModelProvider`，管理页和记账页共用同一份缓存。
class TransactionEditViewModel extends Notifier<TransactionEditState> {
  @override
  TransactionEditState build() => const TransactionEditState();

  /// 编辑模式回填原值。返回 null 表示成功，否则是可直接展示的文案。
  /// 原值只往状态里放这一份，页面用 `ref.listen` 拿到后再灌进各个 controller。
  Future<String?> load(int id) async {
    state = state.copyWith(loading: true);
    Transaction transaction;
    try {
      transaction = await _repository.get(id);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false);
      return errorCopy(e);
    }
    state = state.copyWith(loading: false, original: transaction);
    return null;
  }

  /// 新增时 `id` 留空。
  ///
  /// `bizDate` 收 `DateTime` 而不是字符串：日期选择器给的就是 `DateTime`，
  /// 到 `yyyy-MM-dd` 的转换集中在这里做一次。不能图省事把 `DateTime` 直接塞进
  /// 请求体——`toIso8601String()` 带出的时刻后缀，后端那个 `LocalDate` 参数解不开。
  Future<String?> submit({
    int? id,
    required String amount,
    required int categoryId,
    int? subCategoryId,
    required int accountId,
    required DateTime bizDate,
    String? remark,
  }) async {
    state = state.copyWith(submitting: true);
    final bizDay = formatDate(bizDate);
    try {
      if (id == null) {
        await _repository.create(
          amount: amount,
          categoryId: categoryId,
          subCategoryId: subCategoryId,
          accountId: accountId,
          bizDate: bizDay,
          remark: remark,
        );
      } else {
        await _repository.update(
          id,
          amount: amount,
          categoryId: categoryId,
          subCategoryId: subCategoryId,
          accountId: accountId,
          bizDate: bizDay,
          remark: remark,
        );
      }
    } on ApiException catch (e) {
      state = state.copyWith(submitting: false);
      return errorCopy(e);
    }
    state = state.copyWith(submitting: false);
    return null;
  }

  TransactionRepository get _repository =>
      ref.read(transactionRepositoryProvider);
}

final transactionEditViewModelProvider =
    NotifierProvider<TransactionEditViewModel, TransactionEditState>(
      TransactionEditViewModel.new,
    );
