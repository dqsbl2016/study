/*
*	employee
*/

CREATE TABLE `t_employee_info` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `birthday` int(11) DEFAULT NULL COMMENT '出生日期',
  `sex` tinyint(4) NOT NULL DEFAULT '1' COMMENT '性别 1男，2女',
  `icn` varchar(18) NOT NULL DEFAULT '0' COMMENT '身份证号',
  `picture` varchar(512) NOT NULL DEFAULT '' COMMENT '头像',
  `name` varchar(100) NOT NULL DEFAULT '' COMMENT '员工名称',
  `phone` varchar(13) NOT NULL DEFAULT '0' COMMENT '联系电话',
  `status` tinyint(4) NOT NULL DEFAULT '1' COMMENT '状态 1在职，2离职',
  `remark` varchar(1000) DEFAULT '' COMMENT '备注',
  `company_id` bigint(11) NOT NULL DEFAULT '0' COMMENT '所属机构',
  `app_num` int(11)  DEFAULT '0' COMMENT '预约次数',
  `join_t` int(11) NOT NULL DEFAULT '0' COMMENT '入职日期',
  `leave_t` int(11) NOT NULL DEFAULT '0' COMMENT '离职日期',
  `province_id` int(11) NOT NULL DEFAULT '0' COMMENT '行政省ID',
  `province_name` varchar(200) DEFAULT '' COMMENT '行政省名称',
  `city_id` int(11) NOT NULL DEFAULT '0' COMMENT '行政城市ID',
  `city_name` varchar(200) DEFAULT '' COMMENT '行政城市名称',
  `address` varchar(255) NOT NULL DEFAULT '' COMMENT '地址',
  `datekey` int(11) NOT NULL DEFAULT '0' COMMENT 'datekey',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_company_id` (`company_id`),
  UNIQUE KEY `idx_phone` (`phone`) USING BTREE,
  KEY `idx_datekey` (`datekey`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='员工档案';


CREATE TABLE `t_employee_account` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `employee_id` int(11) NOT NULL DEFAULT '0' COMMENT '关联员工信息主键ID',
  `phone` varchar(20)  NOT NULL DEFAULT '' COMMENT '手机号',
  `password` varchar(512) NOT NULL DEFAULT '' COMMENT '密码',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
 `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_phone` (`phone`),
  KEY `idx_employee_id` (`employee_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='员工账号';


CREATE TABLE `t_employee_login_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `employee_id` int(11) NOT NULL DEFAULT '0' COMMENT '员工信息主键ID',
  `ip` varchar(20)  NOT NULL DEFAULT '' COMMENT '登陆IP',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
 `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_employee_id` (`employee_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='登陆日志';

CREATE TABLE `t_employee_correlation_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `company_id` int(11) NOT NULL DEFAULT '0' COMMENT '门店ID',
  `employee_id` int(11) NOT NULL DEFAULT '0' COMMENT '员工信息主键ID',
  `type` tinyint(4) NOT NULL DEFAULT '1' COMMENT '状态 1入职，2离职', 
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
 `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_employee_id` (`employee_id`),
  KEY `idx_company_id` (`company_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='员工入离职日志';

