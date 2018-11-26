CREATE TABLE IF NOT EXISTS `extreceipts` (
  `payments_id` INT(11)    UNSIGNED NOT NULL DEFAULT 0,
  `command_id`  INT(11)    UNSIGNED NOT NULL DEFAULT 0,
  `receipt_id`  INT(11)    UNSIGNED NOT NULL DEFAULT 0,
  `status`      TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`payments_id`)
)
  COMMENT = 'External receipts';