ALTER TABLE `internet_main` ADD KEY `cid` (`cid`);

ALTER TABLE `msgs_address` DROP FOREIGN KEY `msgs_id`;

ALTER TABLE `msgs_address`  ADD CONSTRAINT `msgs_id` FOREIGN KEY (`id`) REFERENCES `msgs_messages` (`id`) ON DELETE CASCADE;