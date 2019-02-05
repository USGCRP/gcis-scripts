# create_generic_from_reference.pl

## Purpose

After creating references for a report, this script should be run to create
Generic publications corresponding to publication types GCIS does not
specifically handle.

## How To

*Create for all references of a type*

```
./create_generic_from_references.pl \
  --type cproc \
  --max_update -1
```

*Update a provided list of references*

```
./create_generic_from_references.pl \
  --references /tmp/references.txt \
  --max_update -1
```

