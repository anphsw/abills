ALTER TABLE `admins` ADD COLUMN `password_changed_at` DATE NOT NULL DEFAULT '0000-00-00';
ALTER TABLE `companie_admins` ADD COLUMN `assign_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE `companies` ADD COLUMN `email` VARCHAR(200) NOT NULL DEFAULT '';

ALTER TABLE `users_pi`  ADD COLUMN `indication`      VARCHAR(200) NOT NULL DEFAULT '';
ALTER TABLE `users_pi`  ADD COLUMN `contract_expiry` DATE NOT NULL DEFAULT '0000-00-00';
ALTER TABLE `users_pi`  ADD COLUMN `contract_status` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `users_pi`  ADD COLUMN `payment_type`    TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `companies` ADD COLUMN `indication`      VARCHAR(200) NOT NULL DEFAULT '';
ALTER TABLE `companies` ADD COLUMN `contract_expiry` DATE NOT NULL DEFAULT '0000-00-00';
ALTER TABLE `companies` ADD COLUMN `contract_status` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `companies` ADD COLUMN `payment_type`    TINYINT(1) UNSIGNED NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `admin_bruteforce` (
  `login`      VARCHAR(20)         NOT NULL  DEFAULT '',
  `password`   BLOB                NOT NULL,
  `api_key`    VARCHAR(64)         NOT NULL  DEFAULT '',
  `datetime`   DATETIME            NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `ip`         INT(11) UNSIGNED    NOT NULL  DEFAULT '0',
  `auth_state` TINYINT(1) UNSIGNED NOT NULL  DEFAULT '0'
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Admins credentials brute force';
