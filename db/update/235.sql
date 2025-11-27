ALTER TABLE `crm_dialogues` ADD COLUMN `recipient` VARCHAR(60) NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS `crm_echat_numbers` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `type` VARCHAR(32) NOT NULL DEFAULT '',
  `number` VARCHAR(50) NOT NULL DEFAULT '',
  `token` VARCHAR(512) NOT NULL DEFAULT '',
  `status` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  `comments` TEXT,
  `created` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_number` (`number`, `type`),
  KEY `type` (`type`),
  KEY `status` (`status`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Messaging platform bot configuration';

CREATE TABLE IF NOT EXISTS `crm_echat_contacts` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `type` VARCHAR(32) NOT NULL DEFAULT '',
  `external_id` VARCHAR(255) NOT NULL,
  `lead_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `echat_number_id` INT(11) UNSIGNED NOT NULL,
  `first_contact` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_receiver` (`external_id`, `type`),
  KEY `lead_id` (`lead_id`),
  KEY `echat_number_id` (`echat_number_id`),
  KEY `type` (`type`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Platform user to lead mapping';