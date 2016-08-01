
CREATE TABLE `tags` (
  `id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `priority` tinyint(4) unsigned NOT NULL default '0',
  `name` varchar(20) NOT NULL DEFAULT '',
  `comments` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Tags';


CREATE TABLE `tags_users` (
  `uid` int(10) unsigned NOT NULL DEFAULT '0',
  `tag_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `date` date NOT NULL DEFAULT '0000-00-00',
  UNIQUE KEY `uid_tag_id` (`uid`,`tag_id`)
) COMMENT='Users Tags';

