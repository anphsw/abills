SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `triplay_tps`
(
    `id`             SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    `tp_id`          SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `name`           CHAR(40)                         NOT NULL DEFAULT '',
    `internet_tp`    SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `iptv_tp`        SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `voip_tp`        SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `abon_tp`        SMALLINT UNSIGNED                NOT NULL DEFAULT 0,
    `comment`        TEXT                             NULL,
    PRIMARY KEY (`id`),
    KEY (`tp_id`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Triplay Tarif plans';

CREATE TABLE IF NOT EXISTS `triplay_main`
(
    `uid`      INT(11) UNSIGNED    NOT NULL DEFAULT 0,
    `tp_id`    SMALLINT UNSIGNED   NOT NULL DEFAULT 0,
    `disable`  TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `expire`   DATE                NOT NULL DEFAULT '0000-00-00',
    `personal_tp` double(14, 2) unsigned NOT NULL DEFAULT '0.00',
    `comments` VARCHAR(250)        NOT NULL DEFAULT '',
    PRIMARY KEY (`uid`),
    KEY `tp_id` (`tp_id`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'User table';

CREATE TABLE IF NOT EXISTS `triplay_services`
(
    `id`         INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `uid`        INT(11) UNSIGNED NOT NULL DEFAULT 0,
    `service_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
    `module`     VARCHAR(10)      NOT NULL DEFAULT '',
    `comments`   VARCHAR(250)     NOT NULL DEFAULT '',
    `disable`    TINYINT(1)       NOT NULL DEFAULT '0',
    `changed`    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY (`uid`, `module`, `service_id`),
    PRIMARY KEY (`id`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'User services';
