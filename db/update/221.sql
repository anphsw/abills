REPLACE INTO `contracts_type` VALUES (1, '$lang{APPLICATION_TERMINATION_CONTRACT}', 'Docs_docs_contract_termination.pdf');
ALTER TABLE `msgs_messages` ADD COLUMN `client_responsible` VARCHAR(60) NOT NULL DEFAULT '';
ALTER TABLE `users_pi` MODIFY COLUMN `contract_id` VARCHAR(100) NOT NULL DEFAULT '';
ALTER TABLE `companies` MODIFY COLUMN `contract_id` VARCHAR(100) NOT NULL DEFAULT '';
