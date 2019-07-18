alter table t_type add column is_service tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否服务岗位' AFTER `name`;

alter table t_employee_info add column app_num int(11)  DEFAULT '0' COMMENT '预约次数' AFTER `company_id`;

alter table t_company_info add column inbody varchar(1000) DEFAULT '' COMMENT '当前正文' AFTER `address`;

alter table t_service_item add column picture varchar(512) DEFAULT '' COMMENT '项目图片' AFTER `name`;

alter table t_consumer_info add column open_id varchar(100)  DEFAULT '' COMMENT 'open_id' AFTER `phone`;

alter table t_consumer_info add column union_id varchar(100) DEFAULT '' COMMENT 'union_id' AFTER `phone`;

ALTER TABLE t_consumer_info DROP index  idx_phone;
ALTER TABLE t_consumer_info ADD index  idx_phone(phone);
ALTER TABLE t_consumer_info ADD index  idx_open_id(open_id);
ALTER TABLE t_consumer_info ADD index  idx_union_id(union_id);

alter table t_consumer_info add column app_num int(11)  DEFAULT '0' COMMENT '预约次数' AFTER `money`;
alter table t_consumer_info add column can_num int(11)  DEFAULT '0' COMMENT '预约取消次数' AFTER `money`;

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
