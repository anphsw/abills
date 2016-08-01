create table cashbox_cashboxes (
`id`                   SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
`name`                 CHAR(40) NOT NULL,
`comments`             text,
PRIMARY KEY     (`id`)
)COMMENT="Cashboxes";

create table cashbox_spending (
`id`                   SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
`amount`                     DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
`spending_type_id`           SMALLINT NOT NULL DEFAULT 0,
`cashbox_id`                 SMALLINT NOT NULL DEFAULT 0,
`date`                       DATE NOT NULL DEFAULT '0000-00-00',
`comments`                   text,
PRIMARY KEY     (`id`)
)COMMENT="Spending";

create table cashbox_spending_types (
`id`                   SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
`name`                 CHAR(40) NOT NULL,
`comments`             text,
PRIMARY KEY     (`id`)
)COMMENT="Spending types";

create table cashbox_coming (
`id`                   SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
`amount`                     DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
`coming_type_id`           SMALLINT NOT NULL DEFAULT 0,
`cashbox_id`                 SMALLINT NOT NULL DEFAULT 0,
`date`                       DATE NOT NULL DEFAULT '0000-00-00',
`comments`                   text,
PRIMARY KEY     (`id`)
)COMMENT="Coming";

create table cashbox_coming_types (
`id`                   SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
`name`                 CHAR(40) NOT NULL,
`comments`             text,
PRIMARY KEY     (`id`)
)COMMENT="Coming types";

create table crm_work_schedule (
`aid`                 SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
`type`                SMALLINT(1) UNSIGNED NOT NULL DEFAULT 0,
`bet`                 DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
`bet_per_day`         DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
`bet_overtime`  DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
PRIMARY KEY (`aid`)
)COMMENT='Work schedule for admins';

create table crm_salaries_payed (
`aid`                 SMALLINT(6) UNSIGNED NOT NULL DEFAULT 0,
`year`                SMALLINT(4) UNSIGNED NOT NULL DEFAULT 0,
`month`               SMALLINT(2) UNSIGNED NOT NULL DEFAULT 0,
`date`                DATE NOT NULL DEFAULT '0000-00-00',
`bet`                 DOUBLE(10, 2) NOT NULL DEFAULT 0.00,
PRIMARY KEY (`aid`, `month`)
)COMMENT='Work schedule for admins';