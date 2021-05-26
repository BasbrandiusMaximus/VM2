DROP TABLE IF EXISTS webdb;
CREATE TABLE webdb (
    message varcher(255) NOT NULL
)   ENGINE+MyISAM DEFAULT CHARSET=urf8;

INSERT INTO webdb (message) VALUES ('Test test');