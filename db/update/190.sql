ALTER TABLE `paysys_log` ADD COLUMN `merchant_id` TINYINT UNSIGNED NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `abon_gids` (
  `id`              SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `tp_id`           SMALLINT(6) UNSIGNED NOT NULL,
  `gid`             SMALLINT(4) UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tp_id_gid` (`tp_id`, `gid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Abon tariffs to user groups';

ALTER TABLE `tags_users` ADD COLUMN `end_date` DATE NOT NULL  DEFAULT '0000-00-00' COMMENT 'Tag expiration date';