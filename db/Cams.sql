DROP TABLE IF EXISTS cams_tp;
DROP TABLE IF EXISTS cams_main;
DROP TABLE IF EXISTS cams_streams;
DROP TABLE IF EXISTS cams_user_streams;

CREATE TABLE cams_tp (
  id      INT(11)     UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name    VARCHAR(32) NOT NULL,
  abon_id SMALLINT(6) UNSIGNED NOT NULL REFERENCES abon_tariffs (`id`) ON DELETE RESTRICT,
  streams_count SMALLINT(6) UNSIGNED,
  UNIQUE KEY cams_abon (`abon_id`)
) ENGINE = 'InnoDB'
  COMMENT = 'Cams use Abon module subscribes';

CREATE TABLE cams_main (
  uid     INT(11) UNSIGNED REFERENCES abills.users (`uid`) ON DELETE CASCADE,
  tp_id   INT(11) UNSIGNED REFERENCES cams_tp (`id`) ON DELETE RESTRICT,
  created DATETIME,
  UNIQUE KEY cams_user (`uid`)
) ENGINE = 'InnoDB'
  COMMENT = 'Users subscribed to cams';

CREATE TABLE cams_streams (
  id       INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name     VARCHAR(32)   NOT NULL,
  ip       VARBINARY(11) NOT NULL,
  login    VARCHAR(32)   NOT NULL,
  password BLOB          NOT NULL,
  url      TEXT
) ENGINE = 'InnoDB'
  COMMENT = 'Storing all streams';


CREATE TABLE cams_user_streams (
  user_id   INT(11) UNSIGNED REFERENCES cams_main (`uid`)    ON DELETE CASCADE,
  stream_id INT(11) UNSIGNED REFERENCES cams_streams (`id`)    ON DELETE CASCADE,
  UNIQUE KEY cams_users_streams (`user_id`, `stream_id`)
) ENGINE = 'InnoDB'
  COMMENT = 'Many-to-many links beetween users and streams';

