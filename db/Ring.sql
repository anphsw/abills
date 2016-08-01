create table ring_rules (
	id                   SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
	name                 CHAR(40) NOT NULL DEFAULT '',
	date_start           DATE NOT NULL DEFAULT '0000-00-00',
	date_end             DATE NOT NULL DEFAULT '0000-00-00',
	time_start           time NOT NULL DEFAULT '00:00:00',
	time_end             time NOT NULL DEFAULT '00:00:00',
	every_month          smallint(1) NOT NULL DEFAULT 0,
	file                 CHAR(40) NOT NULL DEFAULT '',
	message              text NULL,
	comment              text NULL,
	unique               (id)
)COMMENT='Rules for autocall redial';

create table ring_users_filters (
	uid                  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
	r_id                 SMALLINT UNSIGNED NOT NULL DEFAULT 0,
	time                 time NOT NULL DEFAULT '00:00:00',
	date                 DATE NOT NULL DEFAULT '0000-00-00',
	status               tinyint(1) NOT NULL DEFAULT 0,
	unique               (uid, r_id),
	FOREIGN KEY (r_id) REFERENCES ring_rules(id)
                    ON UPDATE CASCADE
						        ON DELETE CASCADE
)COMMENT='Users filters';