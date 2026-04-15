SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';
INSERT INTO `users` (`id`, `activate`, `expire`, `credit`, `reduction`, `reduction_date`, `registration`, `password`,
                     `uid`, `gid`, `disable`, `company_id`, `bill_id`, `ext_bill_id`, `credit_date`, `domain_id`,
                     `deleted`, `disable_date`)
VALUES ('test_user', '0000-00-00', '0000-00-00', '0.00', '0.00', '0000-00-00', '2025-12-03',
        ENCODE('xv2pqL', 'test12345678901234567890'), '1', '0', '0', '0', '215816', '0', '0000-00-00', '0', '0',
        '0000-00-00');
INSERT INTO `users_pi` (`uid`, `fio`, `fio2`, `fio3`, `phone`, `email`, `country_id`, `address_street`, `address_build`,
                        `address_flat`, `comments`, `contract_id`, `contract_date`, `contract_sufix`, `pasport_num`,
                        `pasport_date`, `pasport_grant`, `birth_date`, `reg_address`, `floor`, `entrance`, `zip`,
                        `city`, `accept_rules`, `location_id`, `tax_number`, `_SHCHET`, `_PIN_ABS`, `_test`,
                        `_google`, `_facebook`, `_apple`, `_G2FA`, `_testfield`, `_test_field`, `_test_list`,
                        `_document`)
VALUES ('1', '', '', '', '', '', '0', '', '', '', '', '1027349432', '2025-12-03', '', '', '0000-00-00', '',
        '0000-00-00', '', '0', '0', '', '', '0', '0', '0', '', '0', '0', ',', ',', ',', '', '', '', '0', '0');
INSERT INTO `bills` (`id`, `deposit`, `uid`, `company_id`, `registration`)
VALUES ('215816', '-100.000000', '1', '0', '2025-12-03');
INSERT INTO `fees` (`date`, `sum`, `dsc`, `ip`, `last_deposit`, `uid`, `aid`, `id`, `bill_id`, `vat`, `inner_describe`,
                    `method`, `reg_date`)
VALUES ('2025-12-03 00:00:00', '100.0000', 'Internet: М/А Console tests (71) 315(2025-12-01-2025-12-31)', '2887151617',
        '0.000000', '1', '1', '6195', '215816', '0.00', '', '1', '2025-12-03 17:45:22');
INSERT INTO `tarif_plans` (`id`, `month_fee`, `fixed_fees_day`, `uplimit`, `name`, `day_fee`, `active_day_fee`,
                           `logins`, `day_time_limit`, `week_time_limit`, `month_time_limit`, `day_traf_limit`,
                           `week_traf_limit`, `month_traf_limit`, `prepaid_trafic`, `change_price`, `activate_price`,
                           `credit_tresshold`, `age`, `octets_direction`, `max_session_duration`, `filter_id`,
                           `payment_type`, `min_session_cost`, `rad_pairs`, `reduction_fee`, `postpaid_daily_fee`,
                           `postpaid_monthly_fee`, `module`, `traffic_transfer_period`, `gid`, `neg_deposit_filter_id`,
                           `tp_id`, `ext_bill_account`, `credit`, `user_credit_limit`, `ippool`, `period_alignment`,
                           `min_use`, `abon_distribution`, `small_deposit_action`, `domain_id`, `total_time_limit`,
                           `total_traf_limit`, `priority`, `comments`, `bills_priority`, `fine`, `neg_deposit_ippool`,
                           `next_tp_id`, `fees_method`, `service_id`, `status`, `describe_aid`, `promotional`,
                           `ext_bill_fees_method`, `active_month_fee`, `popular`, `fixed_fees_free_period`,
                           `age_alignment`)
VALUES ('200', '100.00', '0', '0.00', 'Console tests', '0.00', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0.00',
        '0.00', '0.00', '0', '0', '0', '', '0', '0.00000', NULL, '0', '0', '0', 'Internet', '0', '0', '', '71', '0',
        '0.00', '0.00', '0', '0', '0.00', '0', '0', '0', '0', '0', '0', '', '0', '0.00', '0', '0', '1', '0', '0', '',
        '0', '0', '0', '0', '0', '0');
INSERT INTO `internet_main` (`id`, `uid`, `tp_id`, `logins`, `registration`, `ip`, `ipv6`, `ipv6_prefix`, `ipv6_mask`,
                             `ipv6_prefix_mask`, `netmask`, `filter_id`, `speed`, `cid`, `password`, `disable`,
                             `join_service`, `turbo_mode`, `free_turbo_mode`, `activate`, `expire`, `login`,
                             `detail_stats`, `personal_tp`, `cpe_mac`, `comments`, `port`, `vlan`, `nas_id`,
                             `server_vlan`, `ipn_activate`)
