ALTER TABLE `building_statuses` ADD UNIQUE KEY (`name`);
ALTER TABLE `iptv_extra_params` ADD COLUMN `email_domain` VARCHAR(120) NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS `mobile_log` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `uid` INT(11) NOT NULL DEFAULT 0,
  `transaction_id` VARCHAR(64) NOT NULL DEFAULT '',
  `external_method` VARCHAR(64) NOT NULL DEFAULT '',
  `user_subscribe_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `response` TEXT NOT NULL,
  `callback_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `callback` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  COMMENT = 'Mobile log';