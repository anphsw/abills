ALTER TABLE `tasks_main` ADD COLUMN `location_id` INT(11) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE 'employees_cashboxes_admins' ADD COLUMN `department` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `employees_cashboxes_admins` DROP INDEX `cashbox_id`, ADD INDEX `cashbox_id` (cashbox_id);