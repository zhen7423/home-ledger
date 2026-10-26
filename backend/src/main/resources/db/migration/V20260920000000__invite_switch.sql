-- 邀请码手动开关迁移（第 33 轮）。
--
-- 邀请码从「建家庭即自动签发、7 天有效、期内可反复使用」改为「手动开启才生成、
-- 24 小时有效、只能使用一次，使用或到期后自动失效并关闭邀请入口」：
--   - family 新增 invite_enabled 总开关，默认关闭；
--   - invite_code / invite_code_expire_at 放宽为可空：关闭或已使用时不保留邀请码，
--     只有开关打开（即签发）那一刻才落值；
--   - 关闭入口的动作统一由应用层条件 UPDATE 完成（consumeInvite / disableInvite），
--     不走这里的数据回填。
--
-- 存量数据：升级前已签发且未过期的邀请码按「已开启」对待（invite_enabled = 1），
-- 码与失效时间原样保留、沿用原 7 天有效期，至到期或被使用一次即自动关闭，
-- 不让升级瞬间把正在进行的邀请流程打断。

ALTER TABLE family
    ADD COLUMN invite_enabled TINYINT NOT NULL DEFAULT 0 COMMENT '邀请开关：0 关闭（不生成也不保留邀请码）/ 1 开启（生成 6 位码，24 小时、一次性）' AFTER owner_user_id,
    MODIFY COLUMN invite_code           CHAR(6)     NULL COMMENT '6 位数字邀请码，仅开关开启时签发；使用一次或关闭即清空',
    MODIFY COLUMN invite_code_expire_at DATETIME    NULL COMMENT '签发后 24 小时过期（原 7 天）；过期或使用一次后入口自动关闭';

UPDATE family
SET invite_enabled = 1
WHERE deleted = 0 AND invite_code IS NOT NULL AND invite_code_expire_at > NOW();