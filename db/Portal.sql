CREATE TABLE IF NOT EXISTS `portal_articles` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `title` varchar(255) not null default '',
  `short_description` text NOT NULL default '',
  `content` text NOT NULL default '',
  `status` tinyint(1) NOT NULL default 0,
  `on_main_page` tinyint(1) default '0',
  `date` datetime default NULL,
  `portal_menu_id` int(10) unsigned NOT NULL default 0,
  PRIMARY KEY  (`id`),
  KEY `fk_portal_content_portal_menu` (`portal_menu_id`)
)COMMENT='information about article';


CREATE TABLE IF NOT EXISTS `portal_menu` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(45) not null default '',
  `url` varchar(100) not null default '',
  `date` datetime default NULL,
  `status` tinyint(1) not null default 0,
  PRIMARY KEY  (`id`)
)COMMENT='information about menu' ;



