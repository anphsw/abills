CREATE TABLE `reports_wizard` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL DEFAULT '',
  `gid` smallint NOT NULL DEFAULT 0,
  `comments` text NOT NULL,
  `query` text NOT NULL,
  `fields` text NOT NULL,
  `date` date NOT NULL DEFAULT '0000-00-00',
  `aid` smallint(11) unsigned NOT NULL DEFAULT '0',
  `query_total` text NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Reports Wizard';

CREATE TABLE `reports_groups` (
  `id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(40) NOT NULL DEFAULT '',
  `comments` text NOT NULL,
  PRIMARY KEY (`id`)
) COMMENT='Reports Groups';