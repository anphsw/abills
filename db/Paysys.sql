SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `paysys_log`
(
  `id`                INT(11) UNSIGNED       NOT NULL AUTO_INCREMENT,
  `system_id`         TINYINT(4) UNSIGNED    NOT NULL DEFAULT '0' COMMENT 'paysys_connect.id',
  `datetime`          DATETIME               NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `sum`               DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00' COMMENT 'sum of payment if not successful transaction can be changed',
  `commission`        DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `uid`               INT(11) UNSIGNED       NOT NULL DEFAULT '0' COMMENT 'users.uid',
  `transaction_id`    VARCHAR(50)            NOT NULL DEFAULT '' COMMENT 'ID which received from payment system',
  `info`              TEXT                   NOT NULL COMMENT 'Request body hash',
  `ip`                INT(11) UNSIGNED       NOT NULL DEFAULT '0' COMMENT 'User ip if did in user portal',
  `code`              BLOB                   NOT NULL,
  `paysys_ip`         INT(11) UNSIGNED       NOT NULL DEFAULT '0' COMMENT 'The IP address from which the transaction request was made.',
  `domain_id`         SMALLINT(6) UNSIGNED   NOT NULL DEFAULT '0' COMMENT 'domains.id',
  `status`            TINYINT(2) UNSIGNED    NOT NULL DEFAULT '0' COMMENT 'internal status of transaction ex 2 - successful',
  `user_info`         VARCHAR(120)                    DEFAULT NULL,
  `merchant_id`       TINYINT UNSIGNED       NOT NULL DEFAULT '0' COMMENT 'paysys_merchant_settings.id',
  `recurrent_payment` TINYINT(1) UNSIGNED    NOT NULL DEFAULT '0' COMMENT 'Is payment created as regular payment',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`),
  KEY `system_id` (`system_id`),
  KEY `merchant_id` (`merchant_id`),
  KEY `transaction_id` (`transaction_id`),
  KEY `status` (status),
  UNIQUE KEY `ps_transaction_id` (`domain_id`, `transaction_id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Paysys transactions log';

CREATE TABLE IF NOT EXISTS `paysys_main`
(
  `uid`                  INT(11) UNSIGNED     NOT NULL DEFAULT '0',
  `token`                TINYTEXT,
  `sum`                  DOUBLE(10, 2)        NOT NULL DEFAULT '0.00',
  `date`                 DATE                 NOT NULL,
  `paysys_id`            SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `external_last_date`   DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `attempts`             SMALLINT(2)          NOT NULL DEFAULT 0,
  `closed`               SMALLINT(1)          NOT NULL DEFAULT 0,
  `external_user_ip`     INT(11) UNSIGNED     NOT NULL DEFAULT 0,
  `recurrent_id`         SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `recurrent_cron`       VARCHAR(25)          NOT NULL DEFAULT '',
  `recurrent_module`     VARCHAR(25)          NOT NULL DEFAULT '',
  `order_id`             VARCHAR(50)          NOT NULL DEFAULT '',
  `subscribe_date_start` DATE                 NOT NULL DEFAULT '0000-00-00',
  `domain_id`            SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'domains.id',
  `info`                 VARCHAR(100)         NOT NULL DEFAULT '',
  UNIQUE (`uid`, `paysys_id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Paysys user for recurrent payments';

CREATE TABLE IF NOT EXISTS `paysys_terminals`
(
  `id`          INT(11) UNSIGNED     NOT NULL AUTO_INCREMENT,
  `type`        SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
  `status`      SMALLINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `location_id` INT(11) UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'builds.id',
  `work_days`   SMALLINT(3) UNSIGNED NOT NULL DEFAULT 0,
  `start_work`  TIME                 NOT NULL DEFAULT '00:00:00',
  `end_work`    TIME                 NOT NULL DEFAULT '00:00:00',
  `comment`     TEXT,
  `description` TEXT,
  PRIMARY KEY `id` (`id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Table for paysys terminals';

CREATE TABLE IF NOT EXISTS `paysys_terminals_types`
(
  `id`      INT(3) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`    VARCHAR(80)     NOT NULL DEFAULT '' COMMENT 'Internal name of terminal',
  `comment` TEXT COMMENT 'Internal comment of terminal',
  PRIMARY KEY `id` (`id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Table for paysys terminals types';

CREATE TABLE IF NOT EXISTS `paysys_groups_settings`
(
  `id`        INT(10) UNSIGNED     NOT NULL AUTO_INCREMENT,
  `gid`       SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'groups.gid',
  `paysys_id` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'paysys_connect.id',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'domains.id',
  PRIMARY KEY `id` (`id`),
  KEY `paysys_id` (`paysys_id`),
  KEY `gid` (`gid`)
)
  CHARSET = 'utf8'
  COMMENT = 'Settings for each group';

CREATE TABLE IF NOT EXISTS `paysys_connect`
(
  `id`             TINYINT(4) UNSIGNED NOT NULL AUTO_INCREMENT,
  `paysys_id`      TINYINT UNSIGNED    NOT NULL DEFAULT 0 COMMENT 'ID of payment system inside payment plugin',
  `subsystem_id`   TINYINT UNSIGNED    NOT NULL DEFAULT 0 COMMENT 'ID of inheritance module',
  `name`           VARCHAR(80)         NOT NULL DEFAULT '' COMMENT 'Name of plugin module',
  `module`         VARCHAR(40)         NOT NULL DEFAULT '' COMMENT 'Local redefined plugin name',
  `status`         TINYINT UNSIGNED    NOT NULL DEFAULT 0 COMMENT 'Status of plugin 1 enabled 0 disabled',
  `paysys_ip`      TEXT                NOT NULL COMMENT 'IP list of allowed for payments',
  `payment_method` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'payments_type.id',
  `priority`       TINYINT(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Priority of buttons in user portal',
  PRIMARY KEY `id` (`id`),
  UNIQUE KEY `paysys_id` (`paysys_id`)
)
  CHARSET = 'utf8'
  COMMENT = 'Paysys connected plugins';

CREATE TABLE IF NOT EXISTS `paysys_merchant_settings`
(
  `id`            TINYINT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `merchant_name` VARCHAR(40)          NOT NULL DEFAULT '' COMMENT 'Internal merchant(receiver) name',
  `system_id`     TINYINT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'paysys_connect.id',
  `domain_id`     SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'domains.id',
  PRIMARY KEY `id` (`id`),
  FOREIGN KEY (`system_id`) REFERENCES `paysys_connect` (`id`) ON DELETE CASCADE
)
  CHARSET = 'utf8'
  COMMENT = 'Paysys merchant settings';

CREATE TABLE IF NOT EXISTS `paysys_merchant_params`
(
  `id`          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `param`       VARCHAR(50)      NOT NULL DEFAULT '' COMMENT 'Parameter name ex PAYSYS_SYSTEM_NAME',
  `value`       VARCHAR(400)     NOT NULL DEFAULT '' COMMENT 'Value of parameter ex 12345',
  `merchant_id` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'paysys_merchant_settings.id',
  PRIMARY KEY `id` (`id`),
  FOREIGN KEY (`merchant_id`) REFERENCES `paysys_merchant_settings` (`id`) ON DELETE CASCADE
)
  CHARSET = 'utf8'
  COMMENT = 'Paysys merchant params';

CREATE TABLE IF NOT EXISTS `paysys_merchant_to_groups_settings`
(
  `id`        INT(10) UNSIGNED     NOT NULL AUTO_INCREMENT,
  `gid`       SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'groups.gid',
  `paysys_id` SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'paysys_connect.id',
  `merch_id`  TINYINT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'paysys_merchant_settings.id',
  `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'domains.id',
  PRIMARY KEY `id` (`id`),
  KEY `paysys_id` (`paysys_id`),
  KEY `merch_id` (`merch_id`),
  FOREIGN KEY (`merch_id`) REFERENCES `paysys_merchant_settings` (`id`) ON DELETE CASCADE
)
  CHARSET = 'utf8'
  COMMENT = 'Settings for each group';

CREATE TABLE IF NOT EXISTS `paysys_requests`
(
  `id`             INT(11) UNSIGNED       NOT NULL AUTO_INCREMENT,
  `system_id`      TINYINT(4) UNSIGNED    NOT NULL DEFAULT '0' COMMENT 'paysys_connect.id',
  `datetime`       DATETIME               NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Time when did request',
  `uid`            INT(11) UNSIGNED       NOT NULL DEFAULT '0' COMMENT 'users.uid',
  `request`        TEXT                   NOT NULL COMMENT 'Request body on paysys_check.cgi',
  `response`       TEXT                   NOT NULL COMMENT 'Response body on request on paysys_check.cgi',
  `transaction_id` INT(11) UNSIGNED       NOT NULL DEFAULT '0' COMMENT 'paysys_log.id',
  `http_method`    VARCHAR(10)            NOT NULL DEFAULT '' COMMENT 'HTTP method of request',
  `paysys_ip`      INT(11) UNSIGNED       NOT NULL DEFAULT '0' COMMENT 'IP from which made request',
  `error`          VARCHAR(64)            NOT NULL DEFAULT '' COMMENT 'Internal error message',
  `status`         SMALLINT(2) UNSIGNED   NOT NULL DEFAULT '0' COMMENT 'Status of request',
  `request_type`   TINYINT(2) UNSIGNED    NOT NULL DEFAULT '0' COMMENT 'Request type ex check or pay',
  `sum`            DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00' COMMENT 'Sum in request body',
  PRIMARY KEY (`id`),
  KEY `paysys_id` (`system_id`),
  KEY `uid` (`uid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Paysys access log';
