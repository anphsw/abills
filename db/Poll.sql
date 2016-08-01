create table poll_polls(
	id 										SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
	subject               CHAR(40) NOT NULL DEFAULT '',
	date                  DATE NOT NULL DEFAULT '0000-00-00',
	description           text NULL,
	status                SMALLINT NOT NULL DEFAULT 0,
	unique                (id)
)COMMENT='Table for polls';

create table poll_answers(
	id 										SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
	poll_id               SMALLINT UNSIGNED NOT NULL DEFAULT 0,
	answer                CHAR(40) NOT NULL DEFAULT '',
	unique                (id),
	FOREIGN KEY (poll_id) REFERENCES poll_polls(id)
                        ON UPDATE CASCADE
						            ON DELETE CASCADE
)COMMENT='Table for polls answers';

create table poll_votes(
	answer_id             SMALLINT UNSIGNED NOT NULL DEFAULT 0,
	poll_id								SMALLINT UNSIGNED NOT NULL DEFAULT 0,
	voter                 int(11) unsigned NOT NULL default 0,
	unique                (poll_id,voter),
	FOREIGN KEY (poll_id) REFERENCES poll_polls(id)
                        ON UPDATE CASCADE
						            ON DELETE CASCADE
)COMMENT='Table for votes';

create table poll_discussion(
	id 									  SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
	poll_id								SMALLINT UNSIGNED NOT NULL DEFAULT 0,
	date                  DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
	message               text NOT NULL,              
	voter                 varchar(20) NOT NULL default '',
	unique                (id),
	FOREIGN KEY (poll_id) REFERENCES poll_polls(id)
                        ON UPDATE CASCADE
						            ON DELETE CASCADE
)COMMENT='Table for discussion';