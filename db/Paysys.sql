CREATE TABLE `paysys_log` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `system_id` tinyint(4) unsigned NOT NULL default '0',
  `datetime` datetime NOT NULL default '0000-00-00 00:00:00',
  `sum` double(10,2) unsigned NOT NULL default '0.00',
  `commission` double(10,2) unsigned NOT NULL default '0.00',
  `uid` int(11) unsigned NOT NULL default '0',
  `transaction_id` varchar(24) NOT NULL DEFAULT '',
  `info` text NOT NULL,
  `ip` int(11) unsigned NOT NULL default '0',
  `code` blob NOT NULL,
  `paysys_ip` int(11) unsigned NOT NULL DEFAULT '0',
  `domain_id` smallint(6) unsigned not null default '0',
  `status` tinyint(2) unsigned not null default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `ps_transaction_id` (`domain_id`, `transaction_id`)
) COMMENT='Paysys log';

CREATE TABLE `paysys_main` (
  `uid`         int(11) unsigned NOT NULL default '0',
  `token`       tinytext,
  `sum`         double(10,2) NOT NULL default '0.00',
  `date`        date NOT NULL default '0000-00-00',
  `paysys_id`   smallint(5) unsigned NOT NULL default '0',
  `external_last_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `attempts`    smallint(2) NOT NULL default 0,
  `closed`      smallint(1) NOT NULL DEFAULT 0,
  UNIQUE  (`uid`,`paysys_id`)
) COMMENT="Paysys user account";

CREATE TABLE `paysys_terminals`(
  `id`          int(11) unsigned NOT NULL auto_increment,
  `type`        smallint(2) unsigned NOT NULL DEFAULT 0,
  `status`      smallint(1) unsigned NOT NULL DEFAULT 0,
  `location_id` int(11) unsigned NOT NULL DEFAULT 0,
  `comment`     text ,
  UNIQUE KEY `id` (`id`)
)COMMENT="Table for paysys terminals";