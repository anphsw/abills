ALTER TABLE `docs_invoices` CHANGE COLUMN `send_date` `tracking_date_to` DATE NOT NULL;
ALTER TABLE `docs_invoices` CHANGE COLUMN `tracking_number` `tracking_number_to` VARCHAR(100) NOT NULL DEFAULT '';
ALTER TABLE `docs_invoices` CHANGE COLUMN `tracking_date` `tracking_date_from` DATE NOT NULL;
ALTER TABLE `docs_invoices` ADD COLUMN `tracking_number_from` VARCHAR(100) NOT NULL DEFAULT '';