CREATE TABLE IF NOT EXISTS `equipment_ports_errors`(
 `date`       DATETIME             NOT NULL,
 `nas_id`     SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
 `port_id`    VARCHAR(32)          NOT NULL DEFAULT '',
 `in_errors`  INT(11) UNSIGNED     NOT NULL DEFAULT '0',
 `out_errors` INT(11) UNSIGNED     NOT NULL DEFAULT '0'
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Equipment ports errors';

ALTER TABLE `employees_coming` ADD COLUMN `payment_id` INT(11) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `crm_dialogue_messages` ADD COLUMN `external_id` VARCHAR(256) NOT NULL DEFAULT '';