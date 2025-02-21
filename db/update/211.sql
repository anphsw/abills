CREATE TABLE IF NOT EXISTS `equipment_onu_models`(
   `id`               INT         UNSIGNED NOT NULL AUTO_INCREMENT,
   `pon_type`         VARCHAR(10)          NOT NULL DEFAULT '',
   `onu_type`         VARCHAR(10)          NOT NULL DEFAULT '',
   `wifi_ssids`       SMALLINT(10)UNSIGNED NOT NULL DEFAULT 0,
   `ethernet_ports`   SMALLINT(10)UNSIGNED NOT NULL DEFAULT 0,
   `voip_ports`       SMALLINT(10)UNSIGNED NOT NULL DEFAULT 0,
   `catv`             TINYINT(1)  UNSIGNED NOT NULL DEFAULT 0,
   `custom_profiles`  TINYINT(1)  UNSIGNED NOT NULL DEFAULT 0,
   `capability`       TINYINT(1)  UNSIGNED NOT NULL DEFAULT 0,
   `image`            VARCHAR(100)                  DEFAULT '',
   PRIMARY KEY (`id`)
)
  DEFAULT CHARSET=utf8 COMMENT = 'Equipment log onu';

ALTER TABLE `docs_invoices` ADD COLUMN `send_date`    DATE  NOT NULL;
ALTER TABLE `docs_invoices` ADD COLUMN `receive_date` DATE  NOT NULL;