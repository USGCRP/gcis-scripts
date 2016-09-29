--This will load all intial data for the CDI vocabulary into the tables.
--DB schema is assumed to be patched to 2270_toolkit_casestudy_featured.sql

--Because of the way the scripts were created, some terms or relationships
--are duplicated, so supporess duplicate key messages
set client_min_messages to notice;

\i CDI-001_insert_lexicon_and_context.sql
\! echo -- -- Here is Vector Borne Disease -- --
\i CDI-002_VB-term.sql
\i CDI-003_VB-load-rship-fix.sql
\i CDI-004_VB-load-rship.sql
\i CDI-005_VB-load-cmap.sql
\i CDI-006_VB-load-term-rel.sql
\i CDI-007_VB-load-term-map.sql
\i CDI-008_VB-load-term-map-crt.sql
\i CDI-009_VB-load-term-map-gcis.sql
\! echo -- -- Here is Water Illness -- -- --
\i CDI-010_WI-term.sql
\i CDI-011_WI-load-cmap.sql
\i CDI-012_WI-load-term-rel.sql
\i CDI-013_WI-load-term-map.sql
\i CDI-014_WI-load-term-map-crt.sql
\i CDI-015_WI-load-term-map-gcis.sql
\i CDI-016_WI-Descriptions.sql
\! echo -- -- Here is Air Quality -- -- --
\i CDI-017_AQ-term.sql
\i CDI-018_AQ-load-cmap.sql
\i CDI-019_AQ-load-term-rel.sql
\i CDI-020_AQ-load-term-map.sql
\i CDI-021_AQ-load-term-map-crt.sql
\i CDI-022_AQ-load-term-map-gcis.sql
\! echo -- -- Here is Extreme Weather -- -- --
\i CDI-023_XW-term.sql
\i CDI-024_XW-load-cmap.sql
\i CDI-025_XW-load-term-rel.sql
\i CDI-026_XW-load-term-map.sql
\i CDI-027_XW-load-term-map-crt.sql
\i CDI-028_XW-load-term-map-gcis.sql
\! echo -- -- Here is Food Safety -- -- --
\i CDI-029_FS-term.sql
\i CDI-030_FS-load-cmap.sql
\i CDI-031_FS-load-term-rel.sql
\i CDI-032_FS-load-term-map.sql
\i CDI-033_FS-load-term-map-crt.sql
\i CDI-034_FS-load-term-map-gcis.sql
\! echo -- -- Here is Heat Illnes -- -- --
\i CDI-035_HI-term.sql
\i CDI-036_HI-load-cmap.sql
\i CDI-037_HI-load-term-rel.sql
\i CDI-038_HI-load-term-map.sql
\i CDI-039_HI-load-term-map-crt.sql
\i CDI-040_HI-load-term-map-gcis.sql
\! echo -- -- Final adjustments -- -- --
\i CDI-041_post-load-cleanup.sql

set client_min_messages to notice;
