ALTER TABLE `paysys_connect` ADD COLUMN `payment_method` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `bonus_service_discount` ADD COLUMN `onetime_payment_sum` DOUBLE(10, 2) NOT NULL DEFAULT '0.00';
