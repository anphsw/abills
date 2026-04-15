CREATE TABLE IF NOT EXISTS `ai_embeddings` (
  `id` INT AUTO_INCREMENT,
  `hash` VARCHAR(64) NOT NULL,
  `model` VARCHAR(64) NOT NULL,
  `vector` TEXT NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_hash_model` (`hash`, `model`)
);


ALTER TABLE `bonus_service_discount` ADD COLUMN `gid` SMALLINT(4) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `bonus_service_discount` ADD COLUMN `start_date` DATE not null default '0000-00-00';
ALTER TABLE `bonus_service_discount` ADD COLUMN `end_date`  DATE not null default '0000-00-00';