CREATE TABLE IF NOT EXISTS `telegram_state_user` (
  `id`               INT(11) UNSIGNED     NOT NULL  AUTO_INCREMENT,
  `user_id`          BIGINT(20) UNSIGNED  NOT NULL  DEFAULT '0',
  `button`           VARCHAR(50)          NOT NULL  DEFAULT '',
  `fn`               VARCHAR(50)          NOT NULL  DEFAULT '',
  `args`             TEXT                 CHARACTER SET utf8mb4,
  `ping_count`       INT(11) UNSIGNED     NOT NULL DEFAULT 0,
  `created`          DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Telegram USER state';

CREATE TABLE IF NOT EXISTS `telegram_state_admin` (
  `id`               INT(11) UNSIGNED     NOT NULL  AUTO_INCREMENT,
  `user_id`          BIGINT(20) UNSIGNED  NOT NULL  DEFAULT '0',
  `button`           VARCHAR(50)          NOT NULL  DEFAULT '',
  `fn`               VARCHAR(50)          NOT NULL  DEFAULT '',
  `args`             TEXT                 CHARACTER SET utf8mb4,
  `ping_count`       INT(11) UNSIGNED     NOT NULL DEFAULT 0,
  `created`          DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Telegram ADMIN state';