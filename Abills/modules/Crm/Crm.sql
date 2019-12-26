SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `crm_leads` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `fio` VARCHAR(120) NOT NULL DEFAULT '',
  `phone` VARCHAR(120) NOT NULL DEFAULT '',
  `company` VARCHAR(120) NOT NULL DEFAULT '',
  `email` VARCHAR(250) NOT NULL DEFAULT '',
  `country` VARCHAR(80) NOT NULL DEFAULT '',
  `city` VARCHAR(80) NOT NULL DEFAULT '',
  `address` VARCHAR(100) NOT NULL DEFAULT '',
  `source` int(1) NOT NULL DEFAULT 0,
  `responsible` SMALLINT(4) NOT NULL DEFAULT 0,
  `date` date NOT NULL DEFAULT '0000-00-00',
  `current_step` int NOT NULL DEFAULT 1,
  `priority` SMALLINT(1) NOT NULL DEFAULT 0,
  `uid` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `tag_ids` VARCHAR(20) NOT NULL DEFAULT '',
  `comments` TEXT,
  PRIMARY KEY (`id`),
  KEY uid (`uid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm leads';

CREATE TABLE IF NOT EXISTS `crm_progressbar_steps` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `step_number` INT UNSIGNED NOT NULL DEFAULT 1,
  `name` CHAR(40) NOT NULL DEFAULT '',
  `color` VARCHAR(7) NOT NULL DEFAULT '',
  `description` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm progressbar steps';

REPLACE INTO `crm_progressbar_steps` (`id`, `step_number`, `name`, `color`, `description`) VALUE
  ('1', '1', '$lang{NEW_LEAD}', '#5479e7', ''),
  ('2', '2', '$lang{CONTRACT_SIGNED}', '#25d2f1', ''),
  ('3', '3', '$lang{THE_WORKS}', '#ff8000', ''),
  ('4', '4', '$lang{CONVERSION}', '#f1233d', '');

CREATE TABLE IF NOT EXISTS `crm_leads_sources` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` CHAR(40) NOT NULL DEFAULT '',
  `comments` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm leads source';

REPLACE INTO `crm_leads_sources` (`id`, `name`, `comments`) VALUE
  ('1', '$lang{PHONE}', ''),
  ('2', 'E-mail', ''),
  ('3', '$lang{SOCIAL_NETWORKS}', ''),
  ('4', '$lang{REFERRALS}', '');

CREATE TABLE IF NOT EXISTS `crm_progressbar_step_comments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `step_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `lead_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `message` TEXT NOT NULL,
  `date` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `action_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `status` SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `planned_date` DATE NOT NULL DEFAULT '0000-00-00',
  PRIMARY KEY (`id`),
  UNIQUE (`lead_id`, `date`),
  KEY aid (`aid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Comments for each step in progressbar';

CREATE TABLE IF NOT EXISTS `crm_actions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` char(60) NOT NULL DEFAULT '',
  `action` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Entity ACTION';