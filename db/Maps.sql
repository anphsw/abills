
CREATE TABLE IF NOT EXISTS `maps_routes` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(45) default NULL,
  `type` tinyint(3) unsigned default '0',
  `descr` text,
  `nas1` smallint(5) unsigned default '0',
  `nas2` smallint(5) unsigned default '0',
  `nas1_port` tinyint(3) unsigned default '0',
  `nas2_port` tinyint(3) unsigned default '0',
  `length` smallint(5) unsigned default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY (`name`)
) COMMENT='Routes information';

CREATE TABLE IF NOT EXISTS `maps_routes_coords` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `routes_id` int(10) unsigned default '0',
  `coordx` double(20,14) default '0.00000000000000',
  `coordy` double(20,14) default '0.00000000000000',
  PRIMARY KEY  (`id`)
) COMMENT='Routes coords';

CREATE TABLE IF NOT EXISTS `maps_wells` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(100) default NULL,
  `type_id` tinyint(1) unsigned default '0',
  `coordx` double(20,14) default '0.00000000000000',
  `coordy` double(20,14) default '0.00000000000000',
  `comment` text NOT NULL,
  PRIMARY KEY  (`id`)
) COMMENT='Wells coord';

CREATE TABLE IF NOT EXISTS `maps_wifi_zones` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `radius` int(10) unsigned default '0',
  `coordx` double(20,14) default '0.00000000000000',
  `coordy` double(20,14) default '0.00000000000000',
  PRIMARY KEY  (`id`)
)  COMMENT='Wifi zones';

CREATE TABLE maps_coords (
  `id`       INT(11) PRIMARY KEY AUTO_INCREMENT,
  `coordx`   DOUBLE NOT NULL,
  `coordy`   DOUBLE NOT NULL,
  `altitude` DOUBLE NOT NULL DEFAULT 0.0
)
  COMMENT 'Location data';

CREATE TABLE maps_point_types (
  `id`       SMALLINT(6) PRIMARY KEY AUTO_INCREMENT,
  `name`     VARCHAR(60) NOT NULL UNIQUE,
  `icon`     VARCHAR(30) NOT NULL    DEFAULT 'default',
  `comments` TEXT
)
  COMMENT 'Types of custom points';

INSERT INTO maps_point_types (`name`, `icon`) VALUES
  ('well', 'well'),
  ('wifi', 'wifi'),
  ('build', 'build'),
  ('route', 'route');

CREATE TABLE maps_points (
  `id`       INT(11) PRIMARY KEY AUTO_INCREMENT,
  `name`     VARCHAR(30) NOT NULL,
  `coord_id` INT(11) REFERENCES maps_coords (`id`)           ON DELETE CASCADE,
  `type_id`  SMALLINT(6) REFERENCES maps_point_types (`id`)  ON DELETE RESTRICT,
  `comments` TEXT
)
  COMMENT 'Custom points';
