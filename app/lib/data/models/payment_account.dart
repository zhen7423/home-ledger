import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_account.freezed.dart';
part 'payment_account.g.dart';

/// 支付方式，对应后端的 PaymentAccountResponse。
///
/// 「每个家庭恰好一行 isDefault = 1」是后端保证的不变量：设为默认走
/// `PATCH /{id}` 传 `isDefault: true`，同一事务里清掉其他行，所以前端这边
/// 不存在「找不到默认项」的分支，也不单独开一个设默认端点（需求文档 §4.2.1、§8）。
@freezed
abstract class PaymentAccount with _$PaymentAccount {
  const factory PaymentAccount({
    required int id,
    required String name,
    required int sortNo,
    required bool isDefault,
    required bool enabled,
  }) = _PaymentAccount;

  factory PaymentAccount.fromJson(Map<String, dynamic> json) =>
      _$PaymentAccountFromJson(json);
}
