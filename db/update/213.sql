ALTER TABLE `districts` ADD COLUMN `population` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `districts` ADD COLUMN `households` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `streets` ADD COLUMN `population` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `streets` ADD COLUMN `households` INT UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE `mobile_log` ADD KEY `user_subscribe_id` (`user_subscribe_id`);

