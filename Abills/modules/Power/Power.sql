SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `power_gensets` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `type_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `build_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `fueltank_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `state` TINYINT(4) NOT NULL DEFAULT 0,
  `litres` DOUBLE(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
  KEY `type_id` (`type_id`),
  KEY `fueltank_id` (`fueltank_id`),
  KEY `build_id` (`build_id`),
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Power gensets';

CREATE TABLE IF NOT EXISTS `power_fueltanks` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(80) NOT NULL DEFAULT '',
  `litres` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `description` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Power fuel tanks';

INSERT INTO `power_fueltanks` (`name`, `litres`) VALUES
('100 L', 100),
('150 L', 150),
('180 L', 180),
('200 L', 200),
('250 L', 250),
('300 L', 300),
('350 L', 350);

CREATE TABLE IF NOT EXISTS `power_genset_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL DEFAULT '',
  `description` TEXT NOT NULL DEFAULT '',
  `litres_per_hour` DOUBLE(10,2) NOT NULL DEFAULT 0.00,
  `phase` TINYINT(3) NOT NULL DEFAULT 1,
  `power_kva` DOUBLE(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `power_kw` DOUBLE(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Power genset types';

INSERT INTO `power_genset_types` (`name`, `description`, `litres_per_hour`, `phase`, `power_kva`, `power_kw`) VALUES
('OYK-35', 'Turkiye', 20.00, 3, 35.00, 27.50),
('VSD-20TAJR', 'China', 10.00, 1, 20.00, 16.00),
('P110-3', 'United Kingdom', 20.00, 3, 110.00, 88.00),
('VYX-125TAJR', 'China', 10.00, 3, 125.00, 100.00),
('VYX-187,5TAJR', 'China', 20.00, 3, 187.50, 150.00),
('DE-170RS ZN', '', 35.00, 3, 170.00, 136.00),
('OYK-66', 'Turkiye', 20.00, 3, 66.00, 60.00);

CREATE TABLE IF NOT EXISTS `power_service_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL DEFAULT '',
  `description` TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Power service types';

INSERT INTO `power_service_types` (`name`) VALUES
('$lang{POWER_OIL_REPLACEMENT}'),
('$lang{POWER_FUEL_FILTER_REPLACEMENT}'),
('$lang{POWER_OIL_FILTER_REPLACEMENT}'),
('$lang{POWER_AIR_FILTER_BLOWOUT}'),
('$lang{POWER_FUEL_PUMP_REPAIR}'),
('$lang{POWER_RADIATOR_REPAIR}'),
('$lang{POWER_FUEL_PUMP_REGULATOR_REPAIR}');

CREATE TABLE IF NOT EXISTS `power_genset_runs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `genset_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `start_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `stop_date` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  `type_id` TINYINT(3) UNSIGNED NOT NULL DEFAULT 0,
  `result` TINYINT(3) UNSIGNED NOT NULL DEFAULT 0,
  KEY `genset_id` (`genset_id`),
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Power genset runs';

CREATE TABLE IF NOT EXISTS `power_genset_services` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `genset_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `service_date` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  `service_type_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `description` TEXT NOT NULL DEFAULT '',
  KEY `genset_id` (`genset_id`),
  UNIQUE KEY `genset_id_service_date_service_type_id` (`service_date`, `service_type_id`, `genset_id`),
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Power genset services';

CREATE TABLE IF NOT EXISTS `power_genset_refuels` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `genset_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `litres` DOUBLE(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `litres_before` DOUBLE(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `litres_after` DOUBLE(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
  KEY `genset_id` (`genset_id`),
  UNIQUE KEY `genset_id_date` (`date`, `genset_id`),
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Power genset refuels';