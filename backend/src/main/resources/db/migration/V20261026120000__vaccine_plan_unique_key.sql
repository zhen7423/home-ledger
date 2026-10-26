-- 应种清单「疫苗名称 + 剂次」键的库级唯一性兜底（扫描报告 2026-10-26 P1-3）。
--
-- 此前唯一性只靠 BabyVaccinePlanServiceImpl.assertKeyFree 逐行比对（check-then-act）：
-- 两个家庭成员并发给同一宝宝补录同款自费项时都会通过校验，同键两行并存后——
--   - 接种记录回写（findPlanByKey 取第一条命中）的目标变得不确定；
--   - 改出生日期整份重算（realignFor）只对齐其中一行，另一行保留旧日期，永久脏数据。
--
-- 手法与 baby_formula_bag.uk_formula_bag_family_active 同款（V20260918233000）：
--   - active_vaccine_key 是 STORED 生成列：未删除行 = CONCAT(疫苗名, NUL, 剂次)，软删行为 NULL 退出唯一索引；
--     分隔符用 CHAR(0) 而不是 '\0' 字面量：后者在 NO_BACKSLASH_ESCAPES 的 sql_mode 下会被当两个字符。
--   - 唯一键 (family_id, baby_id, active_vaccine_key) 的最左前缀 (family_id, baby_id) 同时接管了
--     原 idx_plan_family_baby_key 的点查职责，故删掉旧索引；
--   - 实体类不得映射该生成列。
-- 疫苗名最长 30、剂次最长 8，加 NUL 分隔后 ≤ 39，VARCHAR(40) 够用；NUL 不会出现在任一字段里，
-- 拼起来的键不会有两组合撞车（与 BabyVaccinePlanGeneratorImpl.KEY_SEPARATOR 同一论证）。

-- 先把历史上可能已经落进来的同键重复行收敛掉（保留每组 id 最小的一条，其余软删）：
-- 不清理的话 ADD UNIQUE KEY 报 1062、整条 ALTER 原子失败，Flyway 卡住后端起不来。
-- 重复行本就是 assertKeyFree 竞态窗口漏进来的脏数据，软删后清单自动只剩一行，
-- 与 realignFor「同键取第一行对齐」的既有语义一致。
UPDATE baby_vaccine_plan p
JOIN (
    SELECT family_id, baby_id, vaccine_name, dose_no, MIN(id) AS keep_id
    FROM baby_vaccine_plan
    WHERE deleted = 0
    GROUP BY family_id, baby_id, vaccine_name, dose_no
) k ON p.family_id = k.family_id
   AND p.baby_id = k.baby_id
   AND p.vaccine_name = k.vaccine_name
   AND p.dose_no = k.dose_no
SET p.deleted = 1
WHERE p.deleted = 0 AND p.id <> k.keep_id;

ALTER TABLE baby_vaccine_plan
    ADD COLUMN active_vaccine_key VARCHAR(40)
        GENERATED ALWAYS AS (IF(deleted = 0, CONCAT(vaccine_name, CHAR(0), dose_no), NULL)) STORED NULL
        COMMENT '未删除行的 (疫苗名称, 剂次) 拼键，软删行为 NULL 以退出唯一索引。实体类不得映射本列'
        AFTER manual,
    ADD UNIQUE KEY uk_plan_family_baby_key_active (family_id, baby_id, active_vaccine_key),
    DROP KEY idx_plan_family_baby_key;
