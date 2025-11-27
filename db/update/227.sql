CREATE TABLE IF NOT EXISTS `sender_log` (
  `id`          INT(11) UNSIGNED     NOT NULL AUTO_INCREMENT,
  `sender_type` TINYINT(2) UNSIGNED  NOT NULL DEFAULT 0,
  `destination` VARCHAR(60)          NOT NULL DEFAULT '',
  `source`      VARCHAR(60)          NOT NULL DEFAULT '',
  `message`     TEXT,
  `subject`     VARCHAR(150)         NOT NULL  DEFAULT '',
  `created`     DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `result`      SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `uid`         INT(11) UNSIGNED     NOT NULL DEFAULT 0,
  `aid`         SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `aid` (`aid`),
  KEY `uid` (`uid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Sender log';
ALTER TABLE `fees_types` ADD COLUMN `subconto` VARCHAR(20) NOT NULL DEFAULT '';
ALTER TABLE `cablecat_crosses` ADD COLUMN `allow_parallel_ports` TINYINT(1)  UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `tarif_plans` ADD COLUMN `age_alignment` TINYINT(2) UNSIGNED    NOT NULL DEFAULT '0';

CREATE TABLE IF NOT EXISTS `employees_spending_types_admins`
(
  `type_id`     SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `aid`         SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `add_date`    DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY type_id (aid,type_id)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Admins permissions of spending types';