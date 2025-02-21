ALTER TABLE `accident_types` MODIFY COLUMN `comments` TEXT;

ALTER TABLE `expert_faq` ADD COLUMN `priority` TINYINT UNSIGNED NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `docs_customers`
(
  `id`            INT(11) UNSIGNED     NOT NULL AUTO_INCREMENT,
  `uid`           INT(11) UNSIGNED     NOT NULL DEFAULT '0',
  `customer`      VARCHAR(50)          NOT NULL DEFAULT '',
  `type`          TINYINT(1) UNSIGNED  NOT NULL DEFAULT '0',
  `contract_id`   VARCHAR(10)          NOT NULL DEFAULT '',
  `contract_date` DATE                 NOT NULL,
  `inn`		        VARCHAR(20)          NOT NULL DEFAULT '',
  `edrpou`        VARCHAR(20)          NOT NULL DEFAULT '',
  `date`          DATETIME             NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_docs` 	    TINYINT(1) UNSIGNED  NOT NULL DEFAULT '0',
  `disable`       TINYINT(1) UNSIGNED  NOT NULL DEFAULT '0',
  `comments`      TEXT                 NOT NULL,
  PRIMARY KEY (`id`)
)
  CHARSET = utf8
  COMMENT = 'Docs customers';
