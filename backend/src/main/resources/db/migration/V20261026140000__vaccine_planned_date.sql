-- 疫苗计划日期可设置（2026-10-26 需求②）。
--
-- planned_date 是用户「打算哪天去打」的覆盖值，与 due_date 分层共存：
--   - due_date 仍是「程序表 + 出生日期」推导的原定应种日：改出生日期整份重算（realignFor）只重写它，
--     planned_date 不参与重算——重算碰它等于把用户改的期悄悄平移掉；
--   - NULL = 未覆盖，一切展示口径（排序 / 逾期判定 / 完成率分母 / 下一针 / 提醒）按 due_date；
--     非空时统一取 COALESCE(planned_date, due_date)，实体侧唯一落点是 BabyVaccinePlan.effectiveDate()；
--   - 已接种（record_id 非空或 status = DONE）的行拒绝再改计划日期（服务层校验）。
-- 与手动行（manual = 1）兼容：手动行同样可设，等于在用户自填日期之上再改期，一条路径管两类行。

ALTER TABLE baby_vaccine_plan
    ADD COLUMN planned_date DATE NULL
        COMMENT '用户设定的计划接种日期；NULL=按程序表应种日期展示。改生日重算只动 due_date，不动本列'
        AFTER due_date;
