SET SQL_MODE = 'NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';

CREATE TABLE IF NOT EXISTS `expert_question`
(
  `id`          INT(8) UNSIGNED PRIMARY KEY UNIQUE,
  `question`    TEXT,
  `description` TEXT
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Expert system nodes';

CREATE TABLE IF NOT EXISTS `expert_answer`
(
  `id`          INT(8) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `question_id` INT(8) UNSIGNED NOT NULL DEFAULT 0,
  `answer`      TEXT
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Expert system links';

CREATE TABLE IF NOT EXISTS `expert_faq`
(
  `id`       INT(8) UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `title`    VARCHAR(128)          NOT NULL DEFAULT '' COMMENT 'Title of faq',
  `body`     TEXT                                      COMMENT 'Description of faq',
  `type`     TINYINT(2) UNSIGNED   NOT NULL DEFAULT 0  COMMENT 'RESERVED. This field used before for displaying modal, web or separate page in mobile app now not using.',
  `icon`     VARCHAR(60)           NOT NULL DEFAULT '' COMMENT 'RESERVED. This field used before for displaying icon in mobile app now not using.',
  `priority` TINYINT UNSIGNED      NOT NULL DEFAULT 0  COMMENT 'Priority of showing for user'
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Expert faqs';
