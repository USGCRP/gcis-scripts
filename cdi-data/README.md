This directory contains the SQL scripts used for the initial load of vocabulary, 
relationships, and mappings for the Climate Data Initiative (CDI).

From a psql prompt, just run `\i CDI-000_LOAD_ALL.sql`.

Before loading the data, the GCIS data base should be instantiated, populated with
data from a GCIS DB `pg_dump`, and patched up to 
2270\_toolkit\_casestudy\_featured.sql.

The data loaded by the SQL scripts came from 6 concept maps / spreadsheets for topic areas from the 2016 Health Assessment
* Vector Bourne Diseases (VB) [spreadsheet](https://docs.google.com/spreadsheets/d/17k1zl-BUMoA2nsAo4UVohd6VB3sJHbrYYiQ0T6xsQTc/edit#gid=268105789) | [concept map](https://drive.google.com/open?id=0BwyHiyendI9_Y2stbTdqUDFEbWc)
* Extreme Weather (XW) [spreadsheet](https://docs.google.com/spreadsheets/d/1j8cRAXtSchoUVxFa6JYZAbJNigRQZOYrSu-DGxZqUuc/edit#gid=724756332#gid=2126553932) | [concept map](https://drive.google.com/open?id=0BwScu2u7jmZJeFlpV0stQTVTb0k)
* Air Quality (AQ) [spreadsheet](https://docs.google.com/spreadsheets/d/1s-XjaRe5-kuDv2N3MW6YdnRW_C9634QiOHmn63ctY_k/edit) | [concept map](https://drive.google.com/open?id=0BwScu2u7jmZJMklPY1dxTjlZcHc)
* Heat Illness [spreadsheet](https://docs.google.com/spreadsheets/d/1R3w6iZppTp24lZAlLfSod1BJMZC5OytTrUXX3cXZGkM/edit#gid=235304796) | [concept map](https://drive.google.com/open?id=0BwScu2u7jmZJU2hsckRaNFlKazQ)
* Food Safety [spreadsheet](https://docs.google.com/spreadsheets/d/15aYDv7yqF90p5YeytLDpRqOzE4eUahtxaM6Cb61j7s4/edit#gid=365811436) | [concept map](https://drive.google.com/open?id=0BwScu2u7jmZJalVQcmF6UGZadm8)
* Water Illnes (WI) [spreadsheet](https://docs.google.com/spreadsheets/d/1DBZA2OrXHc2Sd9lIYWHmbQw7BMfrPkFFiTHTW2e7TP8/edit#gid=946049893) | [concept map](https://drive.google.com/open?id=0BwS_T6Klk_18UFJnd3A5eEJhaE0)
