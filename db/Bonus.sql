CREATE TABLE `bonus_log` (
  `date` datetime NOT NULL default '0000-00-00 00:00:00',
  `sum` double(10,2) NOT NULL default '0.00',
  `dsc` varchar(80) default NULL,
  `ip` int(11) unsigned NOT NULL default '0',
  `last_deposit` double(15,6) NOT NULL default '0.000000',
  `uid` int(11) unsigned NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `id` int(11) unsigned NOT NULL auto_increment,
  `method` tinyint(4) unsigned NOT NULL default '0',
  `ext_id` varchar(28) NOT NULL default '',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `inner_describe` varchar(80) NOT NULL default '',
  `action_type` tinyint(11) unsigned NOT NULL default '0',
  `expire` date NOT NULL default '0000-00-00',  
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `date` (`date`),
  KEY `uid` (`uid`)
) COMMENT "Bonus log"  ;

CREATE TABLE `bonus_service_discount` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `service_period` smallint(4) unsigned NOT NULL default '0',
  `registration_days` smallint(4) unsigned NOT NULL default '0',
  `discount` double(10,2) NOT NULL default '0.00',
  `discount_days` smallint(4) unsigned NOT NULL default '0',
  `total_payments_sum` double(10,2) NOT NULL default '0.00',
  `bonus_sum` double(10,2) NOT NULL default '0.00',
  `bonus_percent` double(10,2) NOT NULL default '0.00',
  `ext_account` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) COMMENT "Bonus service discount"  ;

CREATE TABLE `bonus_turbo` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `service_period` smallint(4) unsigned NOT NULL default '0',
  `registration_days` smallint(4) unsigned NOT NULL default '0',
  `turbo_count` smallint(4) unsigned NOT NULL default '0',
  `comments` text not null default '',
  PRIMARY KEY  (`id`)
) COMMENT "Bonus turbo"  ;

CREATE TABLE `bonus_tps` (
  `id` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `state` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT "Bonus tarif plans"  ; 

CREATE TABLE `bonus_accoumulation` (
  `tp_id` smallint(6) unsigned NOT NULL default 0,
  `dv_tp_id` smallint(6) unsigned NOT NULL default 0,
  `scores` smallint(6) unsigned NOT NULL default 0
) COMMENT "Bonus accoumulation"  ;


CREATE TABLE `bonus_rules` (
  `tp_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `period` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `rules` varchar(20) NOT NULL,
  `actions` varchar(20) NOT NULL,
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `rule_value` int(11) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tp_id` (`tp_id`,`period`,`rules`,`rule_value`)
) COMMENT "Bonus rules"  ; 

CREATE TABLE `bonus_main` (
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `tp_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `accept_rules` tinyint(1) unsigned NOT NULL default '0',
  `state` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`uid`),
  UNIQUE KEY `uid` (`uid`)
)  COMMENT='Bonus users' ;


CREATE TABLE `bonus_rules_accomulation` (
  `tp_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `dv_tp_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `cost` double(15,6) NOT NULL default '0.000000',
  UNIQUE KEY `tp_id` (`tp_id`,`dv_tp_id`)
) COMMENT "Bonus accomulation rules"  ;


CREATE TABLE `bonus_rules_accomulation_scores` (
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `dv_tp_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `cost` double(15,6) NOT NULL default '0.000000',
  `changed` date not null default '0000-00-00',
  PRIMARY KEY `uid` (`uid`)
) COMMENT "Bonus accomulation scores"  ;
