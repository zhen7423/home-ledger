-- 奶粉开罐具体时间（2026-10-26 需求①）。
--
-- started_time 只补「记录精度」：展示「10月26日 08:30 开罐」用的，不参与任何推导——
--   - 时间线 telescoping（下一罐开始日 = 上一罐结束日）与使用天数仍按天算（ConsumptionEstimate 按天分摊）；
--   - uk_formula_bag_family_active 仍是天级唯一（「同一天只能开一罐」口径不变，要放开需重写消耗推算）；
--   - 服务端校验只有一条：started_date = 今天 时 started_time 不得晚于当前时刻（未来的那一刻还没有奶粉可喝）。
-- 选填 NULL：老数据与「只记日期」的用法照旧。

ALTER TABLE baby_formula_bag
    ADD COLUMN started_time TIME NULL
        COMMENT '开罐具体时间，选填。只用于展示，不参与天级时间线推导与统计'
        AFTER started_date;
