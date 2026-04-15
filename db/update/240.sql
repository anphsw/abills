CREATE TABLE IF NOT EXISTS `fees2payments`
(
    `payment_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
    `fees_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY `fees_payments` (`fees_id`, `payment_id`),
    UNIQUE KEY `fees_id` (`fees_id`),
    FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`),
    FOREIGN KEY (`fees_id`) REFERENCES `fees` (`id`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Fees 2 payments';

CREATE TABLE IF NOT EXISTS `fees_extra`
(
    `fees_id`    INT(11) UNSIGNED  NOT NULL DEFAULT 0,
    `start_date` DATE              not null default '0000-00-00',
    `end_date`   DATE              not null default '0000-00-00',
    `module`     VARCHAR(15)       NOT NULL DEFAULT '',
    `tp_id`      SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `count`      INT(11) UNSIGNED  NOT NULL DEFAULT 0,
    `units`      TINYINT UNSIGNED  NOT NULL DEFAULT 0,
    `discount`   DOUBLE(6, 2)      NOT NULL DEFAULT '0.00',
    `service_id` INT(11) UNSIGNED  NOT NULL DEFAULT 0,
    FOREIGN KEY (`fees_id`) REFERENCES `fees` (`id`) ON DELETE CASCADE,
    KEY `module` (`module`),
    KEY `tp_id` (`tp_id`),
    KEY `start_date` (`start_date`),
    KEY `end_date` (`end_date`)
)
    DEFAULT CHARSET = utf8
    COMMENT = 'Fees Extra values';

ALTER TABLE `builds` ADD COLUMN `start_numbering_floor` TINYINT(4) NOT NULL DEFAULT 1;


alter table users_pi add column   `pasport_expire`   DATE                 NOT NULL DEFAULT '0000-00-00';
alter table admins add column   `pasport_expire`   DATE                 NOT NULL DEFAULT '0000-00-00';
