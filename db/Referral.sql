SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `referral_main` (
  `uid` INT(11) UNSIGNED PRIMARY KEY REFERENCES `users` (`uid`)
    ON DELETE CASCADE,
  `referrer` INT(11) UNSIGNED NOT NULL REFERENCES `users` (`uid`)
    ON DELETE CASCADE,
    KEY uid (`uid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Referral main table stores information about referrers and referrals';

CREATE TABLE IF NOT EXISTS `referral_log` (
    `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `uid` INT(11) UNSIGNED NOT NULL REFERENCES `users` (`uid`)
    ON DELETE CASCADE,
    `referrer` INT(11) UNSIGNED NOT NULL REFERENCES `users` (`uid`)
    ON DELETE CASCADE,
    `date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `referral_request` INT(11) UNSIGNED NOT NULL DEFAULT 0,
    `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
    `log_type` SMALLINT(1) UNSIGNED NOT NULL DEFAULT 0,
    KEY uid (`uid`),
    KEY referral_request (`referral_request`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Referral log table stores information about periodic referrals';

CREATE TABLE IF NOT EXISTS `referral_tp` (
    `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR (60) NOT NULL DEFAULT '',
    `bonus_amount` DOUBLE(10, 2) UNSIGNED NOT NULL  DEFAULT 0.00,
    `payment_arrears` INT(11) UNSIGNED NOT NULL  DEFAULT 0,
    `period` INT(11) UNSIGNED NOT NULL  DEFAULT 0,
    `repl_percent` SMALLINT(3) UNSIGNED NOT NULL  DEFAULT 0,
    `spend_percent` SMALLINT(3) UNSIGNED NOT NULL  DEFAULT 0,
    `bonus_bill` TINYINT(1) UNSIGNED NOT NULL  DEFAULT 0,
    `is_default`SMALLINT(1) NOT NULL DEFAULT 0
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Referral tp table stores information about referral tarifs';

CREATE TABLE IF NOT EXISTS `referral_requests` (
    `id` INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `fio` VARCHAR (60) NOT NULL DEFAULT '',
    `phone` VARCHAR (20) NOT NULL DEFAULT '',
    `address` VARCHAR (255) NOT NULL DEFAULT '',
    `status` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `referrer` INT (11) UNSIGNED NOT NULL DEFAULT 0,
    `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
    `date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `referral_uid` INT(11) UNSIGNED NOT NULL DEFAULT 0,
    `location_id` INT(11) UNSIGNED NOT NULL DEFAULT 0,
    `address_flat` VARCHAR(10) NOT NULL DEFAULT '',
    `comments` VARCHAR(100) NOT NULL DEFAULT '',
    KEY referral_uid (`referral_uid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Referral request table stores information about referral status and request info';
