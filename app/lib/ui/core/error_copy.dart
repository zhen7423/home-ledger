import 'package:flutter/material.dart';

import '../../data/services/api_exception.dart';

/// 后端 ErrorCode 逐条带了中文文案并随响应回传，优先用它，前端不另抄一份业务文案。
/// 这里只补后端不可能知道的几种传输层情况。
String errorCopy(Object? error) {
  if (error is! ApiException) {
    return '操作失败了，请稍后重试';
  }
  final message = error.message.trim();
  if (message.isNotEmpty) {
    return message;
  }
  return switch (error.code) {
    ClientErrorCode.timeout => '请求超时，请稍后重试',
    ClientErrorCode.gateway => '服务器暂时不可用，请稍后重试',
    ClientErrorCode.malformedResponse => '服务器返回的内容无法识别，请稍后重试',
    ClientErrorCode.accessDenied => '请求被拦截（403），请确认访问入口是否正确',
    _ => '连不上服务器，请检查网络后重试',
  };
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
