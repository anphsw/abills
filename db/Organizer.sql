CREATE TABLE organizer_user_info(
  `id`    int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uid`   int(11) unsigned NOT NULL default '0',
  `date`  date NOT NULL default '0000-00-00',
  `light` int unsigned NOT NULL default 0,
  `gas`   int unsigned NOT NULL default 0,
  `water` int unsigned NOT NULL default 0,
  `communal` double(6,2) unsigned NOT NULL default '0.00',
  `comments` text NOT NULL,
  PRIMARY KEY  (`uid`, `date`),
  KEY `id` (`id`)
)COMMENT='Users data';