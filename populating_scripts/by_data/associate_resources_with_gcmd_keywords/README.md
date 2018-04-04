# Associating GCMD Keywords with GCIS Resources

## Purpose

This script accepts a CSV of GCIS URIs and GCMD Keywords and associates them
in GCIS. It does not handle removal of keywords.

See `perldoc associate_resources_with_gcmd_keywords.pl` for details.

## Usage

The columns `GCIS URI`, `GCMD Keyword UUID`, `Entity Type` are required.  
If your CSV has a `Notes` column, that will be output as the lines are processed but otherwise ignored.  
Other columns will be ignored.  


Dry run a single entry to test connection:  
```
./associate_resources_with_gcmd_keywords.pl \
  --url https://data-stage.globalchange.gov \
  --input sample_input.csv \
  --max 1 \
  --dry
```

Dry run the csv to check the results:  
```
./associate_resources_with_gcmd_keywords.pl \
  --url https://data-stage.globalchange.gov \
  --input sample_input.csv \
  --dry
```

Run for real:  
```
./associate_resources_with_gcmd_keywords.pl \
  --url https://data-stage.globalchange.gov \
  --input sample_input.csv
```

## Examples

Running the sample input file:

```
$ ./associate_resources_with_gcmd_keywords.pl --url https://data-review.globalchange.gov --input sample_input.csv
Found Columns: GCIS URI, GCMD Keyword UUID, Entity Type, Extra Col 1,  Extra Col 2, Notes
Associating Resources with GCMD Keywords
     url : http://data-review.globalchange.gov:3000
     input : sample_input.csv
     max_updates : -1
-----------------------------------------
-----------------------------------------
 uri : /report/nca3/chapter/water-energy-land-use/figure/energy-water-land-and-climate-interactions
     - GCMD Keyword 91697b7d-8f2b-4954-850e-61d5f61c867d
     - type figure
     - notes Only the first three columns matter
     - URI not associated with GCMD keyword, setting.
     - added GCMD relationship
-----------------------------------------
 uri : /report/nca3/chapter/water-energy-land-use/figure/energy-water-land-and-climate-interactions
     - GCMD Keyword 91697b7d-8f2b-4954-850e-61d5f61c867d
     - type figure
     - notes This is a repeat URI+UUID and should fail gracefully (in dry run, repeats above)
     - GCMD Keyword  91697b7d-8f2b-4954-850e-61d5f61c867d already set, skipping.
-----------------------------------------
 uri : /report/nca3/chapter/water-energy-land-use/figure/energy-water-land-and-climate-interactions
     - GCMD Keyword e9f67a66-e9fc-435c-b720-ae32a2c3d8f5
     - type figure
     - notes This is a repeat URI but new UUID and should work
     - URI not associated with GCMD keyword, setting.
     - added GCMD relationship
-----------------------------------------
 uri : /report/nca3/chapter/water-energy-land-use
     - GCMD Keyword e9f67a66-e9fc-435c-b720-ae32a2c3d8f5
     - type chapter
     - notes This is a new URI but repeat UUID and should work
     - URI not associated with GCMD keyword, setting.
     - added GCMD relationship
-----------------------------------------
 uri : /report/nca3/chapter/water-energy-land-use/figure/energy-water-land-and-climate-interactions
     - GCMD Keyword 464de0a5-2bb9-412-9fd3-1634cbc4e739
     - type figure
     - notes Invalid GCMD keywords should fail gracefully
     - GCMD does not exist
-----------------------------------------
 uri : /report/nc3/chapter/water-energy-land-use/figure/energy-water-land-and-climate-interactions
     - GCMD Keyword 464de0a5-2bb9-412-9fd3-1634cbc4e739
     - type figure
     - notes Invalid URI should fail gracefully
     - URI does not exist
-----------------------------------------
 uri :
     - GCMD Keyword
     - type
     - notes
     - URI not associated with GCMD keyword, setting.
```
