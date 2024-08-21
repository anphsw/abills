ALTER TABLE `portal_newsletters` ADD COLUMN `start_datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;

UPDATE `portal_newsletters` pn INNER JOIN `portal_articles` pa ON pa.id = pn.portal_article_id SET `start_datetime` = pa.`date`;
