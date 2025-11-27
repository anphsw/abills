CREATE TABLE IF NOT EXISTS `msgs_external_chats` (
  `id`        INT(11) UNSIGNED NOT NULL  AUTO_INCREMENT,
  `chat_id`   VARCHAR(32)      NOT NULL  DEFAULT '',
  `date`      DATETIME         NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  `name`      VARCHAR(60)      NOT NULL  DEFAULT '',
  `type`      VARCHAR(32)      NOT NULL  DEFAULT '',
  `uid`       INT(11) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `chat_id` (`chat_id`),
  KEY `uid` (`uid`),
  UNIQUE KEY `chat_id_type` (`chat_id`, `type`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Message external chats';

ALTER TABLE `msgs_reply` ADD COLUMN `contact_id` INT(11) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `msgs_messages` ADD COLUMN `external_chat_id` INT(11) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `msgs_messages` ADD KEY `external_chat_id` (`external_chat_id`);
REPLACE INTO `users_status` (`id`, `name`, `color`, `descr`) VALUES (6, '$lang{IN_TERMINATION_PROCESS}', 'f20791', '');
REPLACE INTO `users_status` (`id`, `name`, `color`, `descr`) VALUES (7, '$lang{TERMINATED_CONTRACT}', '9f040c', '');

ALTER TABLE `accident_log` ADD COLUMN `gid` SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `accident_log` ADD COLUMN `nas_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT 0;