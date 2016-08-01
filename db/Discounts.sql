create table discounts_discounts (
`id`                   SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
`name`                 CHAR(40) NOT NULL,
`size`                 SMALLINT NOT NULL default '0',
`comments`             text,
PRIMARY KEY     (`id`)
)COMMENT="Discounts table";

create table discounts_user_discounts (
`uid`                   int(10) unsigned NOT NULL DEFAULT '0',
`discount_id`           smallint(5) unsigned NOT NULL DEFAULT '0',
`date`                  date NOT NULL DEFAULT '0000-00-00',
UNIQUE KEY `uid_discount_id` (`uid`,`discount_id`)
)COMMENT="User discounts";