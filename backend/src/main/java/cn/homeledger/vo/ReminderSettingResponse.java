package cn.homeledger.vo;

/**
 * 一类提醒的开关状态。
 *
 * @param label 中文标签由服务端给：前端硬编码七份中文的话，加第八类就得发一次 App
 * @param pushed 取自枚举，用户改不了。给前端是为了让它能显示「这类提醒会进通知栏」这句副标题
 */
public record ReminderSettingResponse(String type, String label, boolean enabled, boolean pushed) {

}
