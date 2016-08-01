create table megogo_tp (
id                   SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
name                 CHAR(40) NOT NULL,
amount               DOUBLE(10,2) NOT NULL default '0.00',
serviceid            CHAR(40) NOT NULL,
additional           SMALLINT(1) NOT NULL DEFAULT '0',
free_period          SMALLINT(1) NOT NULL DEFAULT '0',
PRIMARY KEY     (id)
)COMMENT="Megogo tp";

create table megogo_users (
uid                  int(11) unsigned NOT NULL default '0',
tp_id                SMALLINT(5) unsigned NOT NULL,
next_tp_id           SMALLINT(5) unsigned NOT NULL,
subscribe_date       date NOT NULL default '0000-00-00',
expiry_date          date NOT NULL default '0000-00-00',
suspend              SMALLINT(1) NOT NULL default '0',
active               SMALLINT(1) NOT NULL default '0',
unique               (uid, tp_id),
FOREIGN KEY (tp_id) REFERENCES megogo_tp(id)
                    ON UPDATE CASCADE
						  ON DELETE RESTRICT
)COMMENT="Megogo user account";


create table megogo_report (
tp_id           SMALLINT(5) UNSIGNED NOT NULL,
uid             int(11) unsigned NOT NULL DEFAULT '0',
days            SMALLINT UNSIGNED NOT NULL DEFAULT 0,
free_days       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
year            SMALLINT(4) UNSIGNED NOT NULL,
month           SMALLINT(2) UNSIGNED NOT NULL,
payments        DOUBLE(10,2) NOT NULL DEFAULT '0.00', 
unique          (tp_id, uid, year, month)
)COMMENT="Megogo report";

create table megogo_free_period (
uid                  INT(11) unsigned NOT NULL,
used                 SMALLINT(1) NOT NULL,
date_start           DATE NOT NULL,
unique               (uid)
)COMMENT="Megogo users who used free period";