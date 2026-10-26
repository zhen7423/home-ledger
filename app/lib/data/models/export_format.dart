/// 导出格式（§4.2.7）。`param` 与后端 ExportFormat 的取值一致（B7 大小写不敏感，前端只发小写）。
///
/// 刻意不在这里存 MIME 类型：真正的类型由响应头给（`DownloadedFile.contentType`）。
/// 在 Dart 里再抄一份，等于两处各写一遍「csv 是什么」，改了后端忘了改前端，
/// 分享面板就会把 csv 当成未知二进制，用户点不开。
enum ExportFormat {
  xlsx('xlsx', 'Excel (.xlsx)'),
  csv('csv', 'CSV');

  const ExportFormat(this.param, this.label);

  /// 查询串里 `format=` 的值。
  final String param;

  /// 界面上单选按钮的文案（§1.3）。
  final String label;
}
