ALTER TABLE `accident_equipments` MODIFY `date`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE `accident_equipments` MODIFY `end_date` DATETIME NOT NULL DEFAULT '0000-00-00';

CREATE TABLE IF NOT EXISTS `tariff_plan_gradients` (
  `id`          SMALLINT(6) UNSIGNED   NOT NULL AUTO_INCREMENT,
  `tp_id`       SMALLINT(6) UNSIGNED   NOT NULL DEFAULT '0',
  `start_value` INT UNSIGNED           NOT NULL DEFAULT '0',
  `units`       TINYINT(4) UNSIGNED    NOT NULL DEFAULT '0',
  `price`       DOUBLE(14, 2) UNSIGNED NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`id`),
  UNIQUE KEY `tp_gradient_start_value` (`tp_id`, `start_value`),
  KEY `tp_id` (tp_id)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Tariff plan gradients';

ALTER TABLE `abon_user_list` ADD COLUMN `discount_expire` DATE NOT NULL DEFAULT '0000-00-00';
ALTER TABLE `abon_user_list` ADD COLUMN `discount_activate` DATE NOT NULL DEFAULT '0000-00-00';