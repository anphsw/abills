SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';
CREATE TABLE IF NOT EXISTS `docs_edocs_services`
(
  `id`      TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `module`  VARCHAR(20)      NOT NULL DEFAULT '',
  `session` BLOB             NOT NULL,
  PRIMARY KEY (`id`)
)
  CHARSET = utf8
  COMMENT = 'Docs edocs services';

CREATE TABLE IF NOT EXISTS `docs_edocs`
(
  `id`         INT(11) UNSIGNED     NOT NULL AUTO_INCREMENT,
  `aid`        SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `uid`        INT(11) UNSIGNED     NOT NULL DEFAULT '0',
  `company_id` INT(11) UNSIGNED     NOT NULL DEFAULT '0',
  `ext_id`     VARCHAR(40)          NOT NULL DEFAULT '',
  `doc_id`     VARCHAR(60)          NOT NULL DEFAULT '',
  `doc_type`   TINYINT(1) UNSIGNED  NOT NULL DEFAULT '0',
  `status`     TINYINT(1) UNSIGNED  NOT NULL DEFAULT '0',
  `date`       DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `offer_id`   VARCHAR(128)         NOT NULL DEFAULT '',
  `branch_id`  VARCHAR(128)         NOT NULL DEFAULT '',
  KEY uid (`uid`),
  KEY aid (`aid`),
  PRIMARY KEY (`id`)
)
  CHARSET = utf8
  COMMENT = 'Docs edocs';

CREATE TABLE IF NOT EXISTS `docs_customers`
(
  `id`            INT(11) UNSIGNED     NOT NULL AUTO_INCREMENT,
  `uid`           INT(11) UNSIGNED     NOT NULL DEFAULT '0',
  `customer`      VARCHAR(50)          NOT NULL DEFAULT '',
  `type`          TINYINT(1) UNSIGNED  NOT NULL DEFAULT '0',
  `contract_id`   VARCHAR(10)          NOT NULL DEFAULT '',
  `contract_date` DATE                 NOT NULL,
  `inn`		      VARCHAR(20)          NOT NULL DEFAULT '',
  `edrpou`        VARCHAR(20)          NOT NULL DEFAULT '',
  `date`          DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_docs` 	  TINYINT(1) UNSIGNED  NOT NULL DEFAULT '0',
  `disable`       TINYINT(1) UNSIGNED  NOT NULL DEFAULT '0',
  `comments`      TEXT                 NOT NULL,
  PRIMARY KEY (`id`),
  KEY uid (`uid`)
)
  CHARSET = utf8
  COMMENT = 'Docs customers';