ALTER TABLE `users_contacts` ADD COLUMN `date` DATE NOT NULL DEFAULT '0000-00-00' COMMENT 'Date of adding contact';
ALTER TABLE `companies` ADD COLUMN `comments` TEXT NOT NULL DEFAULT '';