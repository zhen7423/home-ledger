package cn.homeledger.vo;

/**
 * 一个模块的开关与顺序。
 *
 * @param label 中文标签由服务端给，理由同 {@code ReminderSettingResponse.label}：前端硬编码三份中文的话，
 *        加第四个模块就得发一次 App
 * @param sortNo 按它升序即中间三个 Tab 的展示顺序。数组顺序已在服务端折成这个数，前端不必再排一次
 */
public record ModulePreferenceResponse(String moduleKey, String label, boolean enabled, int sortNo) {

}
