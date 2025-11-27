ALTER TABLE `accident_log` MODIFY COLUMN `realy_time` DATETIME NOT NULL DEFAULT '0000-00-00';

ALTER TABLE `employees_cashboxes_moving` MODIFY COLUMN `id_spending` INT(11)  UNSIGNED  NOT NULL DEFAULT 0;
ALTER TABLE `employees_cashboxes_moving` MODIFY COLUMN `id_coming` INT(11)  UNSIGNED  NOT NULL DEFAULT 0;
ALTER TABLE `iptv_main` MODIFY COLUMN `subscribe_id` VARCHAR(64) NOT NULL DEFAULT '' COMMENT 'External service ID for synchronization';