VALUES ('315', '1', '71', '0', '2025-12-03', '0', '', '', '32', '32', '4294967295', '', '0', '',
        ENCODE(NULL, 'test12345678901234567890'), '0', '0', '0', '0', '0000-00-00', '0000-00-00', '', '0', '0.00', '',
        '', '', '0', '0', '0', '0');
INSERT INTO `info_fields` (`id`, `name`, `sql_field`, `type`, `priority`, `abon_portal`, `user_chg`, `comment`,
                           `module`, `company`, `pattern`, `title`, `domain_id`, `required`)
VALUES ('6', 'Счет', '_SHCHET', '0', '0', '0', '0', '', '', '0', '', '', '0', '0');
INSERT INTO `info_fields` (`id`, `name`, `sql_field`, `type`, `priority`, `abon_portal`, `user_chg`, `comment`,
                           `module`, `company`, `pattern`, `title`, `domain_id`, `required`)
VALUES ('10', 'Пин', '_PIN_ABS', '1', '0', '1', '1', '', '', '0', '', '', '0', '0');
INSERT INTO `info_fields` (`id`, `name`, `sql_field`, `type`, `priority`, `abon_portal`, `user_chg`, `comment`,
                           `module`, `company`, `pattern`, `title`, `domain_id`, `required`)
VALUES ('13', 'is_ipn_connection', '_test', '4', '0', '1', '1', '', '', '0', '', '', '0', '0');
INSERT INTO `info_fields` (`id`, `name`, `sql_field`, `type`, `priority`, `abon_portal`, `user_chg`, `comment`,
                           `module`, `company`, `pattern`, `title`, `domain_id`, `required`)
VALUES ('15', 'Google', '_google', '16', '0', '0', '0', '', '', '0', '', '', '0', '0');
INSERT INTO `info_fields` (`id`, `name`, `sql_field`, `type`, `priority`, `abon_portal`, `user_chg`, `comment`,
                           `module`, `company`, `pattern`, `title`, `domain_id`, `required`)
VALUES ('17', 'Facebook', '_facebook', '16', '0', '0', '0', '', '', '0', '', '', '0', '0');
INSERT INTO `info_fields` (`id`, `name`, `sql_field`, `type`, `priority`, `abon_portal`, `user_chg`, `comment`,
                           `module`, `company`, `pattern`, `title`, `domain_id`, `required`)
VALUES ('18', 'Apple', '_apple', '16', '0', '0', '0', '', '', '0', '', '', '0', '0');
INSERT INTO `info_fields` (`id`, `name`, `sql_field`, `type`, `priority`, `abon_portal`, `user_chg`, `comment`,
                           `module`, `company`, `pattern`, `title`, `domain_id`, `required`)
VALUES ('26', 'G2FA', '_G2FA', '0', '0', '0', '0', '', '', '0', '', '', '0', '0');
INSERT INTO `info_fields` (`id`, `name`, `sql_field`, `type`, `priority`, `abon_portal`, `user_chg`, `comment`,
                           `module`, `company`, `pattern`, `title`, `domain_id`, `required`)
VALUES ('27', 'Test', '_testfield', '0', '0', '0', '0', '', '', '0', '', '', '2', '0');
INSERT INTO `info_fields` (`id`, `name`, `sql_field`, `type`, `priority`, `abon_portal`, `user_chg`, `comment`,
                           `module`, `company`, `pattern`, `title`, `domain_id`, `required`)
VALUES ('28', 'TEST FIELD', '_test_field', '0', '0', '0', '0', '', '', '0', '', '', '0', '0');
INSERT INTO `info_fields` (`id`, `name`, `sql_field`, `type`, `priority`, `abon_portal`, `user_chg`, `comment`,
                           `module`, `company`, `pattern`, `title`, `domain_id`, `required`)
VALUES ('29', 'Kaspi', '_kaspi', '0', '0', '0', '0', '', '', '1', '', '', '0', '0');
INSERT INTO `info_fields` (`id`, `name`, `sql_field`, `type`, `priority`, `abon_portal`, `user_chg`, `comment`,
                           `module`, `company`, `pattern`, `title`, `domain_id`, `required`)
VALUES ('32', 'Bank id', '_bank_id', '1', '0', '0', '0', '', '', '1', '', '', '0', '0');