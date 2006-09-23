CREATE TABLE `abon_tariffs` (
  `id` smallint(6) unsigned NOT NULL auto_increment,
  `name` varchar(20) NOT NULL default '',
  `period` tinyint(2) unsigned NOT NULL default '0',
  `price` double(14,2) unsigned NOT NULL default '0.00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) ;

CREATE TABLE `abon_user_list` (
  `uid` int(11) unsigned NOT NULL default '0',
  `tp_id` smallint(6) unsigned NOT NULL default '0',
  `date` date NOT NULL default '0000-00-00'
) ;

CREATE TABLE `admin_actions` (
  `actions` varchar(100) NOT NULL default '',
  `datetime` datetime NOT NULL default '0000-00-00 00:00:00',
  `ip` int(11) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `id` int(11) unsigned NOT NULL auto_increment,
  `module` varchar(10) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `uid` (`uid`)
) ;


CREATE TABLE `admin_permits` (
  `aid` smallint(6) unsigned NOT NULL default '0',
  `section` smallint(6) unsigned NOT NULL default '0',
  `actions` smallint(6) unsigned NOT NULL default '0',
  `module` varchar(12) NOT NULL default '',
  UNIQUE KEY `aid_modules` (`aid`,`module`,`section`,`actions`),
  KEY `aid` (`aid`)
) ;


CREATE TABLE `admins` (
  `id` varchar(12) default NULL,
  `name` varchar(24) default NULL,
  `regdate` date default NULL,
  `password` varchar(16) binary NOT NULL default '',
  `gid` tinyint(4) unsigned NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL auto_increment,
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `phone` varchar(16) NOT NULL default '',
  `web_options` text NOT NULL,
  PRIMARY KEY  (`aid`),
  UNIQUE KEY `aid` (`aid`),
  UNIQUE KEY `id` (`id`)
) ;


CREATE TABLE `bills` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `deposit` double(15,6) NOT NULL default '0.000000',
  `uid` int(11) unsigned NOT NULL default '0',
  `company_id` int(11) unsigned NOT NULL default '0',
  `registration` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `uid` (`uid`,`company_id`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `dv_calls`
#

CREATE TABLE `dv_calls` (
  `status` int(3) default NULL,
  `user_name` varchar(32) default NULL,
  `started` datetime NOT NULL default '0000-00-00 00:00:00',
  `nas_ip_address` int(11) unsigned NOT NULL default '0',
  `nas_port_id` int(6) unsigned default NULL,
  `acct_session_id` varchar(25) NOT NULL default '',
  `acct_session_time` int(11) unsigned NOT NULL default '0',
  `acct_input_octets` int(11) unsigned NOT NULL default '0',
  `acct_output_octets` int(11) unsigned NOT NULL default '0',
  `ex_input_octets` int(11) unsigned NOT NULL default '0',
  `ex_output_octets` int(11) unsigned NOT NULL default '0',
  `connect_term_reason` int(4) NOT NULL default '0',
  `framed_ip_address` int(11) unsigned NOT NULL default '0',
  `lupdated` int(11) unsigned NOT NULL default '0',
  `sum` double(14,6) NOT NULL default '0.000000',
  `CID` varchar(18) NOT NULL default '',
  `CONNECT_INFO` varchar(20) NOT NULL default '',
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `nas_id` smallint(6) unsigned NOT NULL default '0',
  KEY `user_name` (`user_name`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `companies`
#

CREATE TABLE `companies` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(100) NOT NULL default '',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `tax_number` varchar(250) NOT NULL default '',
  `bank_account` varchar(250) default NULL,
  `bank_name` varchar(150) default NULL,
  `cor_bank_account` varchar(150) default NULL,
  `bank_bic` varchar(100) default NULL,
  `registration` date NOT NULL default '0000-00-00',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `credit` double(8,2) NOT NULL default '0.00',
  `address` varchar(100) NOT NULL default '',
  `phone` varchar(20) NOT NULL default '',
  `vat` double(5,2) unsigned NOT NULL default '0.00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `config`
#

CREATE TABLE `config` (
  `param` varchar(20) NOT NULL default '',
  `value` varchar(200) NOT NULL default '',
  UNIQUE KEY `param` (`param`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `docs_acct`
#

CREATE TABLE `docs_acct` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `date` date NOT NULL default '0000-00-00',
  `created` datetime NOT NULL default '0000-00-00 00:00:00',
  `customer` varchar(200) NOT NULL default '',
  `phone` varchar(16) NOT NULL default '0',
  `user` varchar(20) NOT NULL default '',
  `acct_id` int(10) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `docs_acct_orders`
#

CREATE TABLE `docs_acct_orders` (
  `acct_id` int(11) unsigned NOT NULL default '0',
  `orders` varchar(200) NOT NULL default '',
  `counts` int(10) unsigned NOT NULL default '0',
  `unit` tinyint(3) unsigned NOT NULL default '0',
  `price` double(10,2) unsigned NOT NULL default '0.00',
  KEY `aid` (`acct_id`)
) ;

# --------------------------------------------------------
#
# Структура таблиці `dv_main`
#

CREATE TABLE `dv_main` (
  `uid` int(11) unsigned NOT NULL auto_increment,
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `logins` tinyint(3) unsigned NOT NULL default '0',
  `registration` date default '0000-00-00',
  `ip` int(10) unsigned NOT NULL default '0',
  `filter_id` varchar(15) NOT NULL default '',
  `speed` int(10) unsigned NOT NULL default '0',
  `netmask` int(10) unsigned NOT NULL default '4294967294',
  `cid` varchar(35) NOT NULL default '',
  `password` varchar(16) binary NOT NULL default '',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `callback` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`uid`),
  KEY `tp_id` (`tp_id`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `exchange_rate`
#

CREATE TABLE `exchange_rate` (
  `money` varchar(30) NOT NULL default '',
  `short_name` varchar(30) NOT NULL default '',
  `rate` double(12,4) NOT NULL default '0.0000',
  `changed` date default NULL,
  `id` smallint(6) unsigned NOT NULL auto_increment,
  UNIQUE KEY `money` (`money`),
  UNIQUE KEY `short_name` (`short_name`),
  UNIQUE KEY `id` (`id`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `fees`
#

CREATE TABLE `fees` (
  `date` datetime NOT NULL default '0000-00-00 00:00:00',
  `sum` double(12,2) NOT NULL default '0.00',
  `dsc` varchar(80) NOT NULL default '',
  `ip` int(11) unsigned NOT NULL default '0',
  `last_deposit` double(15,6) NOT NULL default '0.000000',
  `uid` int(11) unsigned NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `id` int(11) unsigned NOT NULL auto_increment,
  `bill_id` int(11) unsigned NOT NULL default '0',
  `vat` double(5,2) unsigned NOT NULL default '0.00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `date` (`date`),
  KEY `uid` (`uid`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `filters`
#

CREATE TABLE `filters` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `filter` varchar(100) NOT NULL default '',
  `descr` varchar(200) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `filter` (`filter`)
)  ;

# --------------------------------------------------------

#
# Структура таблиці `groups`
#

CREATE TABLE `groups` (
  `gid` smallint(4) unsigned NOT NULL default '0',
  `name` varchar(12) NOT NULL default '',
  `descr` varchar(200) NOT NULL default '',
  PRIMARY KEY  (`gid`),
  UNIQUE KEY `gid` (`gid`),
  UNIQUE KEY `name` (`name`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `holidays`
#

CREATE TABLE `holidays` (
  `day` varchar(5) NOT NULL default '',
  `descr` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`day`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `icards`
#

CREATE TABLE `icards` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `prefix` varchar(4) NOT NULL default '',
  `nominal` double(15,2) NOT NULL default '0.00',
  `variant` smallint(6) NOT NULL default '0',
  `period` smallint(5) unsigned NOT NULL default '0',
  `expire` date NOT NULL default '0000-00-00',
  `changes` double(15,2) NOT NULL default '0.00',
  `password` varchar(16) binary NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `intervals`
#

CREATE TABLE `intervals` (
  `tp_id` smallint(6) unsigned NOT NULL default '0',
  `begin` time NOT NULL default '00:00:00',
  `end` time NOT NULL default '00:00:00',
  `tarif` varchar(7) NOT NULL default '0',
  `day` tinyint(4) unsigned default '0',
  `id` smallint(6) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `tp_intervals` (`tp_id`,`begin`,`day`)
)  ;

# --------------------------------------------------------

#
# Структура таблиці `ippools`
#

CREATE TABLE `ippools` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `nas` smallint(5) unsigned NOT NULL default '0',
  `ip` int(10) unsigned NOT NULL default '0',
  `counts` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `nas` (`nas`,`ip`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `dv_log`
#

CREATE TABLE `dv_log` (
  `start` datetime NOT NULL default '0000-00-00 00:00:00',
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `duration` int(11) NOT NULL default '0',
  `sent` int(10) unsigned NOT NULL default '0',
  `recv` int(10) unsigned NOT NULL default '0',
  `minp` double(10,2) unsigned NOT NULL default '0.00',
  `kb` double(10,2) unsigned NOT NULL default '0.00',
  `sum` double(14,6) NOT NULL default '0.000000',
  `port_id` smallint(5) unsigned NOT NULL default '0',
  `nas_id` tinyint(3) unsigned NOT NULL default '0',
  `ip` int(10) unsigned NOT NULL default '0',
  `sent2` int(11) unsigned NOT NULL default '0',
  `recv2` int(11) unsigned NOT NULL default '0',
  `acct_session_id` varchar(25) NOT NULL default '',
  `CID` varchar(18) NOT NULL default '',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `terminate_cause` tinyint(4) unsigned NOT NULL default '0',
  KEY `uid` (`uid`,`start`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `mail_access`
#

CREATE TABLE `mail_access` (
  `pattern` varchar(30) NOT NULL default '',
  `action` varchar(255) NOT NULL default '',
  `id` int(11) unsigned NOT NULL auto_increment,
  `comments` varchar(255) NOT NULL default '',
  `change_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`pattern`),
  UNIQUE KEY `id` (`id`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `mail_aliases`
#

CREATE TABLE `mail_aliases` (
  `address` varchar(255) NOT NULL default '',
  `goto` text NOT NULL,
  `domain` varchar(255) NOT NULL default '',
  `create_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `change_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` tinyint(2) unsigned NOT NULL default '1',
  `id` int(11) unsigned NOT NULL auto_increment,
  `comments` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`address`),
  UNIQUE KEY `id` (`id`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `mail_boxes`
#

CREATE TABLE `mail_boxes` (
  `username` varchar(255) NOT NULL default '',
  `password` varchar(16) binary NOT NULL default '',
  `descr` varchar(255) NOT NULL default '',
  `maildir` varchar(255) NOT NULL default '',
  `create_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `change_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `mails_limit` int(11) unsigned NOT NULL default '0',
  `status` tinyint(2) unsigned NOT NULL default '0',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `antivirus` tinyint(1) unsigned NOT NULL default '1',
  `antispam` tinyint(1) unsigned NOT NULL default '1',
  `expire` date NOT NULL default '0000-00-00',
  `id` int(11) unsigned NOT NULL auto_increment,
  `domain_id` smallint(6) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `box_size` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`username`,`domain_id`),
  UNIQUE KEY `id` (`id`),
  KEY `username_antivirus` (`username`,`antivirus`),
  KEY `username_antispam` (`username`,`antispam`)
)  ;

# --------------------------------------------------------

#
# Структура таблиці `mail_domains`
#

CREATE TABLE `mail_domains` (
  `domain` varchar(255) NOT NULL default '',
  `create_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `change_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` tinyint(2) unsigned NOT NULL default '0',
  `id` int(11) unsigned NOT NULL auto_increment,
  `comments` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`domain`),
  UNIQUE KEY `id` (`id`)
)  ;

# --------------------------------------------------------

#
# Структура таблиці `mail_transport`
#

CREATE TABLE `mail_transport` (
  `domain` varchar(128) NOT NULL default '',
  `transport` varchar(128) NOT NULL default '',
  `comments` varchar(255) NOT NULL default '',
  `change_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `id` int(11) unsigned NOT NULL auto_increment,
  UNIQUE KEY `domain` (`domain`),
  UNIQUE KEY `id` (`id`)
)  ;

CREATE TABLE `msgs_chapters` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(20) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
);

CREATE TABLE `msgs_messages` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `par` int(11) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `chapter` smallint(6) unsigned NOT NULL default '0',
  `message` text,
  `reply` text,
  `ip` int(11) unsigned default '0',
  `date` datetime NOT NULL default '0000-00-00 00:00:00',
  `state` tinyint(2) unsigned default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `subject` varchar(40) NOT NULL default '',
  PRIMARY KEY  (`id`)
);

CREATE TABLE `nas` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `name` varchar(30) default NULL,
  `nas_identifier` varchar(20) NOT NULL default '',
  `descr` varchar(250) default NULL,
  `ip` varchar(15) default NULL,
  `nas_type` varchar(20) default NULL,
  `auth_type` tinyint(3) unsigned NOT NULL default '0',
  `mng_host_port` varchar(21) default NULL,
  `mng_user` varchar(20) default NULL,
  `mng_password` varchar(16) binary  NOT NULL default '',
  `rad_pairs` text NOT NULL,
  `alive` smallint(6) unsigned NOT NULL default '0',
  `disable` tinyint(6) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
)  ;

# --------------------------------------------------------

#
# Структура таблиці `netflow_address`
#

CREATE TABLE `netflow_address` (
  `client_ip` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`client_ip`),
  UNIQUE KEY `client_ip` (`client_ip`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `networks`
#

CREATE TABLE `networks` (
  `ip` int(11) unsigned NOT NULL default '0',
  `netmask` int(11) unsigned NOT NULL default '0',
  `domainname` varchar(50) NOT NULL default '',
  `hostname` varchar(20) NOT NULL default '',
  `descr` text NOT NULL,
  `changed` datetime NOT NULL default '0000-00-00 00:00:00',
  `type` tinyint(3) unsigned NOT NULL default '0',
  `mac` varchar(18) NOT NULL default '',
  `id` int(11) unsigned NOT NULL auto_increment,
  `status` tinyint(2) unsigned NOT NULL default '0',
  `web_control` varchar(21) NOT NULL default '',
  PRIMARY KEY  (`ip`,`netmask`),
  UNIQUE KEY `id` (`id`)
)  ;

# --------------------------------------------------------

#
# Структура таблиці `payments`
#

CREATE TABLE `payments` (
  `date` datetime NOT NULL default '0000-00-00 00:00:00',
  `sum` double(10,2) NOT NULL default '0.00',
  `dsc` varchar(80) default NULL,
  `ip` int(11) unsigned NOT NULL default '0',
  `last_deposit` double(15,6) NOT NULL default '0.000000',
  `uid` int(11) unsigned NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `id` int(11) unsigned NOT NULL auto_increment,
  `method` tinyint(4) unsigned NOT NULL default '0',
  `ext_id` varchar(16) NOT NULL default '',
  `bill_id` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `date` (`date`),
  KEY `uid` (`uid`)
)  ;

# --------------------------------------------------------

#
# Структура таблиці `s_detail`
#

CREATE TABLE `s_detail` (
  `acct_session_id` varchar(25) NOT NULL default '',
  `nas_id` smallint(5) unsigned NOT NULL default '0',
  `acct_status` tinyint(2) unsigned NOT NULL default '0',
  `start` datetime default NULL,
  `last_update` int(11) unsigned NOT NULL default '0',
  `sent1` int(10) unsigned NOT NULL default '0',
  `recv1` int(10) unsigned NOT NULL default '0',
  `sent2` int(10) unsigned NOT NULL default '0',
  `recv2` int(10) unsigned NOT NULL default '0',
  `id` varchar(16) NOT NULL default '',
  KEY `sid` (`acct_session_id`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `shedule`
#

CREATE TABLE `shedule` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `uid` int(11) unsigned NOT NULL default '0',
  `date` date NOT NULL default '0000-00-00',
  `type` varchar(50) NOT NULL default '',
  `action` varchar(200) NOT NULL default '',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `counts` tinyint(4) unsigned NOT NULL default '0',
  `d` char(2) NOT NULL default '*',
  `m` char(2) NOT NULL default '*',
  `y` varchar(4) NOT NULL default '*',
  `h` char(2) NOT NULL default '*',
  `module` varchar(12) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `uniq_action` (`h`,`d`,`m`,`y`,`type`,`uid`),
  KEY `date_type_uid` (`date`,`type`,`uid`)
)  ;

# --------------------------------------------------------

#
# Структура таблиці `tarif_plans`
#

CREATE TABLE `tarif_plans` (
  `id` smallint(5) unsigned NOT NULL default '0',
  `hourp` double(15,5) unsigned NOT NULL default '0.00000',
  `month_fee` double(14,2) unsigned NOT NULL default '0.00',
  `uplimit` double(14,2) NOT NULL default '0.00',
  `name` varchar(40) NOT NULL default '',
  `day_fee` double(14,2) unsigned NOT NULL default '0.00',
  `logins` tinyint(4) NOT NULL default '0',
  `day_time_limit` int(10) unsigned NOT NULL default '0',
  `week_time_limit` int(10) unsigned NOT NULL default '0',
  `month_time_limit` int(10) unsigned NOT NULL default '0',
  `day_traf_limit` int(10) unsigned NOT NULL default '0',
  `week_traf_limit` int(10) unsigned NOT NULL default '0',
  `month_traf_limit` int(10) unsigned NOT NULL default '0',
  `prepaid_trafic` int(10) unsigned NOT NULL default '0',
  `change_price` double(14,2) unsigned NOT NULL default '0.00',
  `activate_price` double(14,2) unsigned NOT NULL default '0.00',
  `credit_tresshold` double(8,2) unsigned NOT NULL default '0.00',
  `age` smallint(6) unsigned NOT NULL default '0',
  `octets_direction` tinyint(2) unsigned NOT NULL default '0',
  `max_session_duration` smallint(6) unsigned NOT NULL default '0',
  `filter_id` varchar(15) NOT NULL default '',
  `payment_type` tinyint(1) NOT NULL default '0',
  `min_session_cost` double(14,5) unsigned NOT NULL default '0.00000',
  `rad_pairs` text NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `id` (`id`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `tp_nas`
#

CREATE TABLE `tp_nas` (
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `nas_id` smallint(5) unsigned NOT NULL default '0',
  KEY `vid` (`tp_id`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `trafic_tarifs`
#

CREATE TABLE `trafic_tarifs` (
  `id` tinyint(4) NOT NULL default '0',
  `descr` varchar(30) default NULL,
  `nets` text,
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `prepaid` int(11) unsigned default '0',
  `in_price` double(13,5) unsigned NOT NULL default '0.00000',
  `out_price` double(13,5) unsigned NOT NULL default '0.00000',
  `in_speed` int(10) unsigned NOT NULL default '0',
  `interval_id` smallint(6) unsigned NOT NULL default '0',
  `rad_pairs` text NOT NULL,
  `out_speed` int(10) unsigned NOT NULL default '0',
  UNIQUE KEY `id` (`id`,`interval_id`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `users`
#

CREATE TABLE `users` (
  `id` varchar(20) NOT NULL default '',
  `activate` date NOT NULL default '0000-00-00',
  `expire` date NOT NULL default '0000-00-00',
  `credit` double(10,2) NOT NULL default '0.00',
  `reduction` double(6,2) NOT NULL default '0.00',
  `registration` date default '0000-00-00',
  `password` varchar(16) binary NOT NULL default '',
  `uid` int(11) unsigned NOT NULL auto_increment,
  `gid` smallint(6) unsigned NOT NULL default '0',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `company_id` int(11) unsigned NOT NULL default '0',
  `bill_id` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`uid`),
  UNIQUE KEY `id` (`id`)
)  ;

# --------------------------------------------------------

#
# Структура таблиці `users_nas`
#

CREATE TABLE `users_nas` (
  `uid` int(10) unsigned NOT NULL default '0',
  `nas_id` smallint(5) unsigned NOT NULL default '0',
  KEY `uid` (`uid`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `users_pi`
#

CREATE TABLE `users_pi` (
  `uid` int(11) unsigned NOT NULL auto_increment,
  `fio` varchar(40) NOT NULL default '',
  `phone` bigint(16) unsigned NOT NULL default '0',
  `email` varchar(35) NOT NULL default '',
  `address_street` varchar(100) NOT NULL default '',
  `address_build` varchar(10) NOT NULL default '',
  `address_flat` varchar(10) NOT NULL default '',
  `comments` text NOT NULL,
  `contract_id` varchar(10) NOT NULL default '',
  PRIMARY KEY  (`uid`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `voip_calls`
#

CREATE TABLE `voip_calls` (
  `status` tinyint(4) unsigned NOT NULL default '0',
  `user_name` varchar(32) NOT NULL default '',
  `acct_session_id` varchar(25) NOT NULL default '',
  `calling_station_id` varchar(32) NOT NULL default '',
  `called_station_id` varchar(32) NOT NULL default '',
  `lupdated` int(11) unsigned NOT NULL default '0',
  `started` datetime NOT NULL default '0000-00-00 00:00:00',
  `nas_id` smallint(6) unsigned NOT NULL default '0',
  `client_ip_address` int(11) unsigned NOT NULL default '0',
  `conf_id` varchar(32) NOT NULL default '',
  `call_origin` tinyint(1) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `route_id` int(11) unsigned NOT NULL default '0',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `reduction` double(6,2) unsigned NOT NULL default '0.00'
) ;

# --------------------------------------------------------

#
# Структура таблиці `voip_log`
#

CREATE TABLE `voip_log` (
  `uid` int(11) unsigned NOT NULL default '0',
  `start` datetime NOT NULL default '0000-00-00 00:00:00',
  `duration` int(11) unsigned NOT NULL default '0',
  `calling_station_id` varchar(16) NOT NULL default '',
  `called_station_id` varchar(16) NOT NULL default '',
  `nas_id` smallint(6) NOT NULL default '0',
  `client_ip_address` int(11) unsigned NOT NULL default '0',
  `acct_session_id` varchar(25) NOT NULL default '',
  `tp_id` smallint(6) unsigned NOT NULL default '0',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `sum` double(14,6) NOT NULL default '0.000000',
  `terminate_cause` tinyint(4) unsigned NOT NULL default '0'
) ;

# --------------------------------------------------------

#
# Структура таблиці `voip_main`
#

CREATE TABLE `voip_main` (
  `uid` int(11) unsigned NOT NULL default '0',
  `tp_id` smallint(6) unsigned NOT NULL default '0',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `number` varchar(16) NOT NULL default '',
  `registration` date NOT NULL default '0000-00-00',
  `ip` int(11) unsigned NOT NULL default '0',
  `cid` varchar(35) NOT NULL default '',
  `allow_answer` tinyint(1) unsigned NOT NULL default '1',
  `allow_calls` tinyint(1) unsigned NOT NULL default '1',
  `logins` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`uid`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `voip_route_prices`
#

CREATE TABLE `voip_route_prices` (
  `route_id` int(11) unsigned NOT NULL default '0',
  `interval_id` int(11) unsigned NOT NULL default '0',
  `price` double(15,5) unsigned NOT NULL default '0.00000',
  `date` date NOT NULL default '0000-00-00',
  UNIQUE KEY `route_id` (`route_id`,`interval_id`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `voip_routes`
#

CREATE TABLE `voip_routes` (
  `prefix` varchar(14) NOT NULL default '',
  `name` varchar(20) NOT NULL default '',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `date` date NOT NULL default '0000-00-00',
  `parent` int(11) unsigned NOT NULL default '0',
  `descr` varchar(120) NOT NULL default '',
  `gateway_id` smallint(6) unsigned NOT NULL default '0',
  `id` int(11) unsigned NOT NULL auto_increment,
  `iso_codes` varchar(10) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `prefix` (`prefix`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `voip_tps`
#

CREATE TABLE `voip_tps` (
  `id` smallint(5) unsigned NOT NULL default '0',
  `day_time_limit` int(10) unsigned NOT NULL default '0',
  `week_time_limit` int(10) unsigned NOT NULL default '0',
  `month_time_limit` int(10) unsigned NOT NULL default '0',
  `max_session_duration` smallint(6) unsigned NOT NULL default '0',
  `min_session_cost` double(15,5) unsigned NOT NULL default '0.00000',
  `rad_pairs` text NOT NULL,
  `first_period` int(10) unsigned NOT NULL default '0',
  `first_period_step` int(10) unsigned NOT NULL default '0',
  `next_period` int(10) unsigned NOT NULL default '0',
  `next_period_step` int(10) unsigned NOT NULL default '0',
  `free_time` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`)
) ;



CREATE TABLE `help` (
  `function` varchar(20) NOT NULL default '',
  `title` varchar(200) NOT NULL default '',
  `help` text NOT NULL,
  PRIMARY KEY  (`function`),
  UNIQUE KEY `function` (`function`)
);


#
# Структура таблиці `web_online`
#

CREATE TABLE `web_online` (
  `admin` varchar(15) NOT NULL default '',
  `ip` varchar(15) NOT NULL default '',
  `logtime` int(11) unsigned NOT NULL default '0'
) ;
    


INSERT INTO admins VALUES ('abills','abills','2005-06-16', ENCODE('abills', 'test12345678901234567890'), 0, 1,0,'', '');
INSERT INTO admins VALUES ('system','Syetem user','2005-07-07', ENCODE('test', 'test12345678901234567890'), 0, 2, 0,'', '');



--
-- Dumping data for table `admin_permits`
--
INSERT INTO `admin_permits` (`aid`, `section`, `actions`, `module`) VALUES 
  (1,0,0,''),
  (1,0,1,''),
  (1,0,2,''),
  (1,0,3,''),
  (1,0,4,''),
  (1,0,5,''),
  (1,0,6,''),
  (1,1,0,''),
  (1,1,1,''),
  (1,1,2,''),
  (1,1,3,''),
  (1,2,0,''),
  (1,2,1,''),
  (1,2,2,''),
  (1,2,3,''),
  (1,3,0,''),
  (1,3,1,''),
  (1,4,0,''),
  (1,4,1,''),
  (1,4,2,''),
  (1,4,3,''),
  (1,5,0,''),
  (1,6,0,''),
  (1,7,0,''),
  (1,8,0,'');
