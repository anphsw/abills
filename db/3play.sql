create table triplay_tps (
	id 											SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
	name 										CHAR(40) NOT NULL DEFAULT '',
	internet_tp             SMALLINT UNSIGNED NOT NULL DEFAULT 0,
	iptv_tp                 SMALLINT UNSIGNED NOT NULL DEFAULT 0,
	voip_tp                 SMALLINT UNSIGNED NOT NULL DEFAULT 0,
	comment                 text NULL,
	unique                  (id),
	FOREIGN KEY (internet_tp) REFERENCES tarif_plans(id)
                            ON UPDATE CASCADE
						                ON DELETE RESTRICT,
	FOREIGN KEY (internet_tp) REFERENCES tarif_plans(id)
                            ON UPDATE CASCADE
						                ON DELETE RESTRICT,
  FOREIGN KEY (internet_tp) REFERENCES tarif_plans(id)
                            ON UPDATE CASCADE
						                ON DELETE RESTRICT
)COMMENT='For triplay tariff plans';

create table triplay_users (
	uid                      SMALLINT UNSIGNED NOT NULL DEFAULT 0,
	tp_id                    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
	unique                   (uid),
	FOREIGN KEY (tp_id) REFERENCES triplay_tps(id)
														ON UPDATE CASCADE
														ON DELETE RESTRICT
)COMMENT='Table for users in module Triplay';