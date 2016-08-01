CREATE TABLE IF NOT EXISTS `equipment_vendors` (
  `id` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL DEFAULT '',
  `support` varchar(50) NOT NULL DEFAULT '',
  `site` varchar(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Netlist equipment vendor';

REPLACE INTO `equipment_vendors` (`id`, `name`, `support`, `site`) VALUES
(1, 'Cisco', '', 'http://cisco.com'),
(2, 'D-link', '', 'http://www.dlink.ru/'),
(3, 'Zyxel', '', 'http://zyxel.ru'),
(4, 'Juniper', '', 'http://juniper.com'),
(5, 'Edge-Core', '', 'http://www.edge-core.ru'),
(6, 'Mikrotik', '', 'http://www.mikrotik.com'),
(7, 'Ericsson', '', 'http://www.ericsson.com/ua'),
(8, '3com', '', 'http://3com.com'),
(9, 'TP-Link', '', 'http://www.tplink.com'),
(10, 'Dell', '', 'http://www.dell.com'),
(11, 'BDCOM', '', 'http://www.bdcom.com'),
(12, 'ZTE',   '', 'http://zte.ru/'),
(13, 'ELTEX', '', 'http://www.eltex.ru/'),
(14, 'GWdelight', '', 'http://www.gwdelight.com'),
(15, 'Ruckus', '', 'http://www.ruckuswireless.com/'),
(16, 'Ubiquiti', '', 'https://www.ubnt.com/'),
(17, 'Nortel', '', 'http://www.nortel.com/'),
(18, 'H3C', '', 'http://www.h3c.com'),
(19, 'Foundry Networks', '', 'http://www.brocade.com/en.html'),
(20, 'Alcatel', '', 'https://www.alcatel-lucent.com/'),
(21, 'Hewlett-Packard', '', 'http://www8.hp.com/ru/ru/home.html')
;



CREATE TABLE `equipment_types` (
  id tinyint(6) unsigned NOT NULL auto_increment,
  name varchar(50) NOT NULL default '',
  PRIMARY KEY  (id)
) COMMENT = 'Netlist equipment type';

INSERT INTO `equipment_types` VALUES (1,'Switch'),
(2,'WiFi'),
(3,'Router'),
(4,'PON'),
(5,'Server'),
(6,'DOCSIS'),
(7,'Set-top box');

CREATE TABLE `equipment_models` (
  `id` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `type_id` tinyint(6) unsigned NOT NULL DEFAULT '0',
  `vendor_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `model_name` varchar(50) NOT NULL DEFAULT '',
  `site` varchar(150) NOT NULL DEFAULT '',
  `ports` tinyint(6) unsigned NOT NULL DEFAULT '0',
  `manage_web` varchar(50) NOT NULL DEFAULT '',
  `manage_ssh` varchar(50) NOT NULL DEFAULT '',
  `snmp_tpl` varchar(50) NOT NULL DEFAULT '',
  `comments` text NOT NULL,
  `rows_count` int(11) unsigned NOT NULL DEFAULT '1',
  `block_size` int(11) unsigned DEFAULT '0',
  `port_numbering` tinyint(1) unsigned DEFAULT '0' COMMENT 'FALSE is ROWS, TRUE is COLUMNS',
  `first_position` tinyint(1) unsigned DEFAULT '0' COMMENT 'FALSE is UP, TRUE is DOWN',
  `extra_port1` smallint(6) unsigned DEFAULT '0',
  `extra_port2` smallint(6) unsigned DEFAULT '0',
  `extra_port3` smallint(6) unsigned DEFAULT '0',
  `extra_port4` smallint(6) unsigned DEFAULT '0',
  `ports_type` smallint(5) unsigned DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=164 DEFAULT CHARSET=utf8 COMMENT='Equipment models';


CREATE TABLE `equipment_infos` (
  nas_id smallint(6) unsigned NOT NULL default 0,
  model_id smallint(6) unsigned NOT NULL default 0,
  system_id varchar(30) NOT NULL default '',
  ports smallint(6) unsigned NOT NULL default 0,
  firmware varchar(20) NOT NULL default '',
  firmware2 varchar(20) NOT NULL default '',
  status tinyint(1) unsigned not null default 0,
  start_up_date date,
  comments text,
  serial varchar(100) not null default '',
  revision VARCHAR(10) NOT NULL DEFAULT '',
  UNIQUE(nas_id)
) COMMENT = 'Equipment info' ;

CREATE TABLE `equipment_ports` (
  id int unsigned NOT NULL auto_increment,
  nas_id smallint(6) unsigned NOT NULL default 0,
  port smallint(6) unsigned NOT NULL default 0,
  status tinyint(1) unsigned NOT NULL default 0,
  uplink smallint(6) unsigned NOT NULL default 0,
  comments varchar(250) not null default '',
  PRIMARY KEY (id),
  KEY `nas_port` (`nas_id`, `port`)
) COMMENT = 'Equipment ports';

CREATE TABLE `pon_onus` (
  `uid` int(11) unsigned NOT NULL default 0,
  `mac` varchar(16) not null default '',
  `datetime` datetime not null default '0000-00-00 00:00:00',
  `status` tinyint(1) not null default 0
) COMMENT = 'PON onu list';


CREATE TABLE `equipment_box_types` (
  `id` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `marking` varchar(30) NOT NULL DEFAULT '',
  `vendor` varchar(40) NOT NULL DEFAULT '',
  `units` smallint(6) NOT NULL DEFAULT '0',
  `width` smallint(6) NOT NULL DEFAULT '0',
  `hieght` smallint(6) NOT NULL DEFAULT '0',
  `length` smallint(6) NOT NULL DEFAULT '0',
  `diameter` smallint(6) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) COMMENT='Equipment box types';


CREATE TABLE `equipment_boxes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `serial` varchar(30) NOT NULL DEFAULT '',
  `datetime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`)
) COMMENT='Equipment boxes';

CREATE TABLE `equipment_vlans` (
  `id` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `number` smallint(6) unsigned NOT NULL DEFAULT 0,
  `name` varchar(30) NOT NULL DEFAULT '',
  `comments` text NULL,
  unique (id)
) COMMENT = 'Equipment vlans';

CREATE TABLE `equipment_extra_ports` (
  `model_id` SMALLINT UNSIGNED NOT NULL,
  `port_number` SMALLINT UNSIGNED NOT NULL,
  `port_type` SMALLINT UNSIGNED NOT NULL DEFAULT '0',
  `state` TINYINT UNSIGNED NOT NULL DEFAULT '0',
  `row` SMALLINT UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY `model_port` (`model_id`, `port_number`)
) COMMENT = 'Table for extra ports for equipment models';


CREATE TABLE `equipment_traps` (
  id int unsigned NOT NULL auto_increment,
  traptime datetime NOT NULL default '0000-00-00 00:00:00',
  ip int(11) unsigned NOT NULL default '0',
  port smallint(6) unsigned NOT NULL default 0,
  eventname varchar(50) NOT NULL default '',
  trapoid varchar(100) NOT NULL default '',
  severity varchar(20) NOT NULL default '',
  varbinds TEXT,
  PRIMARY KEY (id)
) COMMENT = 'Equipment traps';

CREATE TABLE equipment_backup (

  id INT(11) unsigned PRIMARY KEY,
  name VARCHAR(50) NOT NULL DEFAULT '',
  nas_id SMALLINT(11) UNSIGNED REFERENCES equipment_infos(`nas_id`),
  md5 VARCHAR(32) NOT NULL DEFAULT '',
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(`name`)
) COMMENT = 'Equipment backup description';


CREATE TABLE equipment_graphs (
  `id` int unsigned NOT NULL auto_increment PRIMARY KEY,
  `nas_id` SMALLINT(11) UNSIGNED REFERENCES equipment_infos(`nas_id`),
  `port` VARCHAR(10) NOT NULL DEFAULT '',
  `param` VARCHAR(32) NOT NULL DEFAULT '',
  `comments` VARCHAR(80) NOT NULL DEFAULT '',
  `min_value` VARCHAR(10) NOT NULL DEFAULT '',
  `max_value` VARCHAR(10) NOT NULL DEFAULT '',
  `date` date NOT NULL default '0000-00-00', 
  key(`nas_id`)
) COMMENT = 'Equipment graph stats';


CREATE TABLE equipment_graph_log (
  `id` int unsigned NOT NULL DEFAULT 0 PRIMARY KEY,
  `value` VARCHAR(10) NOT NULL DEFAULT '',
  `datetime` datetime NOT NULL default '0000-00-00'
) COMMENT = 'Equipment graph stats log';

CREATE TABLE equipment_mac_log (
  `mac` VARCHAR(17) NOT NULL DEFAULT '',
  `ip` int unsigned NOT NULL DEFAULT 0,
  `port` VARCHAR(10) NOT NULL DEFAULT '', 
  `vlan` smallint(6) unsigned NOT NULL DEFAULT 0,
  `nas_id` smallint(6) unsigned NOT NULL DEFAULT 0,
  `datetime` datetime NOT NULL default '0000-00-00',
  KEY `mac` (`mac`),
  KEY `nas_id` (`nas_id`)
) COMMENT = 'Equipment MAC log';
