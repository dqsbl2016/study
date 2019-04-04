
/*
*   user
*/

CREATE TABLE `t_user_consumer` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `birthday` int(11) COMMENT '出生日期',
  `sex` tinyint(4) NOT NULL DEFAULT '1' COMMENT '性别 1男，2女',
  `icn` varchar(18) NOT NULL DEFAULT '0' COMMENT '身份证号',
  `picture` varchar(512) NOT NULL DEFAULT '' COMMENT '头像',
  `name` varchar(100) NOT NULL DEFAULT '' COMMENT '客户名称',
  `phone` varchar(20) NOT NULL DEFAULT '0' COMMENT '联系电话',
  `remark` varchar(1000) NOT NULL DEFAULT '' COMMENT '备注',
  `company_id` bigint(11) NOT NULL DEFAULT '0' COMMENT '注册门店id 0表示自己注册',
  `province_id` int(11) NOT NULL DEFAULT '0' COMMENT '行政省ID',
  `province_name` varchar(200) NOT NULL DEFAULT '' COMMENT '行政省名称',
  `city_id` int(11) NOT NULL DEFAULT '0' COMMENT '行政城市ID',
  `city_name` varchar(200) NOT NULL DEFAULT '' COMMENT '行政城市名称',
  `address` varchar(255) DEFAULT '' COMMENT '地址',
  
  `operator_id` varchar(50) DEFAULT '' COMMENT '操作员',
  `c_t` int(11) NOT NULL COMMENT '创建时间',
  `u_t` int(11) NOT NULL COMMENT '最后更新时间',
   `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='客户档案';

CREATE TABLE `t_user_producer` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `birthday` int(11) COMMENT '出生日期',
  `sex` tinyint(4) NOT NULL DEFAULT '1' COMMENT '性别 1男，2女',
  `icn` varchar(18) NOT NULL DEFAULT '0' COMMENT '身份证号',
  `picture` varchar(512) NOT NULL DEFAULT '' COMMENT '头像',
  `name` varchar(100) NOT NULL DEFAULT '' COMMENT '名称',
  `phone` varchar(20) NOT NULL DEFAULT '0' COMMENT '联系电话',
  `remark` varchar(1000) NOT NULL DEFAULT '' COMMENT '备注',
  `company_id` bigint(11) NOT NULL DEFAULT '0' COMMENT '当前所在门店id 0表示当前无门店',
  `is_employer` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否是店主',
  `province_id` int(11) NOT NULL DEFAULT '0' COMMENT '行政省ID',
  `province_name` varchar(200) NOT NULL DEFAULT '' COMMENT '行政省名称',
  `city_id` int(11) NOT NULL DEFAULT '0' COMMENT '行政城市ID',
  `city_name` varchar(200) NOT NULL DEFAULT '' COMMENT '行政城市名称',
  `address` varchar(255) DEFAULT '' COMMENT '地址',
  
  
  `operator_id` varchar(50) DEFAULT '' COMMENT '操作员',
  `c_t` int(11) NOT NULL COMMENT '创建时间',
  `u_t` int(11) NOT NULL COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='技师档案';

CREATE TABLE `t_user_emplayee` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `birthday` int(11) COMMENT '出生日期',
  `sex` tinyint(4) NOT NULL DEFAULT '1' COMMENT '性别 1男，2女',
  `icn` varchar(18) NOT NULL DEFAULT '0' COMMENT '身份证号',
  `picture` varchar(512) NOT NULL DEFAULT '' COMMENT '头像',
  `name` varchar(100) NOT NULL DEFAULT '' COMMENT '名称',
  `phone` varchar(20) NOT NULL DEFAULT '0' COMMENT '联系电话',
  `remark` varchar(1000) NOT NULL DEFAULT '' COMMENT '备注',
  `company_id` bigint(11) NOT NULL DEFAULT '1' COMMENT '当前所在门店id 1表示总部',
  `is_employer` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否是店主',
  `province_id` int(11) NOT NULL DEFAULT '0' COMMENT '行政省ID',
  `province_name` varchar(200) NOT NULL DEFAULT '' COMMENT '行政省名称',
  `city_id` int(11) NOT NULL DEFAULT '0' COMMENT '行政城市ID',
  `city_name` varchar(200) NOT NULL DEFAULT '' COMMENT '行政城市名称',
  `address` varchar(255) DEFAULT '' COMMENT '地址',
  
  
  `operator_id` varchar(50) DEFAULT '' COMMENT '操作员',
  `c_t` int(11) NOT NULL COMMENT '创建时间',
  `u_t` int(11) NOT NULL COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='员工档案';


CREATE TABLE `t_user_franchisee` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `birthday` int(11) COMMENT '出生日期',
  `sex` tinyint(4) NOT NULL DEFAULT '1' COMMENT '性别 1男，2女',
  `icn` varchar(18) NOT NULL DEFAULT '0' COMMENT '身份证号',
  `picture` varchar(512) NOT NULL DEFAULT '' COMMENT '头像',
  `name` varchar(100) NOT NULL DEFAULT '' COMMENT '名称',
  `phone` varchar(20) NOT NULL DEFAULT '0' COMMENT '联系电话',
  `remark` varchar(1000) NOT NULL DEFAULT '' COMMENT '备注',
  `company_id` bigint(11) NOT NULL DEFAULT '0' COMMENT '当前所在门店id 0表示无',
  `province_id` int(11) NOT NULL DEFAULT '0' COMMENT '行政省ID',
  `province_name` varchar(200) NOT NULL DEFAULT '' COMMENT '行政省名称',
  `city_id` int(11) NOT NULL DEFAULT '0' COMMENT '行政城市ID',
  `city_name` varchar(200) NOT NULL DEFAULT '' COMMENT '行政城市名称',
  `address` varchar(255) DEFAULT '' COMMENT '地址',
  
  
  `operator_id` varchar(50) DEFAULT '' COMMENT '操作员',
  `c_t` int(11) NOT NULL COMMENT '创建时间',
  `u_t` int(11) NOT NULL COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='加盟商档案';


/*
*   company
*/

CREATE TABLE `t_company` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `picture` varchar(512) NOT NULL DEFAULT '' COMMENT '公司图片',
  `name` varchar(100) NOT NULL DEFAULT '' COMMENT '公司名称',
  `phone` varchar(20) NOT NULL DEFAULT '0' COMMENT '公司联系电话',
  `remark` varchar(1000) NOT NULL DEFAULT '' COMMENT '备注',
  `province_id` int(11) NOT NULL DEFAULT '0' COMMENT '行政省ID',
  `province_name` varchar(200) NOT NULL DEFAULT '' COMMENT '行政省名称',
  `city_id` int(11) NOT NULL DEFAULT '0' COMMENT '行政城市ID',
  `city_name` varchar(200) NOT NULL DEFAULT '' COMMENT '行政城市名称',
  `address` varchar(255) DEFAULT '' COMMENT '地址',
  `type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '公司类型 1集团 2直营 3加盟',
  
  `operator_id` varchar(50) DEFAULT '' COMMENT '操作员',
  `c_t` int(11) NOT NULL COMMENT '创建时间',
  `u_t` int(11) NOT NULL COMMENT '最后更新时间',
  `is_deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否删除',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='公司';

