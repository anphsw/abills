ALTER TABLE `accident_equipments` ADD COLUMN `port_id` VARCHAR(32) NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS `accident_types` (
  `id`           TINYINT(3) UNSIGNED  NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(50)          NOT NULL DEFAULT '',
  `priority`     TINYINT(2) UNSIGNED  NOT NULL DEFAULT 0,
  `color`        VARCHAR(7)           NOT NULL DEFAULT '',
  `comments`     VARCHAR(120)         NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Accident types';

ALTER TABLE `accident_log` ADD COLUMN `type` TINYINT(3) UNSIGNED NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `accident_admins` (
  `accident_type`  TINYINT(3)  UNSIGNED NOT NULL DEFAULT 0,
  `aid`            SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  UNIQUE KEY `accident_type` (accident_type,aid)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Accident admins';

ALTER TABLE `accident_equipments` ADD COLUMN `type` TINYINT(3) UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `ureports_tp_reports` ADD COLUMN `default_value` VARCHAR(10) NOT NULL DEFAULT '';
