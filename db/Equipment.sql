CREATE TABLE IF NOT EXISTS `equipment_vendors` (
  `id` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL DEFAULT '',
  `support` varchar(50) NOT NULL DEFAULT '',
  `site` varchar(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Netlist equipment vendor';

INSERT INTO `equipment_vendors` (`id`, `name`, `support`, `site`) VALUES
(1, 'Cisco', '', 'http://cisco.com'),
(2, 'Dlink', '', 'http://www.dlink.ru/'),
(3, 'Zyxel', '', 'http://zyxel.ru'),
(4, 'Juniper', '', 'http://juniper.com'),
(5, 'Edge-Core', '', 'http://www.edge-core.ru'),
(6, 'Mikrotik', '', 'http://www.mikrotik.com'),
(7, 'Ericsson', '', 'http://www.ericsson.com/ua'),
(8, '3com', '', 'http://3com.com'),
(9, 'TP-Link', '', 'http://www.tplink.com'),
(10, 'Dell', '', 'http://www.dell.com');



CREATE TABLE `equipment_types` (
  id tinyint(6) unsigned NOT NULL auto_increment,
  name varchar(50) NOT NULL default '',
  PRIMARY KEY  (id)
) COMMENT = 'Netlist equipment type';

CREATE TABLE `equipment_models` (
  id smallint(6) unsigned NOT NULL auto_increment,
  type_id tinyint(6) unsigned NOT NULL default 0,
  vendor_id smallint(6) unsigned NOT NULL default 0,
  model_name varchar(50) NOT NULL default '',
  site varchar(150) NOT NULL default '',
  ports tinyint(6) unsigned NOT NULL default 0,
  manage_web varchar(50) NOT NULL default '',
  manage_ssh varchar(50) NOT NULL default '',
  comments text not null,
  PRIMARY KEY (id)
) COMMENT = 'Equipment models';


CREATE TABLE `equipment_infos` (
  nas_id smallint(6) unsigned NOT NULL default 0,
  model_id smallint(6) unsigned NOT NULL default 0,
  system_id varchar(30) NOT NULL default '',
  ports tinyint(6) unsigned NOT NULL default 0,
  firmware varchar(20) NOT NULL default '',
  firmware2 varchar(20) NOT NULL default '',
  status tinyint(1) unsigned not null default 0,
  start_up_date date,
  comments text,
  serial varchar(100) not null default '',
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



