ALTER TABLE `extreceipts_kkt` ADD COLUMN `tax_id` SMALLINT UNSIGNED NOT NULL DEFAULT '0';

REPLACE INTO `admin_permits` (`aid`, `section`, `actions`) SELECT aid, 0, 40 FROM `admins` WHERE aid > 3;

ALTER TABLE `users_phone_pin` ADD COLUMN `phone` VARCHAR(15) NOT NULL DEFAULT '';
