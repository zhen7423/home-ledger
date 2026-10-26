import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/payment_account.dart';
import '../../../../data/repositories/payment_account_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';

/// §4.2.4 的支付方式字典。理由与 `CategoryViewModel` 一致：整份读、写后重拉。
class PaymentAccountViewModel extends AsyncNotifier<PaymentAccountListResult> {
  @override
  Future<PaymentAccountListResult> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const PaymentAccountListResult([], fromCache: false);
    }
    return _repository.list();
  }

  /// 记账时可选的支付方式：只留启用项。管理页要连停用的一起显示，所以另用 `all`。
  List<PaymentAccount> get selectable => [
    for (final account in all)
      if (account.enabled) account,
  ];

  List<PaymentAccount> get all =>
      state.value?.accounts ?? const <PaymentAccount>[];

  /// 记账表单打开时默认选中的那一项。
  ///
  /// 「每个家庭恰好一行 isDefault = 1」是后端保证的不变量，正常情况下这里不会是 null；
  /// 但离线兜底用的可能是一份旧缓存，所以仍按可空处理，不拿 `!` 硬解。
  PaymentAccount? get defaultAccount {
    for (final account in selectable) {
      if (account.isDefault) return account;
    }
    return null;
  }

  Future<String?> create(String name) => _write(() => _repository.create(name));

  Future<String?> rename(int id, String name) =>
      _write(() => _repository.update(id, name: name));

  /// 设默认会连带清掉其他行的默认标记，所以写完之后必须重拉整份，不能只改列表里那一条。
  Future<String?> setDefault(int id) =>
      _write(() => _repository.update(id, isDefault: true));

  Future<String?> toggle(int id) => _write(() => _repository.toggle(id));

  Future<String?> remove(int id) => _write(() => _repository.remove(id));

  Future<String?> sort(List<int> orderedIds) =>
      _write(() => _repository.sort(orderedIds));

  PaymentAccountRepository get _repository =>
      ref.read(paymentAccountRepositoryProvider);

  Future<String?> _write(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      return errorCopy(e);
    }
    try {
      state = AsyncData(await _repository.list());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return errorCopy(e);
    }
    return null;
  }
}

final paymentAccountViewModelProvider =
    AsyncNotifierProvider<PaymentAccountViewModel, PaymentAccountListResult>(
      PaymentAccountViewModel.new,
    );
