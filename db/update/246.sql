CREATE TABLE IF NOT EXISTS `users_pi_docs` (
  `id`          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `uid`         INT UNSIGNED     NOT NULL DEFAULT 0,
  `doc_type`    TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `num`         VARCHAR(32)      NOT NULL DEFAULT '',
  `date`        DATE             NOT NULL DEFAULT '0000-00-00',
  `expire`      DATE             NOT NULL DEFAULT '0000-00-00',
  `issued_by`   VARCHAR(100)     NOT NULL DEFAULT '',
  `filename`    VARCHAR(255)     NOT NULL DEFAULT '',
  `created_at`  DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Users personal documents';

ALTER TABLE `trafic_tarifs` MODIFY COLUMN `descr` VARCHAR(80) DEFAULT '' NOT NULL;

ALTER TABLE `users_pi_docs` ADD UNIQUE KEY `doc_type_num` (`doc_type`, `num`);