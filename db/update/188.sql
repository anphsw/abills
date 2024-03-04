ALTER TABLE `referral_requests` ADD COLUMN `inner_comments` VARCHAR(200)  DEFAULT '' NOT NULL COMMENT 'Inner comment for admin';
ALTER TABLE `portal_articles` ADD COLUMN `deeplink` TINYINT(1) NOT NULL DEFAULT 0;
