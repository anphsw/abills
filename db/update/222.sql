ALTER TABLE `paysys_main` ADD COLUMN `info` VARCHAR(100) NOT NULL DEFAULT '';
ALTER TABLE `storage_sn` ADD COLUMN `ident1` VARCHAR(250) NOT NULL DEFAULT '';
ALTER TABLE `storage_sn` ADD COLUMN `ident2` VARCHAR(250) NOT NULL DEFAULT '';
ALTER TABLE `storage_sn` ADD COLUMN `ident3` VARCHAR(250) NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS `password_blacklist` (
  `id`         SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `aid`        SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `password`   BLOB                 NOT NULL,
  `changed_at` DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE `aid_password` (`aid`, `password`(100))
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Password blacklist';

CREATE TABLE IF NOT EXISTS `discounts_main` (
  `id`        SMALLINT      UNSIGNED  NOT NULL  AUTO_INCREMENT,
  `uid`       INT(11)       UNSIGNED  NOT NULL  DEFAULT 0,
  `percent`   SMALLINT                NOT NULL  DEFAULT 0,
  `sum`       DOUBLE(10, 2) UNSIGNED  NOT NULL  DEFAULT '0.00',
  `from_date` DATE                    NOT NULL,
  `to_date`   DATE                    NOT NULL,
  `module`    VARCHAR(20)             NOT NULL DEFAULT '',
  `status`    TINYINT(1)    UNSIGNED  NOT NULL  DEFAULT 0,
  `type`      TINYINT(1)    UNSIGNED  NOT NULL  DEFAULT 0,
  `aid`       SMALLINT(3)   UNSIGNED  NOT NULL  DEFAULT 0 COMMENT 'Admin who created',
  `comments`  TEXT,
  PRIMARY KEY (`id`)
) COMMENT = 'Discounts users';
