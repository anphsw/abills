ALTER TABLE `abon_tariffs` ADD COLUMN `hot_deal` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0';

CREATE TABLE IF NOT EXISTS `portal_attachments`
(
  `id`                INT(10)     UNSIGNED NOT NULL AUTO_INCREMENT,
  `filename`          VARCHAR(255)         NOT NULL DEFAULT '',
  `file_type`         VARCHAR(50)          NOT NULL DEFAULT '',
  `file_size`         INT(10)     UNSIGNED NOT NULL DEFAULT 0,
  `uploaded_at`       TIMESTAMP            NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Portal attachments';