CREATE TABLE `t_employee_transfer_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `old_company` int(11) NOT NULL DEFAULT '0' COMMENT '原门店ID',
  `new_company` int(11) NOT NULL DEFAULT '0' COMMENT '新门店ID',
  `employee_id` int(11) NOT NULL DEFAULT '0' COMMENT '员工信息主键ID',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
 `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_employee_id` (`employee_id`),
  KEY `idx_old_company` (`old_company`),
  KEY `idx_new_company` (`new_company`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='员工调动日志';


CREATE TABLE `t_type` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(10) NOT NULL DEFAULT '' COMMENT '分类名称',
  `is_service` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否服务岗位',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='员工分类信息';

CREATE TABLE `t_type_level` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `type_id` int(11) NOT NULL DEFAULT '0' COMMENT '分类ID',
  `name` varchar(10) NOT NULL DEFAULT '' COMMENT '级别名称',
  `sort` tinyint(4) NOT NULL DEFAULT '0' COMMENT '级别',
  `is_config` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否配置分成 0配置 1配置',
  `allot_type` tinyint(4) NOT NULL DEFAULT '1' COMMENT '分配方式 1百分百 2固定值',
  `amount` int(11) NOT NULL DEFAULT '0' COMMENT '具体额度 * 1000 ',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_type_id` (`type_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='员工分类级别详情';


CREATE TABLE `t_employee_fixedratio` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `level_id` int(11) NOT NULL DEFAULT '0' COMMENT '级别主键',
  `type_id` int(11) NOT NULL DEFAULT '0' COMMENT '分类ID',
  `employee_id` int(11) NOT NULL DEFAULT '0' COMMENT '员工信息主键ID',
  `is_config` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否配置分成 0配置 1配置',
  `allot_type` tinyint(4) NOT NULL DEFAULT '1' COMMENT '分配方式 1百分百 2固定值',
  `amount` int(11) NOT NULL DEFAULT '0' COMMENT '具体额度 * 1000 ',
  `is_person` tinyint(4) NOT NULL DEFAULT '0' COMMENT '0通用 1个性化',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_employee` (`employee_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COMMENT='员工收入分成';

CREATE TABLE `t_employee_type` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `type_id` int(11) NOT NULL DEFAULT '0' COMMENT '分类ID',
  `employee_id` int(11) NOT NULL DEFAULT '0' COMMENT '员工信息主键ID',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_employee` (`employee_id`,`type_id`) USING BTREE,
  KEY `idx_type` (`type_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COMMENT='员工分类';

CREATE TABLE `t_employee_clearing` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `employee_id` int(11) NOT NULL DEFAULT '0' COMMENT '员工信息主键ID',
  `checkout_id` int(11) NOT NULL DEFAULT '0' COMMENT '消费订单ID',
  `service_id` int(11) NOT NULL DEFAULT '0' COMMENT '项目ID',
  `type_id` int(11) NOT NULL DEFAULT '0' COMMENT '分类ID',
  `level_id` int(11) NOT NULL DEFAULT '0' COMMENT '级别ID',
  `allot_type` tinyint(4) NOT NULL DEFAULT '1' COMMENT '分配方式 1百分百 2固定值',
  `amount` int(11) NOT NULL DEFAULT '0' COMMENT '具体额度 * 1000 ',
  `money` int(11)  NOT NULL DEFAULT '0' COMMENT '分成金额 * 1000',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_employee` (`employee_id`) USING BTREE,
  KEY `checkout` (`checkout_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COMMENT='员工分成情况';

/*
*   company
*/

CREATE TABLE `t_company_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT '上级机构',
  `picture` varchar(512) NOT NULL DEFAULT '' COMMENT '机构图片',
  `name` varchar(100) NOT NULL DEFAULT '' COMMENT '机构名称',
  `phone` varchar(20) NOT NULL DEFAULT '0' COMMENT '机构联系电话',
  `remark` varchar(500) NOT NULL DEFAULT '' COMMENT '备注',
  `province_id` int(11) NOT NULL DEFAULT '0' COMMENT '行政省ID',
  `province_name` varchar(200) NOT NULL DEFAULT '' COMMENT '行政省名称',
  `city_id` int(11) NOT NULL DEFAULT '0' COMMENT '行政城市ID',
  `city_name` varchar(200) NOT NULL DEFAULT '' COMMENT '行政城市名称',
  `address` varchar(255) DEFAULT '' COMMENT '地址',
  `inbody` varchar(1000) DEFAULT '' COMMENT '当前正文',
  `type` tinyint(4) NOT NULL DEFAULT '1' COMMENT '公司类型0总部 1直营 2加盟',
  `status` tinyint(4) NOT NULL DEFAULT '1' COMMENT '状态1营业 2关闭',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='机构信息';

CREATE TABLE `t_company_auth` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_id` int(11) NOT NULL DEFAULT '0' COMMENT '人员ID',
  `company_id` int(11) NOT NULL DEFAULT '0' COMMENT '机构ID',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_e_c` (`employee_id`,`company_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='人员门店权限';


/*
*	consumer
*/

CREATE TABLE `t_consumer_info` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `birthday` int(11) DEFAULT NULL COMMENT '出生日期',
  `sex` tinyint(4) NOT NULL DEFAULT '1' COMMENT '性别 1男，2女',
  `icn` varchar(18) DEFAULT '0' COMMENT '身份证号',
  `picture` varchar(512)  DEFAULT '' COMMENT '头像',
  `name` varchar(100) NOT NULL DEFAULT '' COMMENT '客户名称',
  `phone` varchar(20) NOT NULL DEFAULT '0' COMMENT '联系电话',
  `open_id` varchar(100)  DEFAULT '' COMMENT 'open_id',
  `union_id` varchar(100)  DEFAULT '' COMMENT '微信union_id',
  `remark` varchar(1000) DEFAULT '' COMMENT '备注',
  `company_id` bigint(11) DEFAULT '0' COMMENT '注册门店id 0表示自己注册',
  `money` int(11) DEFAULT '0' COMMENT '剩余金额 * 1000',
  `app_num` int(11) DEFAULT '0' COMMENT '预约次数',
  `can_num` int(11) DEFAULT '0' COMMENT '预约取消次数',
  `province_id` int(11) DEFAULT '0' COMMENT '行政省ID',
  `province_name` varchar(200) DEFAULT '' COMMENT '行政省名称',
  `city_id` int(11) DEFAULT '0' COMMENT '行政城市ID',
  `city_name` varchar(200) DEFAULT '' COMMENT '行政城市名称',
  `address` varchar(255) DEFAULT '' COMMENT '地址',
  `datakey` int(11)  NOT NULL DEFAULT '0' COMMENT 'datakey',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_phone` (`phone`) USING BTREE,
  KEY `idx_open_id` (`open_id`) USING BTREE,
  KEY `idx_union_id` (`union_id`) USING BTREE,
  KEY `idx_name` (`name`) USING BTREE,
  KEY `idx_datekey` (`datekey`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='客户档案';



CREATE TABLE `t_consumer_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `consumer_id` int(11)  NOT NULL DEFAULT '0' COMMENT '客户ID',
  `company_id` int(11)  NOT NULL DEFAULT '0' COMMENT '门店ID',
  `type` int(11)  NOT NULL DEFAULT '0' COMMENT '1充值 2消费',
  `oldmoney` int(11)  NOT NULL DEFAULT '0' COMMENT '充值前余额 * 1000',
  `money` int(11)  NOT NULL DEFAULT '0' COMMENT '充值金额 * 1000',
  `newmoney` int(11)  NOT NULL DEFAULT '0' COMMENT '充值后金额 * 1000',
  `order_id` int(11)  NOT NULL DEFAULT '0' COMMENT '订单ID',
  `remark` varchar(1000) DEFAULT '' COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_consumer` (`consumer_id`,`type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='客户充值/消费记录';

CREATE TABLE `t_consumer_coupon` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `consumer_id` int(11)  NOT NULL DEFAULT '0' COMMENT '客户ID',
  `coupon_id` int(11) NOT NULL DEFAULT '0' COMMENT '优惠卷ID',
  `status` tinyint(4) NOT NULL DEFAULT '0' COMMENT '状态 0未使用，1已使用 2已过期 3销毁',
  `s_t` int(11) NOT NULL DEFAULT '0' COMMENT '有效期 开始时间',
  `e_t` int(11) NOT NULL DEFAULT '0' COMMENT '有效期 结束时间',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_consumer` (`consumer_id`,`status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='客户领取优惠卷';



/*
*  order 订单
*/
CREATE TABLE `t_order_topup` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `consumer_id` int(11)  NOT NULL DEFAULT '0' COMMENT '客户ID',
  `discounts_id` int(11)  NOT NULL DEFAULT '0' COMMENT '活动ID',
  `company_id` int(11)  NOT NULL DEFAULT '0' COMMENT '门店ID',
  `discounts_type` tinyint(11)  NOT NULL DEFAULT '0' COMMENT '活动类型 0赠金额 1赠优惠卷',
  `oldmoney` int(11)  NOT NULL DEFAULT '0' COMMENT '充值前余额 * 1000',
  `money` int(11)  NOT NULL DEFAULT '0' COMMENT '充值金额 * 1000',
  `gift` int(11)  NOT NULL DEFAULT '0' COMMENT '赠送金额 * 1000',
  `newmoney` int(11)  NOT NULL DEFAULT '0' COMMENT '充值后金额 * 1000', 
  `status` tinyint(4) NOT NULL DEFAULT '0' COMMENT '状态 0待付款，1已完成 2已取消',
  `remark` varchar(1000) DEFAULT '' COMMENT '备注',
  `datakey` int(11)  NOT NULL DEFAULT '0' COMMENT 'datakey',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_consumer` (`consumer_id`) USING BTREE,
  KEY `idx_discunts` (`discounts_id`) USING BTREE,
  KEY `idx_datekey` (`datakey`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='客户充值订单';

CREATE TABLE `t_order_topup_coupon` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `topup_id` int(11)  NOT NULL DEFAULT '0' COMMENT '充值订单ID',
  `consumer_id` int(11)  NOT NULL DEFAULT '0' COMMENT '客户ID',
  `discounts_id` int(11)  NOT NULL DEFAULT '0' COMMENT '活动ID',
  `coupon_id` int(11)  NOT NULL DEFAULT '0' COMMENT '优惠卷ID',
  `num` int(11)  NOT NULL DEFAULT '0' COMMENT '数量',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_topup` (`topup_id`) USING BTREE,
  KEY `idx_consumer` (`consumer_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='客户充值订单赠送优惠卷情况';

CREATE TABLE `t_order_checkout` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `consumer_id` int(11)  NOT NULL DEFAULT '0' COMMENT '客户ID',
  `company_id` int(11)  NOT NULL DEFAULT '0' COMMENT '门店ID',
  `old_money` int(11)  NOT NULL DEFAULT '0' COMMENT '消费前余额 * 1000',
  `money` int(11)  NOT NULL DEFAULT '0' COMMENT '消费金额 * 1000',
  `discount` int(11)  NOT NULL DEFAULT '0' COMMENT '折扣 * 1000',
  `sub_money` int(11)  NOT NULL DEFAULT '0' COMMENT '扣除余额 * 1000',
  `new_money` int(11)  NOT NULL DEFAULT '0' COMMENT '消费后余额 * 1000',
  `fina_money` int(11)  NOT NULL DEFAULT '0' COMMENT '实付余额 * 1000',
  `status` tinyint(4) NOT NULL DEFAULT '0' COMMENT '状态 0待付款，1已完成 2已取消',
  `remark` varchar(1000) DEFAULT '' COMMENT '备注',
  `datakey` int(11)  NOT NULL DEFAULT '0' COMMENT 'datakey',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_consumer` (`consumer_id`) USING BTREE,
  KEY `idx_company` (`company_id`) USING BTREE,
  KEY `idx_datekey` (`datakey`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='客户消费订单';

CREATE TABLE `t_order_checkout_service` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `consumer_id` int(11)  NOT NULL DEFAULT '0' COMMENT '客户ID',
  `checkout_id` int(11)  NOT NULL DEFAULT '0' COMMENT '消费订单ID',
  `service_id` int(11)  NOT NULL DEFAULT '0' COMMENT '项目ID',
  `service_name` varchar(100) NOT NULL DEFAULT '' COMMENT '项目名称',
  `service_time` int(11)  NOT NULL DEFAULT '0' COMMENT '服务时长',
  `is_sub` tinyint(4) NOT NULL DEFAULT '0' COMMENT '0统一价 1细分',
  `level_id` int(11)  NOT NULL DEFAULT '0' COMMENT '级别ID',
  `level_name` varchar(100) NOT NULL DEFAULT '' COMMENT '岗位级别名称',
  `service_price` int(11)  NOT NULL DEFAULT '0' COMMENT '服务价格 * 1000',
  `service_num` int(11)  NOT NULL DEFAULT '0' COMMENT '消费数量',
  `service_sum` int(11)  NOT NULL DEFAULT '0' COMMENT '总计价格 * 1000',
  `employee_id` int(11)  NOT NULL DEFAULT '0' COMMENT '技师ID',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_consumer` (`consumer_id`) USING BTREE,
  KEY `idx_checkout` (`checkout_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='客户消费订单项目详情';

CREATE TABLE `t_order_checkout_coupon` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `checkout_id` int(11)  NOT NULL DEFAULT '0' COMMENT '消费订单ID',
  `services` varchar(50) DEFAULT NULL COMMENT '项目IDs',
  `consumer_id` int(11)  NOT NULL DEFAULT '0' COMMENT '客户ID',
  `coupon_id` int(11)  NOT NULL DEFAULT '0' COMMENT '优惠卷ID',
  `num` int(11)  NOT NULL DEFAULT '0' COMMENT '数量',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_checkout` (`checkout_id`) USING BTREE,
  KEY `idx_consumer` (`consumer_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='客户消费订单使用优惠卷情况';

/*
*  service 服务项目
*/

CREATE TABLE `t_service_item` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(50)  NOT NULL DEFAULT '' COMMENT '服务项名称',
  `picture` varchar(512) DEFAULT '' COMMENT '项目图片',
  `service_time` int(11) NOT NULL DEFAULT '0' COMMENT '服务时长 单位分',
  `price` int(11) NOT NULL DEFAULT '0' COMMENT '服务价格 * 1000',
  `is_sub` tinyint(4) NOT NULL DEFAULT '0' COMMENT '0统一价 1细分',
  `type_id` int(11) NOT NULL DEFAULT '0' COMMENT '员工分类ID（服务岗位）',
  `remark` varchar(1000) DEFAULT '' COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='服务项目';

CREATE TABLE `t_service_sub` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `service_id` int(11) NOT NULL DEFAULT '0' COMMENT '项目ID',
  `level_id` int(11) NOT NULL DEFAULT '0' COMMENT '级别ID',
  `type_id` int(11) NOT NULL DEFAULT '0' COMMENT '分类ID',
  `price` int(11) NOT NULL DEFAULT '0' COMMENT '服务价格 * 1000',
  `remark` varchar(1000) DEFAULT '' COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_service` (`service_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='服务项目细分';

/*
*  discounts 优惠活动
*/

CREATE TABLE `t_discounts_info` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(50)  NOT NULL DEFAULT '' COMMENT '活动名称',
  `s_t` int(11) NOT NULL DEFAULT '0' COMMENT '开始时间',
  `e_t` int(11) NOT NULL DEFAULT '0' COMMENT '结束时间',
  `type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '活动方式 0赠金额 1赠优惠卷',
  `threshold` int(11) NOT NULL DEFAULT '0' COMMENT '要求金额 * 1000',
  `gift` int(11) NOT NULL DEFAULT '0' COMMENT '赠送金额 * 1000 ',
  `is_sup` tinyint(4) NOT NULL DEFAULT '0' COMMENT '叠加方式 0不叠加 1叠加',
  `num` tinyint(4) NOT NULL DEFAULT '0' COMMENT '每人限制次数 0不限制 ',
  `company` varchar(50)  NOT NULL DEFAULT '' COMMENT '活动门店ids ,间隔 空表示全部店',
  `status` tinyint(4) NOT NULL DEFAULT '0' COMMENT '活动方式 0未开启 1正常 2已结束 3强制结束',
  `remark` varchar(1000) DEFAULT '' COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_period` (`s_t`,`e_t`) USING BTREE,
  KEY `idx_status` (`status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='优惠活动信息';

CREATE TABLE `t_coupon_info` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `name` varchar(50)  NOT NULL DEFAULT '' COMMENT '优惠卷名称',
  `period_num` int(11) NOT NULL DEFAULT '0' COMMENT '领取后有效期 单位小时',
  `s_t` int(11) NOT NULL DEFAULT '0' COMMENT '开始时间',
  `e_t` int(11) NOT NULL DEFAULT '0' COMMENT '结束时间',
  `type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '优惠卷类型 0通用赠卷 1活动赠卷',
  `threshold` int(11) NOT NULL DEFAULT '0' COMMENT '使用金额 * 1000',
  `deduction` int(11) NOT NULL DEFAULT '0' COMMENT '抵扣金额 * 1000',
  `is_sup` tinyint(4) NOT NULL DEFAULT '0' COMMENT '使用方式 0不叠加 1叠加',
  `num` tinyint(4) NOT NULL DEFAULT '0' COMMENT '每人限领数量 0不限制 ',
  `service` varchar(50) NOT NULL DEFAULT '' COMMENT '可使用项目 空表示全部可以使用',
  `status` tinyint(4) NOT NULL DEFAULT '0' COMMENT '状态 0未开放 1有效 2已过期 3强制结束',
  `remark` varchar(1000) DEFAULT '' COMMENT '备注',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_period` (`s_t`,`e_t`) USING BTREE,
  KEY `idx_status` (`status`) USING BTREE,
  KEY `idx_type` (`type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='优惠卷信息';

CREATE TABLE `t_discounts_coupon` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `discounts_id` int(11) NOT NULL DEFAULT '0' COMMENT '活动Id',
  `coupon_id` int(11) NOT NULL DEFAULT '0' COMMENT '优惠卷ID',
  `num` tinyint(4) NOT NULL DEFAULT '0' COMMENT '数量',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_dc` (`discounts_id`,`coupon_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='活动赠送优惠卷情况';


/*
*	appointment  预约情况
*/

CREATE TABLE `t_appointment_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `pid` int(11) NOT NULL  DEFAULT '0' COMMENT 'PID',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '时间范围',
  `sort` tinyint(4) NOT NULL DEFAULT '0' COMMENT '排序ID',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_pid` (`pid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='预约时间分段配置';


CREATE TABLE `t_appointment_info` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `company_id` int(11) NOT NULL  DEFAULT '0' COMMENT '预约门店ID',
  `config_id` int(11) NOT NULL  DEFAULT '0' COMMENT '时间段ID',
  `config_sort` tinyint(4) NOT NULL  DEFAULT '0' COMMENT '时间段排序字段',
  `config_name` varchar(50) NOT NULL DEFAULT '' COMMENT '时间段名称',
  `consumer_id` int(11) NOT NULL DEFAULT '0' COMMENT '预约人ID',
  `app_date` varchar(50) NOT NULL DEFAULT '' COMMENT '预约日期名称',
  `app_datekey` int(11) NOT NULL DEFAULT '0' COMMENT '预约日期',
  `aemployee_id` int(11)  DEFAULT '0' COMMENT '预约技师ID',
  `is_arrange` tinyint(4)  DEFAULT '0' COMMENT '是否重新安排技师 1重新指定',
  `employee_id` int(11)  DEFAULT '0' COMMENT '服务技师ID',
  `service_id` int(11) NOT NULL DEFAULT '0' COMMENT '预约项目ID',
  `is_sub` tinyint(4) NOT NULL DEFAULT '0' COMMENT '收费方式 0统一价 1细分',
  `level_id` int(11) NOT NULL DEFAULT '0' COMMENT '服务级别',
  `price` int(11) NOT NULL DEFAULT '0' COMMENT '费用 * 1000',
  `person_num` int(11) NOT NULL DEFAULT '1' COMMENT '预约人数 0表示多人',
  `remark` varchar(1000) DEFAULT '' COMMENT '备注',
  `status` tinyint(4) NOT NULL DEFAULT '0' COMMENT '状态 0待接单 1已接单 2已完成 3已取消',
  `datekey` int(11) NOT NULL DEFAULT '0' COMMENT 'datekey',
  `creator` int(11) NOT NULL DEFAULT '0' COMMENT '创建人',
  `modifier` int(11) NOT NULL DEFAULT '0' COMMENT '修改人',
  `c_t` int(11) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `u_t` int(11) NOT NULL DEFAULT '0' COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_company` (`company_id`,`app_datekey`) USING BTREE,
  KEY `idx_employee` (`employee_id`,`app_datekey`) USING BTREE,
  KEY `idx_consumer` (`consumer_id`,`app_datekey`) USING BTREE,
  KEY `idx_datekey` (`app_datekey`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='预约信息表';


