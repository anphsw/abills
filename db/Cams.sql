SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `cams_tp` (
  `tp_id` SMALLINT(6) UNSIGNED DEFAULT '0',
  `streams_count` smallint(6) unsigned DEFAULT 0,
  `dvr` smallint(6) unsigned DEFAULT 0,
  `ptz` smallint(6) unsigned DEFAULT 0,
  `service_id` tinyint(1) unsigned NOT NULL DEFAULT 0,
  KEY `tp_id` (`tp_id`)
)
  DEFAULT CHARSET=utf8 COMMENT='Cams tariff plans';

CREATE TABLE IF NOT EXISTS `cams_main` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` int(11) unsigned DEFAULT 0,
  `tp_id` smallint(6) unsigned DEFAULT 0,
  `activate` datetime DEFAULT NULL,
  `status` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `subscribe_id` VARCHAR(32) NOT NULL DEFAULT '',
  `expire` DATE NOT NULL DEFAULT '0000-00-00',
  KEY `uid` (`uid`), 
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT='Users subscribed to cams';

CREATE TABLE IF NOT EXISTS `cams_streams` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` int(11) unsigned NOT NULL,
  `disabled` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `name` varchar(32) NOT NULL DEFAULT '',
  `title` varchar(32) NOT NULL DEFAULT '',
  `host` varchar(128) NOT NULL DEFAULT '0.0.0.0',
  `rtsp_path` text,
  `rtsp_port` smallint(6) unsigned NOT NULL DEFAULT '554',
  `login` varchar(32) NOT NULL DEFAULT '',
  `password` blob NOT NULL,
  `orientation` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `group_id` int(11) unsigned NOT NULL DEFAULT '0',
  `extra_url` varchar(64) NOT NULL DEFAULT '',
  `screenshot_url` varchar(64) NOT NULL DEFAULT '',
  `pre_image_url` varchar(128) NOT NULL DEFAULT '',
  `coordx` double(20,14) NOT NULL DEFAULT '0.00000000000000',
  `coordy` double(20,14) NOT NULL DEFAULT '0.00000000000000',
  `transport` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `limit_archive` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `pre_image` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `constantly_working` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `archive` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `only_video` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `point_id` int(11) unsigned DEFAULT NULL,
  `angel` int(11) unsigned NOT NULL DEFAULT '0',
  `length` int(11) unsigned NOT NULL DEFAULT '0',
  `location_angel` int(11) unsigned NOT NULL DEFAULT '0',
  `number_id` VARCHAR(32) NOT NULL DEFAULT '',
  `folder_id` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  DEFAULT CHARSET=utf8 COMMENT='Storing all streams';

CREATE TABLE IF NOT EXISTS `cams_services` (
  `id` tinyint(2) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL DEFAULT '',
  `module` varchar(24) NOT NULL DEFAULT '',
  `status` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `comment` varchar(250) DEFAULT '',
  `login` VARCHAR(72) NOT NULL DEFAULT '',
  `password` BLOB,
  `url` varchar(120) NOT NULL DEFAULT '',
  `user_portal` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `debug` tinyint(2) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  DEFAULT CHARSET=utf8 COMMENT='Cams Services';

CREATE TABLE IF NOT EXISTS `cams_groups` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL DEFAULT '',
  `location_id` int(11) unsigned NOT NULL DEFAULT '0',
  `district_id` int(11) unsigned NOT NULL DEFAULT '0',
  `street_id` int(11) unsigned NOT NULL DEFAULT '0',
  `build_id` int(11) unsigned NOT NULL DEFAULT '0',
  `comment` varchar(250) DEFAULT '',
  `max_users` smallint(6) unsigned DEFAULT 0,
  `max_cameras` smallint(6) unsigned DEFAULT 0,
  `service_id` int(6) unsigned NOT NULL DEFAULT 0,
  `subgroup_id` VARCHAR(32) NOT NULL DEFAULT '' COMMENT 'External group ID for syncronization',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  DEFAULT CHARSET=utf8 COMMENT='Cams Groups';

CREATE TABLE IF NOT EXISTS `cams_users_groups` (
  `id` INTEGER(10) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `group_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `changed` DATETIME NOT NULL,
  UNIQUE KEY `id` (`id`, `group_id`, `tp_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Cams users groups';

CREATE TABLE IF NOT EXISTS `cams_users_cameras` (
  `id` INTEGER(10) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `camera_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `changed` DATETIME NOT NULL,
  UNIQUE KEY `id` (`id`, `tp_id`, `camera_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Cams users cameras';

CREATE TABLE IF NOT EXISTS `cams_users_folders` (
  `id` INTEGER(10) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `folder_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `changed` DATETIME NOT NULL,
  UNIQUE KEY `id` (`id`, `folder_id`, `tp_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Cams users folders';

CREATE TABLE IF NOT EXISTS `cams_folder` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(64) NOT NULL DEFAULT '',
  `comment` varchar(250) DEFAULT '',
  `parent_id` int(6) unsigned NOT NULL DEFAULT 0,
  `group_id` int(6) unsigned NOT NULL DEFAULT 0,
  `service_id` int(6) unsigned NOT NULL DEFAULT 0,
  `location_id` int(11) unsigned NOT NULL DEFAULT '0',
  `district_id` int(11) unsigned NOT NULL DEFAULT '0',
  `street_id` int(11) unsigned NOT NULL DEFAULT '0',
  `build_id` int(11) unsigned NOT NULL DEFAULT '0',
  `subfolder_id` VARCHAR(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT='Cams Folder';