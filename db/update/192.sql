ALTER TABLE `mobile_services` ADD COLUMN `filter_id` VARCHAR(60) NOT NULL DEFAULT '';

ALTER TABLE `portal_articles` ADD COLUMN `build_id`     SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `portal_articles` ADD COLUMN `address_flat` VARCHAR(10)          NOT NULL DEFAULT '';
