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
  `build_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `address_flat` VARCHAR(10) NOT NULL DEFAULT '',
  `competitor_id` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  `tp_id` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  `assessment` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT,
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY uid (`uid`),
  KEY competitor_id (`competitor_id`)
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

CREATE TABLE IF NOT EXISTS `crm_competitors` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(64) NOT NULL DEFAULT '',
  `connection_type` VARCHAR(32) NOT NULL DEFAULT '',
  `site` VARCHAR(150) NOT NULL DEFAULT '',
  `color` VARCHAR(7) NOT NULL DEFAULT '',
  `descr` TEXT NOT NULL,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Crm Competitors';

CREATE TABLE IF NOT EXISTS `crm_competitors_tps` (
  `id`            INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`          VARCHAR(64) NOT NULL DEFAULT '',
  `speed`         INT(10) UNSIGNED NOT NULL DEFAULT '0',
  `month_fee`     DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `day_fee`       DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `competitor_id` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `competitor_id` (`competitor_id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Crm Competitors tps';

CREATE TABLE IF NOT EXISTS `crm_competitor_geolocation` (
  `competitor_id` SMALLINT(5) UNSIGNED DEFAULT '0' NOT NULL,
  `district_id`   SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL,
  `street_id`     SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL,
  `build_id`      SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL
)
  DEFAULT CHARSET=utf8 COMMENT = 'Geolocation of competitor';

CREATE TABLE IF NOT EXISTS `crm_competitor_tps_geolocation` (
  `tp_id`       SMALLINT(5) UNSIGNED DEFAULT '0' NOT NULL,
  `district_id` SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL,
  `street_id`   SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL,
  `build_id`    SMALLINT(6) UNSIGNED DEFAULT '0' NOT NULL
)
  DEFAULT CHARSET=utf8 COMMENT = 'Geolocation of competitor tps';

CREATE TABLE IF NOT EXISTS `crm_admin_actions` (
  `actions`     VARCHAR(100)         NOT NULL DEFAULT '',
  `datetime`    DATETIME             NOT NULL,
  `ip`          INT(11) UNSIGNED     NOT NULL DEFAULT '0',
  `lid`         INT(11) UNSIGNED     NOT NULL DEFAULT '0',
  `aid`         SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `id`          INT(11) UNSIGNED     NOT NULL AUTO_INCREMENT,
  `action_type` TINYINT(2)           NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `lid` (`lid`),
  KEY `aid` (`aid`),
  KEY `action_type` (`action_type`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Crm leads changes log';

CREATE TABLE IF NOT EXISTS `crm_info_fields` (
  `id`          TINYINT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(60)          NOT NULL DEFAULT '',
  `sql_field`   VARCHAR(60)          NOT NULL DEFAULT '',
  `type`        TINYINT(2) UNSIGNED  NOT NULL DEFAULT 0,
  `priority`    TINYINT(1) UNSIGNED  NOT NULL DEFAULT 0,
  `comment`     VARCHAR(60)          NOT NULL DEFAULT '',
  `pattern`     VARCHAR(60)          NOT NULL DEFAULT '',
  `title`       VARCHAR(255)         NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY (`name`),
  UNIQUE KEY (`sql_field`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm Info fields';

CREATE TABLE IF NOT EXISTS `crm_tp_info_fields` (
  `id`          TINYINT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(60)          NOT NULL DEFAULT '',
  `sql_field`   VARCHAR(60)          NOT NULL DEFAULT '',
  `type`        TINYINT(2) UNSIGNED  NOT NULL DEFAULT 0,
  `priority`    TINYINT(1) UNSIGNED  NOT NULL DEFAULT 0,
  `comment`     VARCHAR(60)          NOT NULL DEFAULT '',
  `pattern`     VARCHAR(60)          NOT NULL DEFAULT '',
  `title`       VARCHAR(255)         NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY (`name`),
  UNIQUE KEY (`sql_field`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm Tariff plans info fields';
