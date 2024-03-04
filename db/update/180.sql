ALTER TABLE `equipment_models` MODIFY COLUMN `port_shift` INT(11) NOT NULL DEFAULT '0';
ALTER TABLE `portal_articles` MODIFY COLUMN `gid` VARCHAR(64) NOT NULL DEFAULT '*';

CREATE TABLE IF NOT EXISTS `voip_subscribes`(
  `id`                   SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  `callback_url`         VARCHAR(256)         NOT NULL DEFAULT '',
  `period`               SMALLINT(5) UNSIGNED NOT NULL DEFAULT 1,
  `sliding_window_count` SMALLINT(5) UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `callback_url` (`callback_url`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Voip VPBX subscribes';
