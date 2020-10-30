CREATE TABLE IF NOT EXISTS `admins_payments_types` (
  id               INT         UNSIGNED NOT NULL AUTO_INCREMENT,
  payments_type_id TINYINT(4)  UNSIGNED NOT NULL DEFAULT '0',
  aid              SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (id),
  KEY `payments_type_id` (`payments_type_id`),
  KEY `aid` (`aid`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Allowed payments types for admins';
