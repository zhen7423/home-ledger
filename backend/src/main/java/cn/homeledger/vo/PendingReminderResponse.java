package cn.homeledger.vo;

import java.time.LocalDate;
import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 一条待提醒项。
 * <p>
 * 七类提醒共用这一个形状，是 S4 建框架的核心决定：接线时只往产出逻辑里加一段，
 * 前端的通知调度、红点、去重、点击跳转全都不用跟着改。
 * <p>
 * 返回顺序即<b>紧急度顺序</b>（§4.6 第 4 条：逾期 &gt; 3 天内 &gt; 14 天内），由服务端排好，
 * 前端拿出这条列表就能直接铺首页的待办卡片区，不必再自己排一次。
 *
 * @param module 这条提醒属于哪个模块（{@code ModuleKey} 枚举名）。给它是为了客户端能把角标挂到
 *        对应的 Tab 上（§4.5.2）——「哪个类型属于哪个模块」是服务端的事实，写在前端等于让客户端
 *        认识七个具体类型，而 §4.5.1 那条规矩是客户端不认识具体类型
 * @param key 全局唯一的去重键，形如 {@code BUDGET_OVERRUN:FAMILY}、{@code BUDGET_OVERRUN:C:123}、
 *        {@code VACCINE_UPCOMING:PLAN:456}。前端拿它算通知 id，也拿它记「这一次已经提醒过」，
 *        所以同一个事实两次查询必须得到同一个 key
 * @param route 点进去落到哪个页面，由服务端给。「预算超支该跳哪」写死在前端的话，改一次要同时发后端和 App
 * @param fireAt 非空表示定时提醒（前端走 zonedSchedule），空表示立即提醒（走 show）。<b>它回答的是
 *        「下一次该弹的时刻」</b>：今天正是触发日（§4.5.1 的提前 N 天 / 当天 / 逾期后每 3 天的整点）时为空，
 *        否则是下一个触发日的上午 9 点。预算、猫粮见底、成长记录待补三类恒为空——它们是「此刻的状态」，
 *        没有该做某件事的时刻
 * @param fireDate {@code fireAt} 的日期部分，给「按天去重」用；fireAt 为空时它也为空。
 *        排程类的那一天到了之后会被重算成空值的 {@code fireAt}，前端拿今天与它比一次就不会重复弹
 */
public record PendingReminderResponse(String type, String module, String key, String title, String body, String route,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDateTime fireAt,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate fireDate) {

}
