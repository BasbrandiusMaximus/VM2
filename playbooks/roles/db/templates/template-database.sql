SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

CREATE DATABASE IF NOT EXISTS 'template-database' DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE 'template-database';

DROP TABLE IF EXISTS 'Klanten';
CREATE TABLE 'Klanten' (
    'klantnaam' text NOT NULL,
    'klantnummer' int(255) NOT NULL,
    'omgeving' text NOT NULL,
    'aantal_omgevingen' int(11) NOT NULL,
    'servernaam' text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

TRUNCATE TABLE 'klanten';

INSERT INTO 'Klanten' ('klantnaam', 'klantnummer', 'omgeving', 'aantal_omgevingen', 'servernaam') VALUES
('Thijs Test'. '1', 'test', '1', 'klant001-test-web1');

ALTER TABLE 'Klanten'
 ADD PRIMARY KEY ('klantnummer');

ALTER TABLE 'Klanten'
 MODIFY 'klantnummer' int(255) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;