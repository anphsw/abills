SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `discounts_discounts`
(
    `id`       SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    `name`     CHAR(80)                         NOT NULL,
    `size`     SMALLINT                         NOT NULL DEFAULT '0',
    `comments` TEXT,
    PRIMARY KEY (`id`)
) COMMENT = 'Discounts for shop';

CREATE TABLE IF NOT EXISTS `discounts_user_discounts`
(
    `uid`         INT(10) UNSIGNED     NOT NULL DEFAULT '0',
    `discount_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
    `date`        DATE                 NOT NULL DEFAULT '0000-00-00',
    UNIQUE KEY `uid_discount_id` (`uid`, `discount_id`)
) COMMENT = 'User discounts for shop';

CREATE TABLE IF NOT EXISTS `discounts_main`
(
    `id`        SMALLINT UNSIGNED      NOT NULL AUTO_INCREMENT,
    `uid`       INT(11) UNSIGNED       NOT NULL DEFAULT 0,
    `percent`   SMALLINT               NOT NULL DEFAULT 0,
    `sum`       DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
    `from_date` DATE                   NOT NULL,
    `to_date`   DATE                   NOT NULL,
    `module`    VARCHAR(20)            NOT NULL DEFAULT '',
    `tp_id`     SMALLINT UNSIGNED      NOT NULL DEFAULT 0,
    `status`    TINYINT(1) UNSIGNED    NOT NULL DEFAULT 0,
    `type`      TINYINT(1) UNSIGNED    NOT NULL DEFAULT 0,
    `aid`       SMALLINT(3) UNSIGNED   NOT NULL DEFAULT 0 COMMENT 'Admin who created',
    `comments`  TEXT,
    `reg_date`  TIMESTAMP              NOT NULL  DEFAULT CURRENT_TIMESTAMP COMMENT 'Date of creation',
    PRIMARY KEY (`id`),
    KEY `uid` (`uid`),
    KEY `from_date` (`from_date`),
    KEY `to_date` (`to_date`),
    KEY `status` (`status`)
) COMMENT = 'Discounts users';
