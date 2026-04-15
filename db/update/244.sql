CREATE TABLE IF NOT EXISTS `msgs_ai_assist_feedback` (
  `id`        INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  `msg_id`    INT UNSIGNED    NOT NULL,
  `question`  TEXT            NOT NULL,
  `answer`    TEXT            NOT NULL,
  `status`    TINYINT(1)      NOT NULL COMMENT '1 = useful, 0 = not_useful',
  `aid`       SMALLINT(6)     UNSIGNED NOT NULL DEFAULT 0,
  `created`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `status`  (`status`),
  KEY `msg_id`  (`msg_id`),
  KEY `aid`     (`aid`),
  KEY `created` (`created`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Msgs AI assist feedback';