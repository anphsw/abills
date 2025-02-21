CREATE TABLE IF NOT EXISTS `msgs_teams` (
  `id`          INT(11)      UNSIGNED NOT NULL AUTO_INCREMENT,
  `responsible` SMALLINT(6)  UNSIGNED NOT NULL DEFAULT 0,
  `name`        VARCHAR(40)  NOT NULL DEFAULT '',
  `descr`       VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Msgs teams';

CREATE TABLE IF NOT EXISTS `msgs_team_messages` (
  `id`          INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `team_id`     INT(11) UNSIGNED NOT NULL DEFAULT 0,
  `message_id`  INT(11) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `msgs_id_team` (`team_id`),
  KEY `message_id` (`message_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Team messages';

CREATE TABLE IF NOT EXISTS `msgs_team_members` (
  `id`          INT(11)     UNSIGNED NOT NULL AUTO_INCREMENT,
  `team_id`     INT(11)     UNSIGNED NOT NULL DEFAULT 0,
  `aid`         SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Team members';

ALTER TABLE `msgs_team_address` ADD COLUMN `team_id` INT(11) UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `triplay_main` ADD COLUMN `personal_tp` double(14, 2) unsigned NOT NULL DEFAULT '0.00';
