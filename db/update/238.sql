ALTER TABLE `admin_actions` ADD KEY `module_type` (`module`, `action_type`);
ALTER TABLE `crm_open_lines` ADD COLUMN `autoclose` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0;