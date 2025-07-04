CREATE TABLE IF NOT EXISTS `companies_bics` (
  `bank_name`      VARCHAR(150)      NOT NULL DEFAULT '',
  `bank_bic`       VARCHAR(100)      DEFAULT NULL,
  UNIQUE KEY `bank_bic` (`bank_bic`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Companies Bics';