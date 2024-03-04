CREATE TABLE IF NOT EXISTS `building_statuses` (
  `id`         SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`       VARCHAR(50) NOT NULL DEFAULT '',
  `is_default` TINYINT(1)  UNSIGNED  NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Build statuses';

REPLACE INTO `building_statuses` (`id`, `name`, `is_default`) VALUES (1, '$lang{ENABLE}', 1), (2, '$lang{PLANNED_TO_CONNECT}', 0), (3, '$lang{CLOSED}', 0);
ALTER TABLE `builds` ADD COLUMN `status_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT 1;

ALTER TABLE `crm_competitor_geolocation` ADD KEY `competitor_id` (`competitor_id`);
ALTER TABLE `crm_competitor_geolocation` ADD KEY `district_id` (`district_id`);
ALTER TABLE `crm_competitor_geolocation` ADD KEY `street_id` (`street_id`);
ALTER TABLE `crm_competitor_geolocation` ADD KEY `build_id` (`build_id`);

ALTER TABLE `crm_competitor_tps_geolocation` ADD KEY `tp_id` (`tp_id`);
ALTER TABLE `crm_competitor_tps_geolocation` ADD KEY `district_id` (`district_id`);
ALTER TABLE `crm_competitor_tps_geolocation` ADD KEY `street_id` (`street_id`);
ALTER TABLE `crm_competitor_tps_geolocation` ADD KEY `build_id` (`build_id`);

ALTER TABLE `crm_leads` ADD COLUMN `floor` SMALLINT(3) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `crm_leads` ADD COLUMN `entrance` SMALLINT(3) UNSIGNED NOT NULL DEFAULT '0';