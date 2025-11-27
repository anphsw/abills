CREATE TABLE IF NOT EXISTS `territorial_units` (
  `id`        INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `code`      VARCHAR(20)      NOT NULL DEFAULT '',
  `name`      VARCHAR(200)     NOT NULL DEFAULT '',
  `type_code` CHAR(1)          NOT NULL DEFAULT '',
  `level`     TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `parent_id` INT UNSIGNED     NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  KEY `parent_id` (`parent_id`),
  KEY `type_level` (`type_code`, `level`),
  KEY `name` (`name`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Administrative territorial units (KATOTTG)';

ALTER TABLE `districts` ADD COLUMN `territorial_units_id` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `districts` ADD KEY `territorial_units_id` (`territorial_units_id`);

CREATE TABLE IF NOT EXISTS `fees_subconto_codes` (
  `code`    VARCHAR(20)      NOT NULL DEFAULT '',
  `name`    VARCHAR(80)      NOT NULL DEFAULT '',
  UNIQUE KEY `code` (`code`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Code Subconto types for fees';

CREATE TABLE `abon_tariffs_subtariffs` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tp_id`     SMALLINT(6) UNSIGNED NOT NULL,
  `sub_tp_id`  SMALLINT(6) UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tariff_subtariff` (`tp_id`, `sub_tp_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Abon Subtariffs';