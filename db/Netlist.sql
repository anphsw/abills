CREATE TABLE `netlist_groups` (
  `id` smallint(6) unsigned NOT NULL auto_increment,
  `name` char(20) NOT NULL default '',
  `comments` char(250) NOT NULL default '',
  `parent_id` smallint(6) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Netlist groups';


CREATE TABLE `netlist_ips` (
  `ip_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `ip` int(11) unsigned NULL DEFAULT 0,
  `ipv6` varbinary(16) NULL DEFAULT 0,
  `mac` varchar(17) NOT NULL DEFAULT '0',
  `mac_auto_detect` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `gid` smallint(6) unsigned NOT NULL DEFAULT '0',
  `netmask` int(11) unsigned NOT NULL DEFAULT '0',
  `ipv6_prefix` int(3) NULL,
  `hostname` varchar(50) NOT NULL DEFAULT '',
  `status` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `comments` text NOT NULL,
  `date` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `aid` smallint(6) unsigned NOT NULL DEFAULT '0',
  `descr` varchar(200) NOT NULL DEFAULT '',
  `machine_type` smallint(6) unsigned NOT NULL DEFAULT '0',
  `location` varchar(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`ip_id`),
  UNIQUE `_key_ip_ipv6` (`ip`, `ipv6`),
  CHECK (ip <> 0 OR ipv6 <> 0),
  CHECK (netmask <> 0 OR ipv6_prefix <> 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Netlist ips';