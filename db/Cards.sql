CREATE TABLE `cards_bruteforce` (
  `uid` int(11) unsigned NOT NULL default '0',
  `pin` varchar(20) NOT NULL default '',
  `datetime` datetime NOT NULL default '0000-00-00 00:00:00'
);

CREATE TABLE `cards_dillers` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(45) NOT NULL default '',
  `address` varchar(100) NOT NULL default '',
  `phone` bigint(20) unsigned NOT NULL default '0',
  `email` varchar(35) NOT NULL default '0',
  `comments` text NOT NULL,
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `registration` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
);

CREATE TABLE `cards_payments` (
  `serial` varchar(10) NOT NULL default '',
  `number` int(11) unsigned zerofill NOT NULL default '00000000000',
  `pin` varchar(20) NOT NULL default '',
  `sum` double(15,3) unsigned NOT NULL default '0.000',
  `status` tinyint(2) unsigned NOT NULL default '0',
  `datetime` datetime NOT NULL default '0000-00-00 00:00:00',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `expire` date NOT NULL default '0000-00-00',
  `diller_id` smallint(6) unsigned NOT NULL default '0',
  UNIQUE KEY `pin` (`pin`),
  UNIQUE KEY `serial` (`serial`,`number`)
);


CREATE TABLE `cards_users` (
  `serial` int(11) unsigned zerofill NOT NULL auto_increment,
  `login` varchar(20) NOT NULL default '',
  `password` varchar(16) NOT NULL default '',
  `status` tinyint(2) unsigned NOT NULL default '0',
  `datetime` datetime NOT NULL default '0000-00-00 00:00:00',
  `aid` int(11) unsigned NOT NULL default '0',
  `gid` smallint(6) unsigned NOT NULL default '0',
  `expire` date NOT NULL default '0000-00-00',
  `diller_id` smallint(6) unsigned NOT NULL default '0',
  PRIMARY KEY  (`serial`),
  UNIQUE KEY `serial` (`serial`),
  UNIQUE KEY `login` (`login`)
);
