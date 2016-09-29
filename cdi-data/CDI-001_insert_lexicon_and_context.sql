alter database gcis set search_path to gcis_metadata, pg_catalog;
insert into lexicon values ('cdi', 'Climate Data Initiative');
insert into lexicon values ('concept-map', 'Concept Map');
insert into lexicon values ('mesh', 'MeSH');
insert into context (lexicon_identifier, identifier) values ('cdi', 'health');
insert into context (lexicon_identifier, identifier) values ('mesh', 'resource');
insert into context (lexicon_identifier, identifier) values ('concept-map', 'vectorBorneDisease');
insert into context (lexicon_identifier, identifier) values ('concept-map', 'foodSafety');
insert into context (lexicon_identifier, identifier) values ('concept-map', 'waterIllness');
insert into context (lexicon_identifier, identifier) values ('concept-map', 'airQuality');
insert into context (lexicon_identifier, identifier) values ('concept-map', 'extremeWeather');
insert into context (lexicon_identifier, identifier) values ('concept-map', 'heatIllness');

