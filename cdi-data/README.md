This directory contains the SQL scripts used for the initial load of vocabulary, 
relationships, and mappings for the Climate Data Initiative (CDI).

From a psql prompt, just run `\i CDI-000_LOAD_ALL.sql`.

Before loading the data, the GCIS data base should be instantiated, populated with
data from a GCIS DB `pg_dump`, and patched up to 
2270\_toolkit\_casestudy\_featured.sql.

