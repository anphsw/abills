CREATE TABLE IF NOT EXISTS `crm_attachments` (
  `id`           INT(10)     UNSIGNED  NOT NULL AUTO_INCREMENT,
  `filename`     VARCHAR(255)          NOT NULL DEFAULT '',
  `file_size`    INT(10)      UNSIGNED NOT NULL DEFAULT 0,
  `content_type` VARCHAR(50)           NOT NULL DEFAULT '',
  `uploaded_at`  TIMESTAMP             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `message_id`   INT          UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Crm attachments table';