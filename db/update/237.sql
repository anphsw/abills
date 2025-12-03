ALTER TABLE `storage_log` ADD COLUMN `article_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `storage_log` ADD COLUMN `storage_incoming_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `storage_log` ADD COLUMN `serial_number` VARCHAR(60) DEFAULT '';
ALTER TABLE `storage_log` ADD COLUMN `extra_data` TEXT;
ALTER TABLE `storage_log` ADD COLUMN `operation_data` TEXT;

ALTER TABLE `storage_log` ADD INDEX `idx_article_id` (`article_id`);
ALTER TABLE `storage_log` ADD INDEX `idx_storage_incoming_id` (`storage_incoming_id`);
ALTER TABLE `storage_log` ADD INDEX `idx_serial_number` (`serial_number`);