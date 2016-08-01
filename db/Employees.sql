CREATE TABLE employees_positions (
	`id`								SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
	`position`      	  CHAR(40) unique NOT NULL DEFAULT '',
	`subordination`			SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  primary key (`id`)
)COMMENT='Employees positions';

CREATE TABLE employees_geolocation (
	`employee_id`       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
	`district_id`       smallint(6) unsigned NOT NULL DEFAULT 0,
  `street_id`         smallint(6) unsigned NOT NULL DEFAULT 0,
  `build_id`          smallint(6) unsigned NOT NULL DEFAULT 0
)COMMENT='Employees';