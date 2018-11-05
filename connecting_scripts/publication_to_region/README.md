# Connect Regions & Publication Type Resources

## Use Case

Mass connecting GCIS resources to regions.

## Usage 

```
./connect_publications_to_regions.pl \
  --url http://data-stage.globalchange.gov \
  --input_file regions.txt \
  --dry
```

## Input File Format

```
region_uri_1 resource_uri_1
region_uri_1 resource_uri_2
region_uri_2 resource_uri_1
...
```
