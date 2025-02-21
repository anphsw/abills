ALTER TABLE `ureports_user_send_types` ADD COLUMN `error_code` INT(6) UNSIGNED NOT NULL DEFAULT 1;
ALTER TABLE `ureports_user_send_types` ADD COLUMN `error_msg` TEXT;
ALTER TABLE `ureports_user_send_types` ADD COLUMN `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE `ureports_user_send_types` MODIFY COLUMN `error_code` INT(6) UNSIGNED NOT NULL DEFAULT 1;
ALTER TABLE `ureports_log` MODIFY COLUMN `status` INT(6) UNSIGNED NOT NULL DEFAULT 0;