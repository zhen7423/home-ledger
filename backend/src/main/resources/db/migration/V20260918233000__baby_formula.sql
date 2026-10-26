-- 宝宝奶粉记录迁移（第 32 轮）。
--
-- 设计与 cat_food_bag 同构，是同一份「包装消耗时间线」在宝宝侧的投影（共用
-- common/ConsumptionEstimate 的推算，§6.4.1 只此一处）：
--   - 结束日期与在用状态不落库，全部由 started_date（开罐日期）推导，下一罐的开始日即上一罐的结束日；
--   - active_started_date 是 STORED 生成列 + 唯一索引，软删行为 NULL 以退出唯一索引，
--     同一天只能开一罐、删掉后可同一天重录（与 cat_food_bag 的生成列同一个手法）；
--   - 实体类不得映射该生成列。
--
-- 与猫粮袋唯一的差别在「预估日均」的存放处：猫粮放在家庭级 cat_setting（一整袋用完才换，设置一次
-- 管全家），奶粉开罐时用户顺手填的日均更贴近「开了一罐大概一天吃多少」的语境，且每罐批次不同
-- （800 g 装与 400 g 装），故直接落在每一罐上（estimated_daily_grams），历史罐仍按实际使用天数反推
-- 日均、优先级高于手填（与猫粮同一条规则）。

CREATE TABLE baby_formula_bag (
    id                    BIGINT       NOT NULL COMMENT '雪花 ID',
    family_id             BIGINT       NOT NULL COMMENT '所属家庭。不预设属于哪个宝宝：奶粉按家庭整体消耗统计（与猫粮袋同一口径）',
    brand                 VARCHAR(20)  NOT NULL COMMENT '奶粉品牌/系列。自由文本，历史品牌由前端从既有记录里去重记忆，不建字典表',
    pack_grams            INT          NOT NULL COMMENT '包装规格，整数克 > 0（如 800 g 罐装、400 g 袋装）。克数用 INT，与猫粮同一约定',
    started_date          DATE         NOT NULL COMMENT '开罐日期。可回溯填过去、不可晚于今天。结束日期与在用状态都不落库，由本列推导',
    active_started_date   DATE         GENERATED ALWAYS AS (IF(deleted = 0, started_date, NULL)) STORED NULL COMMENT '在用罐的开罐日，软删行为 NULL 以退出下面的唯一索引。实体类不得映射本列',
    estimated_daily_grams INT          NULL COMMENT '开罐时填的预计每天克数，1–2000，选填。只在没有可用历史罐时兜底（推算规则见 ConsumptionEstimate）',
    remark                VARCHAR(200) NULL COMMENT '备注 ≤ 200 字符',
    created_by            BIGINT       NOT NULL COMMENT '记录人',
    created_at            DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted               TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除。删除后时间线自动重新闭合，该行的 active_started_date 转 NULL 从而不再占住开罐日',
    PRIMARY KEY (id),
    -- 列表就是 family_id 全量按 started_date 升序，无分页
    KEY idx_formula_bag_family_started (family_id, deleted, started_date),
    UNIQUE KEY uk_formula_bag_family_active (family_id, active_started_date),
    CONSTRAINT fk_formula_bag_family FOREIGN KEY (family_id) REFERENCES family (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='奶粉开罐记录（消耗推算与统计的唯一数据源）';
