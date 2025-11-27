ALTER TABLE `storage_storages` ADD COLUMN `responsible` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `storage_storages` ADD KEY `responsible` (`responsible`);