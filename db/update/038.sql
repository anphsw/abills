# Comment

ALTER TABLE `shedule` ADD KEY uid (uid);

CREATE TABLE IF NOT EXISTS `storage_inner_use` (
  `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `storage_incoming_articles_id` INT(10) UNSIGNED DEFAULT '0',
  `count` INT(10) UNSIGNED DEFAULT '0',
  `aid` INT(10) UNSIGNED DEFAULT '0',
  `date` DATETIME DEFAULT NULL,
  `sum` DOUBLE(10, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  `comments` TEXT,
  PRIMARY KEY (`id`),
  KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`)
);
