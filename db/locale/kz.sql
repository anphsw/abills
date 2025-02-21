REPLACE INTO `address_types` (`id`, `name`, `position`) VALUES
  (1, '$lang{OBLAST}', 1),
  (2, '$lang{DISTRICT}', 2),
  (3, '$lang{CITY}', 3);

REPLACE INTO `config` (`param`, `value`) VALUES
  ('DOCS_CURRENCY', '398'),
  ('DOCS_LANGUAGE', 'russian'),
  ('MONEY_UNIT_NAMES', 'тенге;тиынов'),
  ('CURRENCY_ICON', 'fas fa-tenge');