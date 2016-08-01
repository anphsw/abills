CREATE TABLE IF NOT EXISTS `portal_articles` (
  `id`                INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `title`             VARCHAR(255)     NOT NULL DEFAULT '',
  `short_description` TEXT             NULL,
  `content`           TEXT             NULL,
  `status`            TINYINT(1)       NOT NULL DEFAULT 0,
  `on_main_page`      TINYINT(1)                DEFAULT '0',
  `date`              DATETIME                  DEFAULT NULL,
  `portal_menu_id`    INT(10) UNSIGNED NOT NULL DEFAULT 0,
  `end_date`          DATETIME                  DEFAULT NULL,
  `archive`           tinyint(1)       NOT NULL DEFAULT 0,
  `importance`        tinyint(1)       NOT NULL DEFAULT 0,
  `gid`               smallint(4)      NOT NULL DEFAULT 0,
  `tags`              smallint(4)      NOT NULL DEFAULT 0,
  `district_id`       smallint(6) unsigned NOT NULL DEFAULT 0,
  `street_id`         smallint(6) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `fk_portal_content_portal_menu` (`portal_menu_id`)
)
  COMMENT = 'information about article';


CREATE TABLE IF NOT EXISTS `portal_menu` (
  `id`     INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`   VARCHAR(45)      NOT NULL DEFAULT '',
  `url`    VARCHAR(100)     NOT NULL DEFAULT '',
  `date`   DATETIME                  DEFAULT NULL,
  `status` TINYINT(1)       NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
)
  COMMENT = 'information about menu';



