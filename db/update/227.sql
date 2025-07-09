CREATE TABLE IF NOT EXISTS `sender_log` (
  `id`          INT(11) UNSIGNED     NOT NULL AUTO_INCREMENT,
  `sender_type` TINYINT(2) UNSIGNED  NOT NULL DEFAULT 0,
  `destination` VARCHAR(60)          NOT NULL DEFAULT '',
  `source`      VARCHAR(60)          NOT NULL DEFAULT '',
  `message`     TEXT,
  `subject`     TEXT,
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