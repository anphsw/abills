SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `portal_articles`
(
  `id`                INT(10) UNSIGNED     NOT NULL AUTO_INCREMENT,
  `title`             VARCHAR(255)         NOT NULL DEFAULT '',
  `short_description` TEXT                 NULL,
  `content`           TEXT                 NULL,
  `status`            TINYINT(1)           NOT NULL DEFAULT 0,
  `on_main_page`      TINYINT(1)                    DEFAULT '0',
  `date`              DATETIME                      DEFAULT NULL,
  `portal_menu_id`    INT(10) UNSIGNED     NOT NULL DEFAULT 0,
  `end_date`          DATETIME                      DEFAULT NULL,
  `archive`           TINYINT(1)           NOT NULL DEFAULT 0,
  `importance`        TINYINT(1)           NOT NULL DEFAULT 0,
  `gid`               VARCHAR(64)          NOT NULL DEFAULT '*',
  `tags`              SMALLINT(5) UNSIGNED NOT NULL DEFAULT 0,
  `domain_id`         SMALLINT(4)          NOT NULL DEFAULT 0,
  `district_id`       SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `street_id`         SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `build_id`          SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
  `address_flat`      VARCHAR(10)          NOT NULL DEFAULT '',
  `picture`           VARCHAR(32)          NOT NULL DEFAULT '',
  `permalink`         VARCHAR(255)                  DEFAULT NULL,
  `deeplink`          TINYINT(1)           NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `permalink` (`permalink`),
  KEY `fk_portal_content_portal_menu` (`portal_menu_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'information about article';


CREATE TABLE IF NOT EXISTS `portal_menu`
(
  `id`     INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`   VARCHAR(80)      NOT NULL DEFAULT '',
  `url`    VARCHAR(100)     NOT NULL DEFAULT '',
  `date`   DATETIME                  DEFAULT NULL,
  `status` TINYINT(1)       NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'information about menu';

CREATE TABLE IF NOT EXISTS `portal_newsletters`
(
  `id`                INT(10)     UNSIGNED NOT NULL AUTO_INCREMENT,
  `portal_article_id` INT(10)     UNSIGNED NOT NULL DEFAULT 0,
  `send_method`       TINYINT(2)  UNSIGNED NOT NULL DEFAULT '0',
  `status`            TINYINT(1)  UNSIGNED NOT NULL DEFAULT '0',
  `sent`              INT(10)     UNSIGNED NOT NULL DEFAULT '0',
  `start_datetime`    DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `portal_article_id` (`portal_article_id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Portal newsletters';

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
