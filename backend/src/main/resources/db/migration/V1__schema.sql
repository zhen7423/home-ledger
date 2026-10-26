-- 家记 全量建库脚本（Flyway 第一版迁移）。
--
-- 全库约定：主键 BIGINT + 雪花 ID（不写 AUTO_INCREMENT，由 MyBatis-Plus id-type: assign_id 生成）；
-- 时间统一存 Asia/Shanghai 的 DATETIME；业务表带逻辑删除 deleted(0/1)；
-- 含 family_id 的表必建 FOREIGN KEY (family_id) REFERENCES family(id)，且不进租户白名单
-- （白名单语义见 FamilyTenantHandler.NON_TENANT_TABLES）；静态字典表不带家族级通用列。
-- 建表顺序即外键依赖顺序：先 user / family 族，再各业务模块，最后用户级偏好表。
--
-- 版本顺序：本脚本版本号为 1；紧随其后的是一个 Java 迁移——1.1（SeedBabyDictionaries，
-- 宝宝静态字典播种）。它要读本脚本建好的两张字典表，故版本号必须大于 1，排序由 Flyway 按版本号决定。

CREATE TABLE schema_meta (
    meta_key   VARCHAR(64)  NOT NULL COMMENT '配置键',
    meta_value VARCHAR(255) NOT NULL COMMENT '配置值',
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (meta_key)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='系统全局口径常量';

INSERT INTO schema_meta (meta_key, meta_value)
VALUES ('timezone', 'Asia/Shanghai'),
       ('currency', 'CNY'),
       ('locale', 'zh-CN');

-- ------------------------------------------------------------------
-- 账号与家庭组
-- ------------------------------------------------------------------
-- 通用约定：主键 BIGINT + 雪花 ID、Asia/Shanghai 的 DATETIME、逻辑删除 deleted(0/1)。
--
-- user / family / family_member 一律只用 deleted 作为唯一的逻辑删除标记，不再另设 status 列：
-- 两个语义重叠的标记必然会出现「一个置位、另一个忘了改」的分支，而 deleted 由 MyBatis-Plus 全局
-- 逻辑删除自动加条件，status 则要每处手写，前者才是不会漏的那个。
--
-- family_member 不含 created_at / created_by：它是成员关系行而非业务记录，joined_at 即其建立时间，
-- 且「谁建立了这行」在创建者邀请 / 他人主动加入两种路径下含义不同，记录它没有消费方。
--
-- 本段的 user、user_auth_binding、family、family_member 四张表都无 family_id 隔离语义，必须显式
-- 登记在 FamilyTenantHandler.NON_TENANT_TABLES 中。其余带 family_id 的表须同时满足两条：
-- 不进白名单；建 FOREIGN KEY (family_id) REFERENCES family(id) —— 后者保证登录态缺 familyId 时
-- 租户拦截器注入的哨兵值 -1 在写入路径上撞外键失败（fail-closed），而不是静默落库。

CREATE TABLE `user` (
    id            BIGINT      NOT NULL COMMENT '雪花 ID',
    phone         VARCHAR(11) NOT NULL COMMENT '登录名：11 位中国大陆手机号。仅作账号标识，不发送短信',
    password_hash VARCHAR(60) NOT NULL COMMENT 'BCrypt(cost=10) 摘要，固定 60 字符。永不明文保存或回显',
    nickname      VARCHAR(12) NOT NULL COMMENT '昵称 1–12 字符，家庭内可见，用于标记记录人',
    created_at    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted       TINYINT     NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 / 1 已注销',
    PRIMARY KEY (id),
    -- 注销后手机号仍被唯一索引占用，即注销后不能用同一手机号重新注册
    UNIQUE KEY uk_user_phone (phone)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='用户账号';

CREATE TABLE user_auth_binding (
    id         BIGINT      NOT NULL COMMENT '雪花 ID',
    user_id    BIGINT      NOT NULL COMMENT '归属用户',
    provider   VARCHAR(16) NOT NULL COMMENT 'WECHAT / PHONE_SMS（第三方登录预留，本期不写入）',
    open_id    VARCHAR(64) NOT NULL COMMENT '第三方唯一标识；PHONE_SMS 时存手机号',
    union_id   VARCHAR(64) NULL COMMENT '微信开放平台 unionId，可空',
    phone      VARCHAR(11) NULL COMMENT '第三方回传的手机号，可空',
    bound_at   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '绑定时间',
    created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted    TINYINT     NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 有效 / 1 已解绑',
    PRIMARY KEY (id),
    UNIQUE KEY uk_binding_provider_open_id (provider, open_id),
    KEY idx_binding_user (user_id),
    CONSTRAINT fk_binding_user FOREIGN KEY (user_id) REFERENCES `user` (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='第三方登录绑定（仅建表预留）';

CREATE TABLE family (
    id                    BIGINT      NOT NULL COMMENT '雪花 ID',
    name                  VARCHAR(20) NOT NULL COMMENT '家庭名称 1–20 字符；创建时留空则填「XX 的家」',
    owner_user_id         BIGINT      NOT NULL COMMENT '创建者。转让时须与两行 family_member.role 在同一事务内更新',
    invite_code           CHAR(6)     NOT NULL COMMENT '6 位数字邀请码，在全部未过期码中全局唯一，由应用层随机取号后查重保证',
    invite_code_expire_at DATETIME    NOT NULL COMMENT '签发后 7 天过期；重置即换码并顺延 7 天，旧码立即失效',
    created_at            DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted               TINYINT     NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 / 1 已解散。保留 30 天供服务器侧恢复，到期由定时任务物理删除',
    -- 解散时刻：解散时由 FamilyService.markDissolved 写入；30 天物理删除的起点。逻辑删除的
    -- family 不再被编辑故只写一次，取值不依赖「恰好没再碰过」的 updated_at。
    deleted_at            DATETIME    NULL COMMENT '解散时刻',
    PRIMARY KEY (id),
    -- 非唯一索引：过期码仍留在表中，全局唯一性只在「未过期」子集上成立，无法用唯一索引表达
    KEY idx_family_invite_code (invite_code),
    KEY idx_family_owner (owner_user_id),
    -- 物理清除任务每天按 (deleted, deleted_at) 扫描待清除家庭（FamilyMapper.selectDissolvedBefore，
    -- ORDER BY deleted_at LIMIT 50——不按 id 排的理由见该 XML 的注释），这条索引让扫描不做全表扫
    KEY idx_family_purge_scan (deleted, deleted_at),
    CONSTRAINT fk_family_owner FOREIGN KEY (owner_user_id) REFERENCES `user` (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='家庭';

CREATE TABLE family_member (
    id                BIGINT      NOT NULL COMMENT '雪花 ID',
    family_id         BIGINT      NOT NULL COMMENT '所属家庭',
    user_id           BIGINT      NOT NULL COMMENT '成员用户',
    nickname_snapshot VARCHAR(12) NOT NULL COMMENT '加入时的昵称快照；退出/被移除时刷新为当时昵称，供记录人展示兜底',
    role              VARCHAR(16) NOT NULL COMMENT 'OWNER 创建者 / MEMBER 普通成员',
    joined_at         DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
    updated_at        DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted           TINYINT     NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 在籍 / 1 已退出或被移除。重新加入同一家庭时复活本行而非新插，以保住下面的唯一索引',
    PRIMARY KEY (id),
    -- 同一用户在同一家庭最多一行。注意「一个用户同时只属于一个家庭」无法用唯一索引表达：
    -- 软删除的历史行会让 (user_id) 或 (user_id, deleted) 在二次退出时撞键，故该约束由应用层
    -- 在事务内 SELECT ... FOR UPDATE 锁住 user 行后校验（见 FamilyService）
    UNIQUE KEY uk_member_family_user (family_id, user_id),
    KEY idx_member_user (user_id),
    CONSTRAINT fk_member_family FOREIGN KEY (family_id) REFERENCES family (id),
    CONSTRAINT fk_member_user FOREIGN KEY (user_id) REFERENCES `user` (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='家庭成员关系';

-- ------------------------------------------------------------------
-- 记账核心
-- ------------------------------------------------------------------
-- 三张表都带 family_id，故一律不进租户白名单，且都建 FOREIGN KEY (family_id) REFERENCES family(id)
-- 兜住登录态缺 familyId 时注入的哨兵值 -1。
--
-- 预置数据不在此处：category / payment_account 的主键是雪花 ID，纯 SQL 脚本生成不出来。
-- 由 FamilyService.create 在建家庭的同一事务内插入，内容取自 PresetFinanceDict 一份常量。

CREATE TABLE category (
    id          BIGINT      NOT NULL COMMENT '雪花 ID',
    family_id   BIGINT      NOT NULL COMMENT '所属家庭。类别树家庭级共享，任一成员增删改对其他成员立即生效',
    parent_id   BIGINT      NULL COMMENT 'NULL 为大类，非 NULL 为其下小类。最多两级——深度不靠数据库约束，由应用层校验（小类的 parent_id 必须指向一行 parent_id IS NULL 的记录）',
    type        VARCHAR(8)  NOT NULL COMMENT 'EXPENSE / INCOME。收支两棵树互相独立，同一 parent_id 下不跨类型',
    name        VARCHAR(8)  NOT NULL COMMENT '列宽取小类上限 8；大类 ≤ 6 由应用层校验。同一父级下不区分大小写与首尾空格不可重复，但该唯一性只由应用层对 deleted = 0 的行查重（见下方注释）',
    icon_key    VARCHAR(32) NULL COMMENT 'Material Icons 语义键。大类必有，小类为 NULL（下钻视图沿用大类图标）。取值须落在 PresetFinanceDict.ICON_POOL 内，映射不到时前端回落 Icons.label_outline',
    color_index SMALLINT    NULL COMMENT '色板索引 0–23，与 icon_key 共用同一套下标；小类为 NULL。不随 sort_no 变化，否则拖拽排序会让历史类别换色、饼图跨月对比断裂',
    sort_no     INT         NOT NULL DEFAULT 0 COMMENT '家庭内共享的手动排序值',
    enabled     TINYINT     NOT NULL DEFAULT 1 COMMENT '0 停用归档 / 1 启用。停用后不出现在新增流水的选择器中，历史流水仍显示原名称快照',
    is_preset   TINYINT     NOT NULL DEFAULT 0 COMMENT '1 预置：可改名可停用，但永不允许物理删除',
    created_by  BIGINT      NOT NULL COMMENT '记录人。预置行填该家庭的 owner_user_id——插入时机尚无登录态可取',
    created_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted     TINYINT     NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 / 1 已删除',
    PRIMARY KEY (id),
    -- 本表没有日期列，索引按该表的主要访问路径建：「取某类型的整棵类别树按序展示」是唯一的读形态
    KEY idx_category_family (family_id, deleted, type, parent_id, sort_no),
    CONSTRAINT fk_category_family FOREIGN KEY (family_id) REFERENCES family (id)
    -- 不对 parent_id 建外键：级联停用与删除要先在应用层判定「其下是否还有启用小类」，
    -- 交给数据库约束只会把一句明确的业务文案换成一个看不懂的 500
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='收支类别（两级，parent_id 自关联）';

-- category.name 上不建唯一索引，这是刻意的：软删除的历史行会让 (family_id, parent_id, name)
-- 在「删掉再建同名」时撞键，而把 deleted 加进索引又会因多行软删除同名而失效。
-- 唯一性只在应用层对 deleted = 0 的行查重，且必须先 trim——utf8mb4_0900_ai_ci 是 NO PAD，
-- 尾随空格在 MySQL 的比较里是显著字符，不 trim 就漏判。

CREATE TABLE payment_account (
    id         BIGINT      NOT NULL COMMENT '雪花 ID',
    family_id  BIGINT      NOT NULL COMMENT '所属家庭。只是标签字典，不维护余额、不做转账',
    name       VARCHAR(8)  NOT NULL COMMENT '支付方式名称 ≤ 8 字符，与自定义类别小类同宽。家庭内不区分大小写与首尾空格不可重复，同样只在应用层查重',
    sort_no    INT         NOT NULL DEFAULT 0,
    is_default TINYINT     NOT NULL DEFAULT 0 COMMENT '记账页账户选择器的初始值。每个家庭恰好一行为 1：置为默认时在同一事务内清掉其他行，且默认行不允许停用或删除',
    enabled    TINYINT     NOT NULL DEFAULT 1 COMMENT '0 停用 / 1 启用。停用后不出现在新增流水的选择器中，历史流水仍显示名称快照',
    created_by BIGINT      NOT NULL COMMENT '记录人。预置行填该家庭的 owner_user_id，理由同 category',
    created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted    TINYINT     NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 / 1 已删除（有流水引用的只能停用不能删）',
    PRIMARY KEY (id),
    KEY idx_account_family (family_id, deleted, sort_no),
    CONSTRAINT fk_account_family FOREIGN KEY (family_id) REFERENCES family (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='支付方式字典';

CREATE TABLE `transaction` (
    id                       BIGINT        NOT NULL COMMENT '雪花 ID',
    family_id                BIGINT        NOT NULL COMMENT '所属家庭。列表与统计一律以此隔离，created_by 只标记记录人、不作权限依据',
    type                     VARCHAR(8)    NOT NULL COMMENT 'EXPENSE / INCOME。冗余存一份，避免每次查询都为区分收支去 JOIN category',
    amount                   DECIMAL(12,2) NOT NULL COMMENT '金额 > 0，正负由 type 表达而非金额符号。进出 JSON 用字符串，不经浮点中转',
    category_id              BIGINT        NOT NULL COMMENT '大类。不建外键，见下方说明',
    category_name_snapshot   VARCHAR(8)    NOT NULL COMMENT '记账时的大类名称快照。类别改名不回溯历史流水',
    sub_category_id          BIGINT        NULL COMMENT '小类，选填；留空表示未细分',
    sub_category_name_snapshot VARCHAR(8)  NULL COMMENT '记账时的小类名称快照',
    account_id               BIGINT        NOT NULL COMMENT '支付方式。不建外键，理由同 category_id',
    account_name_snapshot    VARCHAR(8)    NOT NULL COMMENT '记账时的支付方式名称快照',
    biz_date                 DATE          NOT NULL COMMENT '业务发生日期，不含时刻，故用 DATE 而非 DATETIME。允许补记过去，不允许晚于今天',
    remark                   VARCHAR(200)  NULL COMMENT '纯文本备注 ≤ 200 字符。不含图片凭证',
    created_by               BIGINT        NOT NULL COMMENT '记录人用户 ID',
    recorder_name_snapshot   VARCHAR(12)   NOT NULL COMMENT '记录人昵称快照。成员退出后其历史流水仍要显示当时是谁记的，而 family_member.nickname_snapshot 会被刷新',
    rule_id                  BIGINT        NULL COMMENT '周期记账规则 ID；由周期记账模块回填，本期恒为 NULL。该列不建唯一索引，幂等由执行日志表承担',
    created_at               DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at               DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted                  TINYINT       NOT NULL DEFAULT 0 COMMENT '逻辑删除：0 正常 / 1 已删除。删掉的流水仍计入「该类别是否存在流水」的判定，故那条计数 SQL 必须绕过 @TableLogic 手写',
    PRIMARY KEY (id),
    KEY idx_tx_family_date (family_id, deleted, biz_date),
    KEY idx_tx_category    (family_id, category_id),
    KEY idx_tx_account     (family_id, account_id),
    KEY idx_tx_creator     (family_id, created_by),
    CONSTRAINT fk_tx_family FOREIGN KEY (family_id) REFERENCES family (id)
    -- 只对外键 family_id 建约束，category_id / account_id / created_by 都不建。
    -- 「类别下还有流水所以不许物理删除」必须由应用层判定并给出 CATEGORY_HAS_TRANSACTIONS 文案；
    -- 若交给数据库外键，同一个错误会变成一条约束冲突异常，用户看到的是一句看不懂的 500
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='收支流水';

-- ------------------------------------------------------------------
-- 周期记账与预算
-- ------------------------------------------------------------------
-- 前三张表带 family_id，故都不进租户白名单，且都建 FOREIGN KEY (family_id) REFERENCES family(id)
-- 兜住哨兵值 -1；reminder_setting 是用户级偏好，本来就在白名单里，自定义 SQL 必须自己写 user_id 条件。
--
-- reminder_setting 的行是懒创建的——用户第一次打开通知设置页才写，行不存在时按 ReminderType
-- 枚举的默认值处理。
--
-- 幂等唯一索引 uk_exec_rule_date 建在 recurring_execution_log，不建在 transaction(rule_id, biz_date)：
-- transaction 有 deleted 列，MySQL 的唯一索引不看 deleted，软删除的行照样占位。挂在那张表上的后果是
-- 用户删掉一笔自动生成的流水之后，同一天那条规则再也补不回来，而这发生在凌晨的定时任务里、界面上
-- 看不见，排查时会以为是「规则没生效」。执行日志表没有 deleted 列（它是审计轨迹，不需要删），
-- 索引不会被软删行污染，代价只是 transaction.rule_id 退回成一个普通可空列，只用于「这笔流水由
-- 哪条规则生成」的展示与反查。
--
-- budget 用 bucket_key 而不是 UNIQUE(family_id, scope, category_id, member_user_id)：
-- MySQL 唯一索引把 NULL 当互不相等，而 scope = FAMILY 的行后两列必然为 NULL，于是同一家庭可以塞进
-- 任意多行家庭总预算。bucket_key 由后端把三列压成一个非空字符串（FAMILY / C:<id> / M:<id>），
-- 唯一性才真的落下来。客户端不许直接传这个值——它一旦可传就能伪造出绕过唯一约束的桶。

CREATE TABLE recurring_rule (
    id                  BIGINT        NOT NULL COMMENT '雪花 ID',
    family_id           BIGINT        NOT NULL COMMENT '所属家庭。规则家庭级共享，任一成员建的规则生成的流水全家可见',
    name                VARCHAR(20)   NOT NULL COMMENT '规则名 ≤ 20 字符，只用于列表展示，不进流水',
    type                VARCHAR(8)    NOT NULL COMMENT 'EXPENSE / INCOME。由大类派生，不收客户端传入，理由同 transaction.type',
    amount              DECIMAL(12,2) NOT NULL COMMENT '每期金额 > 0，约束同 transaction.amount',
    category_id         BIGINT        NOT NULL COMMENT '大类。不存名称快照：规则是「将来要记什么」的配置，类别改名后规则应跟着显示新名，与流水的快照语义相反',
    sub_category_id     BIGINT        NULL COMMENT '小类，选填',
    account_id          BIGINT        NOT NULL COMMENT '支付方式',
    period_type         VARCHAR(8)    NOT NULL COMMENT 'DAILY / WEEKLY / MONTHLY / YEARLY',
    period_value        VARCHAR(200)  NOT NULL COMMENT '周期的具体参数，JSON 文本。四种 period_type 各用其中一部分字段，由应用层按 type 校验',
    start_date          DATE          NOT NULL COMMENT '生效起始日。当天即计入，缺省取今天',
    end_date            DATE          NULL COMMENT '生效截止日，含当天。NULL 为长期有效',
    enabled             TINYINT       NOT NULL DEFAULT 1 COMMENT '0 暂停 / 1 启用。暂停期间跨过的执行日不会在恢复时补出来（见 last_processed_date）',
    last_processed_date DATE          NULL COMMENT '引擎已处理到的业务日期游标。补记窗口起点取 max(start_date, today-6, last_processed_date+1)，缺这一列则规则恢复时会把暂停期整段补出来',
    created_by          BIGINT        NOT NULL COMMENT '建规则的人。生成的流水以它为记录人；此人退出家庭时规则自动暂停',
    created_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted             TINYINT       NOT NULL DEFAULT 0 COMMENT '逻辑删除。流水上的 rule_id 要始终能反查回规则，故不物理删',
    PRIMARY KEY (id),
    KEY idx_rule_family (family_id, deleted, enabled),
    -- 定时任务跨家庭扫描走这条：它不带 family_id 条件（该方法标了 @InterceptorIgnore），
    -- 所以索引也不能以 family_id 打头
    KEY idx_rule_scan (deleted, enabled, start_date),
    CONSTRAINT fk_rule_family FOREIGN KEY (family_id) REFERENCES family (id)
    -- 不对 category_id / account_id / created_by 建外键，理由同 transaction 建表尾注
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='周期性记账规则';

CREATE TABLE recurring_execution_log (
    id             BIGINT   NOT NULL COMMENT '雪花 ID',
    family_id      BIGINT   NOT NULL COMMENT '所属家庭。冗余存一份，让首页「今天自动生成 N 笔」不必 JOIN 规则表',
    rule_id        BIGINT   NOT NULL COMMENT '哪条规则生成的',
    biz_date       DATE     NOT NULL COMMENT '生成的那笔流水的业务日期',
    transaction_id BIGINT   NOT NULL COMMENT '生成的流水 id',
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '执行时刻。与 biz_date 的日期差即「是否补记」的判据',
    PRIMARY KEY (id),
    -- 幂等就靠这一条：同一规则同一天只允许生成一笔
    UNIQUE KEY uk_exec_rule_date (rule_id, biz_date),
    KEY idx_exec_family_date (family_id, biz_date),
    CONSTRAINT fk_exec_family FOREIGN KEY (family_id) REFERENCES family (id),
    CONSTRAINT fk_exec_rule FOREIGN KEY (rule_id) REFERENCES recurring_rule (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='周期记账执行日志（只记成功，失败留给下一轮重试）';

CREATE TABLE budget (
    id             BIGINT        NOT NULL COMMENT '雪花 ID',
    family_id      BIGINT        NOT NULL COMMENT '所属家庭。预算家庭级共享',
    scope          VARCHAR(16)   NOT NULL COMMENT 'FAMILY / CATEGORY / MEMBER 三个维度',
    category_id    BIGINT        NULL COMMENT 'scope = CATEGORY 时必填，且必须是大类',
    member_user_id BIGINT        NULL COMMENT 'scope = MEMBER 时必填，且必须是本家庭在册成员',
    bucket_key     VARCHAR(32)   NOT NULL COMMENT '唯一性载体：FAMILY / C:<category_id> / M:<user_id>。后端派生，不收客户端传入',
    amount         DECIMAL(12,2) NOT NULL COMMENT '预算额度 > 0，约束同 transaction.amount',
    created_by     BIGINT        NOT NULL COMMENT '最后一次保存这批预算的人',
    created_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    -- 不能用 UNIQUE(family_id, scope, category_id, member_user_id)，理由见上文文件头注释
    UNIQUE KEY uk_budget_bucket (family_id, bucket_key),
    KEY idx_budget_family (family_id, scope),
    CONSTRAINT fk_budget_family FOREIGN KEY (family_id) REFERENCES family (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='三维度预算（整体替换语义，故无 updated_at / deleted）';

CREATE TABLE reminder_setting (
    id         BIGINT      NOT NULL COMMENT '雪花 ID',
    user_id    BIGINT      NOT NULL COMMENT '提醒是用户级偏好，不是家庭级——同一家庭里两个人可以一个开一个关',
    type       VARCHAR(32) NOT NULL COMMENT 'ReminderType 枚举名。最长 CAT_DEWORMING_EXTERNAL 22 字符',
    enabled    TINYINT     NOT NULL COMMENT '0 关 / 1 开。行不存在时按枚举的默认值处理，故本表懒创建',
    created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_reminder_user_type (user_id, type)
    -- 本表在租户白名单里，拦截器不管它，所有自定义 SQL 必须显式写 user_id 条件。它也不建外键：
    -- 开关行要能在用户退出家庭后继续留着，而 reminder_setting 没有 family_id 可挂
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='用户级提醒开关';

-- ------------------------------------------------------------------
-- 猫咪模块
-- ------------------------------------------------------------------
-- 四张表都带 family_id，故都不进租户白名单（理由同上）。
--
-- 外键只建在 family_id 上，cat_deworming.cat_id 是裸列：猫可以先软删而驱虫历史要留得住，
-- 加了外键要么删不动猫、要么逼历史行级联改。
--
-- cat_setting 的行是懒创建的——用户第一次进猫咪设置页点保存才写，GET 无行时按列默认值
-- 回 3 / 1 / NULL（默认值表达在应用层，不靠数据行存在）。
--
-- 归档落 cat.enabled = 0 而不是 deleted = 1：归档的猫要继续出现在历史统计、驱虫完成度和
-- 已有的袋子里，而 @TableLogic 的软删会让它在每一次查询中整体消失。
-- deleted 在这四张表里只表达「这条记录不该存在」，enabled 表达「不再参与新记录」。
--
-- cat_food_bag.active_started_date 是 STORED 生成列 + 唯一索引，而不是把唯一索引直接建在
-- started_date 上：MySQL 的唯一索引不看 deleted，软删行照样占键，「删掉补错的那袋再用同一个
-- 开始日重录」会永久失败。生成列把软删行置 NULL，NULL 在唯一索引里互不相等，于是重复挡在库里、
-- 删后重录放行。该列引用了比它晚定义的 deleted，MySQL 允许。实体类不得映射这一列。
--
-- cat_setting 不建 deleted：PUT 是整体覆盖，留软删列会让 upsert 命中软删行时查不到它而走
-- INSERT 撞 uk_cat_setting_family，留下一个用户在界面上永远修不掉的 500。
--
-- cat.name 不加唯一索引：同家庭两只猫同名是真实情形，库上强制会让「先录第二只再改第一只的
-- 名字」这种顺序无法完成。查重只在应用层做，职责是给出一句人话。

CREATE TABLE cat (
    id                 BIGINT        NOT NULL COMMENT '雪花 ID',
    family_id          BIGINT        NOT NULL COMMENT '所属家庭',
    name               VARCHAR(12)   NOT NULL COMMENT '昵称 ≤ 12 字符，家庭内必填。唯一性由应用层拦，见上文',
    gender             VARCHAR(8)    NOT NULL DEFAULT 'UNKNOWN' COMMENT 'MALE / FEMALE / UNKNOWN。表单三选一必给，落库不为 NULL',
    birthday           DATE          NULL COMMENT '生日。勾了「估算」而只填年月时落该月 1 日',
    birthday_estimated TINYINT       NOT NULL DEFAULT 0 COMMENT '0 精确 / 1 估算。为 1 时 birthday 的「日」没有含义，界面要写成「约 2024-05」而不是「2024-05-01」',
    breed              VARCHAR(20)   NULL COMMENT '品种，选填。下拉常用项与自定义输入都落这一列，不建品种字典表',
    weight_kg          DECIMAL(5,2)  NULL COMMENT '当前体重 kg，两位小数，选填。列名带单位后缀：体重是唯一不带单位的度量列，而宝宝侧体重单位是 g',
    neutered           VARCHAR(8)    NOT NULL DEFAULT 'UNKNOWN' COMMENT 'YES / NO / UNKNOWN',
    remark             VARCHAR(200)  NULL COMMENT '备注 ≤ 200 字符',
    -- 档案照片相对路径，形如 /photos/<uuid>.jpg；读取走鉴权端点。NULL = 无照片
    photo_url          VARCHAR(255)  NULL COMMENT '档案照片相对路径，读取走鉴权端点',
    enabled            TINYINT       NOT NULL DEFAULT 1 COMMENT '1 在册 / 0 已归档。在册上限 10 只由应用层数',
    created_by         BIGINT        NOT NULL COMMENT '建档人',
    created_at         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted            TINYINT       NOT NULL DEFAULT 0 COMMENT '逻辑删除。只对名下没有任何驱虫记录（含已软删）的猫开放，有记录只能归档',
    PRIMARY KEY (id),
    -- 档案列表的排序键是 enabled + 建档先后，故索引前缀取 (family_id, deleted, enabled)；
    -- 建档日筛选走 created_at 但不必单开索引——一个家庭最多 10 只
    KEY idx_cat_family (family_id, deleted, enabled),
    -- 昵称查重按名字点查，列表按 family 扫，两条不共用一个索引前缀也各取所需
    KEY idx_cat_family_name (family_id, name),
    CONSTRAINT fk_cat_family FOREIGN KEY (family_id) REFERENCES family (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='猫咪档案';

CREATE TABLE cat_food_bag (
    id                  BIGINT       NOT NULL COMMENT '雪花 ID',
    family_id           BIGINT       NOT NULL COMMENT '所属家庭。刻意不带 cat_id：一袋粮不预设由哪只猫吃，消耗按家庭整体计',
    brand               VARCHAR(20)  NOT NULL COMMENT '猫粮品牌。自由文本，历史品牌由前端从既有袋里去重记忆，不建字典表',
    pack_grams          INT          NOT NULL COMMENT '包装规格，整数克 > 0。克数用 INT：克数 INT、身高 DECIMAL(5,1)、金额才用 DECIMAL(12,2)',
    started_date        DATE         NOT NULL COMMENT '开始喂养日期。可回溯填过去、不可晚于今天。结束日期与在用状态都不落库，由本列推导',
    active_started_date DATE         GENERATED ALWAYS AS (IF(deleted = 0, started_date, NULL)) STORED NULL COMMENT '在用袋的开始日，软删行为 NULL 以退出下面的唯一索引。实体类不得映射本列',
    remark              VARCHAR(200) NULL COMMENT '备注 ≤ 200 字符',
    created_by          BIGINT       NOT NULL COMMENT '录入人',
    created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted             TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除。删除后时间线自动重新闭合，该行的 active_started_date 转 NULL 从而不再占住开始日',
    PRIMARY KEY (id),
    -- 列表就是 family_id 全量按 started_date 升序，无分页
    KEY idx_bag_family_started (family_id, deleted, started_date),
    UNIQUE KEY uk_food_bag_family_active (family_id, active_started_date),
    CONSTRAINT fk_bag_family FOREIGN KEY (family_id) REFERENCES family (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='猫粮袋记录（消耗推算的唯一数据源）';

CREATE TABLE cat_deworming (
    id          BIGINT       NOT NULL COMMENT '雪花 ID',
    family_id   BIGINT       NOT NULL COMMENT '所属家庭。与 cat_id 冗余同存：查询一律带 family_id 走隔离，cat_id 只表达归属哪只猫',
    cat_id      BIGINT       NOT NULL COMMENT '关联的猫。不建外键，理由见上文',
    type        VARCHAR(8)   NOT NULL COMMENT 'INTERNAL 内驱 / EXTERNAL 外驱。与 ReminderType 的 CAT_DEWORMING_INTERNAL / CAT_DEWORMING_EXTERNAL 一一对应',
    done_date   DATE         NOT NULL COMMENT '驱虫日期，不可晚于今天。下次日期的计算基准是它而不是记录创建时间',
    medicine    VARCHAR(30)  NOT NULL COMMENT '药品名称。自由文本 + 历史记忆，不建字典表',
    dosage      VARCHAR(50)  NULL COMMENT '规格/剂量，选填，纯展示文本（如「1 支」「按体重 4kg 用」）',
    next_date   DATE         NOT NULL COMMENT '下次驱虫日期。服务端按 cat_setting 的月数从 done_date 推算；请求给了就是用户覆盖，照抄不回算。NOT NULL 是刻意的：可空会让倒计时与完成度各写一套 null 分支，而「算不出来」在这里等价于「还没填」，前端该显示输入框而不是空白',
    remark      VARCHAR(200) NULL COMMENT '备注 ≤ 200 字符',
    created_by  BIGINT       NOT NULL COMMENT '记录人',
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted     TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除。名下有没有记录的判定不看它（见 CatDewormingMapper.countAnyForCat），故不能靠 @TableLogic 的默认查询来数',
    PRIMARY KEY (id),
    -- 按猫取下次日期
    KEY idx_deworm_family_cat_next (family_id, cat_id, next_date),
    -- 记录列表按 done_date 倒序全量返回
    KEY idx_deworm_family_done (family_id, deleted, done_date),
    -- 完成度与时间轴按 next_date 扫全家庭（不带 cat_id 前缀），上面那条用不上
    KEY idx_deworm_family_next (family_id, deleted, next_date),
    CONSTRAINT fk_deworm_family FOREIGN KEY (family_id) REFERENCES family (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='体内外驱虫记录';

CREATE TABLE cat_setting (
    id                      BIGINT   NOT NULL COMMENT '雪花 ID',
    family_id               BIGINT   NOT NULL COMMENT '所属家庭，UNIQUE：每家庭至多一行',
    internal_months         INT      NOT NULL DEFAULT 3 COMMENT '内驱周期，月数，默认 3，1–12。改它只影响之后新建的记录，不追溯重算已有 next_date',
    external_months         INT      NOT NULL DEFAULT 1 COMMENT '外驱周期，月数，默认 1，1–12',
    estimated_daily_grams   INT      NULL COMMENT '预估日均克数，1–2000。只在没有任何已完成袋时兜底；一旦有真实袋子即刻失效，设置页要置灰标注「已由历史数据接管」',
    created_by              BIGINT   NOT NULL COMMENT '最后一次 PUT 的操作者。整体覆盖语义下它同时是首次写入者与最后修改者',
    created_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_cat_setting_family (family_id),
    CONSTRAINT fk_cat_setting_family FOREIGN KEY (family_id) REFERENCES family (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='猫咪模块家庭级设置（每家庭至多一行，无 deleted）';

-- ------------------------------------------------------------------
-- 宝宝模块
-- ------------------------------------------------------------------
-- 前六张表都带 family_id，故都不进租户白名单；后两张是静态字典表、没有 family_id，必须在白名单里。
--
-- 外键只建在 family_id 上：baby_growth.baby_id / baby_vaccine_plan.baby_id /
-- baby_vaccine_record.baby_id 与 plan_id 都是裸列。宝宝可被软删而历史记录要留得住，
-- 加了外键要么删不动宝宝、要么逼历史行级联改。
--
-- 归档落 baby.enabled = 0 而不是 deleted = 1：归档的宝宝要继续出现在生长曲线、历史统计与
-- 既有接种记录里，而 @TableLogic 的软删会让它在每一次查询中整体消失。
-- deleted 在这六张表里只表达「这条记录不该存在」，enabled 表达「不再参与新记录」。
-- baby.name 的「家庭内唯一」与「在册上限 5 个」都不建唯一索引、都在应用层拦：库上的唯一索引
-- 会连同软删行一起管，删掉的宝宝会永久占名。
--
-- 两张字典表（vaccine_schedule_dict / growth_standard_dict）四个通用列一个都不带：
-- 没有 family_id（跨家庭共享）、没有 created_by / created_at / updated_at（没有录入人，
-- 出处由 standard_source + source_version 两列表达）、没有 deleted（静态数据不软删）。
-- 它们的唯一索引不是防重复录入，而是挡住转录事故——同一 (疫苗名称, 剂次) 或
-- 同一 (性别, 指标, 横轴) 出现两行是转录错了，让库直接拦住比交付后靠眼看强。
-- 静态字典无软删除，所以「软删行占键」的问题在这里不存在。
--
-- 两张字典表的行由 Java 迁移 1.1（SeedBabyDictionaries）用原生 JDBC + IdWorker 播种
-- （纯 SQL 生成不了雪花 ID），逐条转录自官方原文。

CREATE TABLE baby (
    id           BIGINT       NOT NULL COMMENT '雪花 ID',
    family_id    BIGINT       NOT NULL COMMENT '所属家庭',
    name         VARCHAR(12)  NOT NULL COMMENT '姓名/小名 ≤ 12 字符。家庭内唯一由应用层拦（见上文），且只数未归档的',
    gender       VARCHAR(8)   NOT NULL COMMENT 'MALE / FEMALE。百分位曲线依赖性别，不可空',
    birth_date   DATE         NOT NULL COMMENT '出生日期，不可晚于今天',
    birth_height DECIMAL(5,1) NULL COMMENT '出生身高 cm，一位小数，选填，范围 20.0–200.0',
    birth_weight DECIMAL(5,2) NULL COMMENT '出生体重 kg，两位小数，选填，范围 1.00–100.00',
    remark       VARCHAR(200) NULL COMMENT '备注 ≤ 200 字符',
    -- 档案照片相对路径，形如 /photos/<uuid>.jpg；读取走鉴权端点。NULL = 无照片
    photo_url    VARCHAR(255) NULL COMMENT '档案照片相对路径，读取走鉴权端点',
    enabled      TINYINT      NOT NULL DEFAULT 1 COMMENT '1 在册 / 0 已归档。在册上限 5 个由应用层数',
    created_by   BIGINT       NOT NULL COMMENT '建档人',
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted      TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除。只对名下四张录入表都没有记录的宝宝开放，有记录只能归档',
    PRIMARY KEY (id),
    -- 列表按「在册的在前、其后按建档先后」扫，主要字段取 enabled（见上文）
    KEY idx_baby_family (family_id, deleted, enabled),
    -- 姓名查重按名字点查，列表按 family 扫，两条各取所需不共用前缀
    KEY idx_baby_family_name (family_id, name),
    CONSTRAINT fk_baby_family FOREIGN KEY (family_id) REFERENCES family (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT ='宝宝档案';

CREATE TABLE baby_growth (
    id           BIGINT       NOT NULL COMMENT '雪花 ID',
    family_id    BIGINT       NOT NULL COMMENT '所属家庭',
    baby_id      BIGINT       NOT NULL COMMENT '关联宝宝。裸列不建外键（见上文）',
    measure_date DATE         NOT NULL COMMENT '测量日期，不可晚于今天。同一天允许多条，参与曲线与充当「上一次」的是当天 id 最大的那条',
    height_cm    DECIMAL(5,1) NULL COMMENT '身高 cm，一位小数，20.0–200.0',
    weight_kg    DECIMAL(5,2) NULL COMMENT '体重 kg，两位小数，1.00–100.00',
    head_cm      DECIMAL(5,1) NULL COMMENT '头围 cm，一位小数，30.0–60.0，选填',
    remark       VARCHAR(200) NULL COMMENT '备注 ≤ 200 字符',
    created_by   BIGINT       NOT NULL COMMENT '录入人',
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted      TINYINT      NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    -- 列表就是 family + baby 全量按 measure_date 降序、同日按 id 降序，无分页
    KEY idx_growth_family_baby_date (family_id, baby_id, deleted, measure_date),
    CONSTRAINT fk_growth_family FOREIGN KEY (family_id) REFERENCES family (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT ='身高体重记录';

CREATE TABLE vaccine_schedule_dict (
    id             BIGINT       NOT NULL COMMENT '雪花 ID，由 Java 迁移 1.1 用 IdWorker 生成（纯 SQL 生成不了雪花 ID）',
    vaccine_name   VARCHAR(30)  NOT NULL COMMENT '疫苗名称，与官方表逐字一致',
    disease        VARCHAR(50)  NOT NULL COMMENT '预防疾病，官方表原文',
    dose_no        VARCHAR(8)   NOT NULL COMMENT '剂次序号，官方表原样字符串。流脑的剂次跨疫苗连续（1、2 归 A 群，3、4 归 A 群 C 群），不改成 1、2',
    due_age_months INT          NOT NULL COMMENT '应种月龄，出生后第几个月；2vHPV 第 2 剂取 162（13 岁 + 6 个月）',
    remark         VARCHAR(200) NULL COMMENT '备注，如加强针间隔要求。接种途径 / 剂量毫升数 / 英文缩写三列不落库',
    source_version VARCHAR(16)  NOT NULL COMMENT '程序表版本，存 2026',
    PRIMARY KEY (id),
    -- 挡住转录重复：同一 (疫苗名称, 剂次) 出现两行是转录事故（见上文）
    UNIQUE KEY uk_vaccine_dict_dose (vaccine_name, dose_no),
    -- 生成应种清单时按 due_age_months 升序整表读出
    KEY idx_vaccine_dict_due (due_age_months)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT ='内置免疫规划疫苗程序表（静态字典，四个通用列一个都不带）';

CREATE TABLE growth_standard_dict (
    id              BIGINT       NOT NULL COMMENT '雪花 ID，由 Java 迁移 1.1 生成',
    standard_source VARCHAR(40)  NOT NULL COMMENT '标准号，存 WS/T 423-2022',
    source_version  VARCHAR(16)  NOT NULL COMMENT '版本年份，存 2022',
    gender          VARCHAR(8)   NOT NULL COMMENT 'MALE / FEMALE。男女各 273 行',
    metric          VARCHAR(24)  NOT NULL COMMENT 'HEIGHT_AGE / WEIGHT_AGE / WEIGHT_LENGTH / WEIGHT_HEIGHT / BMI_AGE / HEAD_CIRCUMFERENCE',
    x_value         DECIMAL(4,1) NOT NULL COMMENT '横轴。四个年龄别指标存月龄（0–81，头围 0–36），WEIGHT_LENGTH 存身长 cm（45.0–100.0）、WEIGHT_HEIGHT 存身高 cm（75.0–130.0）。一列逼读取方拿到能直接插值的数',
    p3              DECIMAL(6,2) NOT NULL COMMENT 'P3 百分位',
    p10             DECIMAL(6,2) NOT NULL,
    p25             DECIMAL(6,2) NOT NULL,
    p50             DECIMAL(6,2) NOT NULL,
    p75             DECIMAL(6,2) NOT NULL,
    p90             DECIMAL(6,2) NOT NULL,
    p97             DECIMAL(6,2) NOT NULL,
    PRIMARY KEY (id),
    -- 唯一键同时就是查表索引（where gender + metric order by x_value 正好走它前缀），不再另建普通索引。
    -- 另一作用是挡住转录重复（见上文）
    UNIQUE KEY uk_growth_dict_axis (gender, metric, x_value)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT ='生长标准百分位表（WS/T 423—2022 附录 A 转录，静态）';

CREATE TABLE baby_vaccine_plan (
    id           BIGINT       NOT NULL COMMENT '雪花 ID',
    family_id    BIGINT       NOT NULL COMMENT '所属家庭',
    baby_id      BIGINT       NOT NULL COMMENT '关联宝宝。裸列不建外键（见上文）',
    vaccine_name VARCHAR(30)  NOT NULL COMMENT '疫苗名称。与 dose_no 一起构成改生日重算时的对齐键',
    dose_no      VARCHAR(8)   NOT NULL COMMENT '剂次序号',
    due_date     DATE         NOT NULL COMMENT '应种日期 = 出生日期 + due_age_months 个日历月',
    status       VARCHAR(8)   NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING / DONE / SKIPPED / NA 四态。待接种 / 即将接种 / 逾期由 due_date 与今天现场算，不落库',
    skip_reason  VARCHAR(50)  NULL COMMENT '跳过或不适用的原因。SKIPPED / NA 时必填，撤销时清空',
    record_id    BIGINT       NULL COMMENT '回写的接种记录 id，与 baby_vaccine_record.plan_id 互为反向指针。删记录时清空',
    manual       TINYINT      NOT NULL DEFAULT 0 COMMENT '1 用户手动建（自费项）/ 0 字典生成。决定 DELETE 放不放行，也决定重算时哪些行不参与对齐',
    created_by   BIGINT       NOT NULL,
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted      TINYINT      NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    -- 清单按 due_date 升序，统计的完成率与「下一针」都走这条
    KEY idx_plan_family_baby_due (family_id, baby_id, deleted, due_date),
    -- 改生日重算与接种记录的自动匹配都按这三个键点查
    KEY idx_plan_family_baby_key (family_id, baby_id, vaccine_name, dose_no),
    -- (baby_id, vaccine_name, dose_no) 不加唯一索引：库上的唯一索引会连同软删行一起管，
    -- 而 SKIPPED 的行要留着、重算时要按这三个键逐行对齐，键的可信度由重算逻辑保证
    CONSTRAINT fk_plan_family FOREIGN KEY (family_id) REFERENCES family (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT ='宝宝应种清单（字典生成 + 手动自费项）';

CREATE TABLE baby_vaccine_record (
    id           BIGINT       NOT NULL COMMENT '雪花 ID',
    family_id    BIGINT       NOT NULL COMMENT '所属家庭',
    baby_id      BIGINT       NOT NULL COMMENT '关联宝宝。裸列不建外键（见上文）',
    plan_id      BIGINT       NULL COMMENT '回写到的应种项。为空是正常状态：自费疫苗的首次录入、名称写法不同的补种都没有对应行可回写',
    vaccine_name VARCHAR(30)  NOT NULL COMMENT '疫苗名称。与 dose_no 一起参与应种项的自动匹配',
    dose_no      VARCHAR(8)   NOT NULL COMMENT '剂次序号',
    given_date   DATE         NOT NULL COMMENT '接种日期，不可晚于今天',
    clinic       VARCHAR(50)  NULL COMMENT '接种机构，选填',
    batch_no     VARCHAR(50)  NULL COMMENT '疫苗批号，选填',
    reaction     VARCHAR(200) NULL COMMENT '不良反应，选填',
    next_date    DATE         NULL COMMENT '下一针日期。请求留空时服务端取「该疫苗在本宝宝清单里下一个 PENDING 剂次的 due_date」，清单里没有未完成剂次则留空。NULL 有含义，故不可默认填充',
    remark       VARCHAR(200) NULL COMMENT '备注 ≤ 200 字符',
    created_by   BIGINT       NOT NULL COMMENT '记录人',
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted      TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除。删它要连带把对应应种项退回 PENDING 并清空 record_id，故不能只靠 @TableLogic 的默认删除',
    PRIMARY KEY (id),
    -- 记录列表按 given_date 降序、同日按 id 降序
    KEY idx_record_family_baby_given (family_id, baby_id, deleted, given_date),
    CONSTRAINT fk_record_family FOREIGN KEY (family_id) REFERENCES family (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT ='疫苗接种记录（含回写应种项的反向指针）';

CREATE TABLE baby_milestone (
    id          BIGINT       NOT NULL COMMENT '雪花 ID',
    family_id   BIGINT       NOT NULL COMMENT '所属家庭',
    baby_id     BIGINT       NOT NULL COMMENT '关联宝宝。裸列不建外键（见上文）',
    occur_date  DATE         NOT NULL COMMENT '发生日期，不可晚于今天',
    title       VARCHAR(30)  NOT NULL COMMENT '里程碑名称。内置常用项与自由输入落同一列，库里没有区别',
    description VARCHAR(200) NULL COMMENT '描述，选填',
    created_by  BIGINT       NOT NULL COMMENT '录入人',
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted     TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除。里程碑没有归档语义，两类都是直接删',
    PRIMARY KEY (id),
    -- 时间轴是 occur_date 升序（里程碑时间轴），与就诊的倒序相反
    KEY idx_milestone_family_baby_date (family_id, baby_id, deleted, occur_date),
    CONSTRAINT fk_milestone_family FOREIGN KEY (family_id) REFERENCES family (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT ='宝宝里程碑';

CREATE TABLE baby_medical (
    id          BIGINT        NOT NULL COMMENT '雪花 ID',
    family_id   BIGINT        NOT NULL COMMENT '所属家庭',
    baby_id     BIGINT        NOT NULL COMMENT '关联宝宝。裸列不建外键（见上文）',
    visit_date  DATE          NOT NULL COMMENT '就诊日期，不可晚于今天',
    hospital    VARCHAR(50)   NULL COMMENT '医院，选填',
    department  VARCHAR(30)   NULL COMMENT '科室，选填',
    diagnosis   VARCHAR(200)  NULL COMMENT '诊断，选填',
    medicine    VARCHAR(200)  NULL COMMENT '用药，选填',
    cost_amount DECIMAL(12,2) NULL COMMENT '费用金额，金额一律 DECIMAL(12,2)。本列纯记录，不同步生成流水',
    remark      VARCHAR(200)  NULL COMMENT '备注 ≤ 200 字符',
    created_by  BIGINT        NOT NULL COMMENT '录入人',
    created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted     TINYINT       NOT NULL DEFAULT 0 COMMENT '逻辑删除。就诊记录没有归档语义，直接删',
    PRIMARY KEY (id),
    -- 就诊是回看，列表按 visit_date 降序、同日按 id 降序
    KEY idx_medical_family_baby_date (family_id, baby_id, deleted, visit_date),
    CONSTRAINT fk_medical_family FOREIGN KEY (family_id) REFERENCES family (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT ='宝宝就诊记录';

-- ------------------------------------------------------------------
-- 模块开关（用户级偏好）
-- ------------------------------------------------------------------
-- 本表没有 family_id，且在租户白名单里。后果有两条：
--   ① 租户拦截器不管它，所有自定义 SQL 必须自己写 user_id 条件；
--   ② 它一张外键都不建——没有 family_id 可挂，而「外键只建在 family_id 上」是全局约定；
--      user_id 也不建外键，与 reminder_setting 同一条理由：开关行要能在用户退出家庭后继续留着。
--
-- 通用列：缺的只有 family_id；created_at / updated_at 照 reminder_setting 补齐。
-- 不建 created_by：这是用户级偏好，操作者恒为 user_id 本人，再存一列只是一个恒等的冗余。
--
-- 行懒创建：GET 在没有任何行时按 ModuleKey 的默认值返回，PUT 才 upsert——「打开一次设置页」
-- 不是写入事件，否则每个账号都会凭空多出几行说不清归属的记录。
--
-- 唯一索引 uk_module_user_key 是真正的约束：同一个用户对同一个模块只能有一行，PUT 的 upsert 靠它兜底。

CREATE TABLE module_preference (
    id         BIGINT      NOT NULL COMMENT '雪花 ID',
    user_id    BIGINT      NOT NULL COMMENT '模块开关是用户级偏好，不是家庭级——同一家庭里两个人可以各看各的 Tab',
    module_key VARCHAR(16) NOT NULL COMMENT 'ModuleKey 枚举名：FINANCE / CAT / BABY。最长 7 字符，16 足够',
    enabled    TINYINT     NOT NULL COMMENT '0 关 / 1 开。行不存在时按枚举的默认值处理，故本表懒创建',
    sort_no    INT         NOT NULL COMMENT '中间三个 Tab 的展示顺序，由 PUT 的数组顺序派生，不收客户端传入的序号',
    created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_module_user_key (user_id, module_key)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci COMMENT ='用户级模块开关与 Tab 顺序';