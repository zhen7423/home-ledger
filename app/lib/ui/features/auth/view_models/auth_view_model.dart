import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';

part 'auth_view_model.freezed.dart';

/// 启动时先认 unknown：本地有没有令牌要异步读，读到之前既不能当已登录也不能当未登录，
/// 否则守卫会把冷启动的用户闪一下登录页再跳回首页。
enum SessionStatus { unknown, signedIn, signedOut }

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(SessionStatus.unknown) SessionStatus status,
    @Default(false) bool submitting,
    String? error,
  }) = _AuthState;
}

/// 登录态的唯一来源。路由守卫只看这里的 status，页面不自己做跳转。
class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() {
    final subscription = ref
        .watch(apiClientProvider)
        .sessionLost
        .listen(
          (_) => state = const AuthState(status: SessionStatus.signedOut),
        );
    ref.onDispose(subscription.cancel);

    ref
        .read(authRepositoryProvider)
        .hasStoredSession()
        .then(_bootstrap, onError: (_) => _bootstrap(false));

    return const AuthState();
  }

  void _bootstrap(bool hasSession) {
    if (state.status != SessionStatus.unknown) return;
    state = AuthState(
      status: hasSession ? SessionStatus.signedIn : SessionStatus.signedOut,
    );
  }

  Future<void> signIn({required String phone, required String password}) async {
    await _submit(
      () => ref
          .read(authRepositoryProvider)
          .signIn(phone: phone, password: password),
    );
  }

  /// §4.1.1 注册即登录，成功后直接进已登录态，不用再登一次。
  Future<void> signUp({
    required String phone,
    required String password,
    required String nickname,
  }) async {
    await _submit(
      () => ref
          .read(authRepositoryProvider)
          .signUp(phone: phone, password: password, nickname: nickname),
    );
  }

  Future<void> _submit(Future<void> Function() action) async {
    state = state.copyWith(submitting: true, error: null);
    try {
      await action();
      state = const AuthState(status: SessionStatus.signedIn);
    } on ApiException catch (e) {
      state = state.copyWith(submitting: false, error: errorCopy(e));
    } catch (e) {
      // 非 ApiException（模型解析 TypeError、FormData 状态错等）也必须复位 submitting：
      // 按钮永久转圈比一句通用报错糟糕得多（扫描报告 2026-10-26 P2-7）。
      state = state.copyWith(submitting: false, error: errorCopy(e));
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(submitting: true, error: null);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } finally {
      state = const AuthState(status: SessionStatus.signedOut);
    }
  }
}

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);
