# create_generic_from_reference.pl

## Purpose

After creating references for a report, this script should be run to create
Generic publications corresponding to publication types GCIS does not
specifically handle.

Should be given a file containing the reference IDs to create child pubs for.

References with existing child pubs will be skipped.

### File Format

```
003d86b9-80b4-4a81-8f88-5b715ee5f14a
003d86b9-80b4-4a81-8f88-5b715ee5f14b
003d86b9-80b4-4a81-8f88-5b715ee5f14c
```

## How To

*Test Run*

```
./create_generic_from_references.pl \
  --url https://data-stage.globalchange.gov \
  --file refs.txt \
  --dry \
  --max_update -1
```

*Create pubs and references*

```
./create_generic_from_references.pl \
  --url https://data-stage.globalchange.gov \
  --file refs.txt \
  --max_update -1
```

