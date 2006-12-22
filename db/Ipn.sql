CREATE TABLE `ipn_club_comps` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(20) NOT NULL default '0',
  `ip` int(11) unsigned NOT NULL default '0',
  `cid` varchar(17) NOT NULL default '',
  `number` smallint(6) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `ip` (`ip`),
  UNIQUE KEY `number` (`number`)
);

CREATE TABLE `ipn_log` (
  `uid` int(11) unsigned NOT NULL default '0',
  `start` datetime NOT NULL default '0000-00-00 00:00:00',
  `stop` datetime NOT NULL default '0000-00-00 00:00:00',
  `traffic_class` smallint(6) unsigned NOT NULL default '0',
  `traffic_in` int(11) unsigned NOT NULL default '0',
  `traffic_out` int(11) unsigned NOT NULL default '0',
  `nas_id` smallint(6) unsigned NOT NULL default '0',
  `ip` int(11) unsigned NOT NULL default '0',
  `interval_id` int(11) unsigned NOT NULL default '0',
  `sum` double(15,6) unsigned NOT NULL default '0.000000',
  `session_id` char(25) NOT NULL default ''
);

