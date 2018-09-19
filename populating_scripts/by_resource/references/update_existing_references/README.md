# Updating Reference Key Values

## Use Case

When many references have new or updated attr keys, this script can automate
the process of updating those.

This script runs in an "add-only" mode by default, so only new keys are
added to existing reference attrs. If the update flag is supplied, existing
keys are updated as well as new keys added.

This script never deletes reference attr keys.

If the reference does not exist in GCIS, it is skipped.

## Options

**url**  
GCIS url, e.g. http://data-stage.globalchange.gov

**file**  
File containing the reference uris and keys to update.  
Example:  
```yaml
---
- uri: /reference/00ba60eb-88b2-4ca5-860d-1af87a8becb2
  ISSN: 1234-4312
- uri: /reference/06df11af-a2ec-4d3b-9d7a-acf9783e1e4f
  ISSN: 1234-4312
  Year: 2013
- uri: /reference/9e08d11c-6cbc-4531-8cb3-80f5b81fabb1
  ISSN: 1234-4312

```

**update**  
A flag to overwrite existing key values

**verbose**  
**dry_run**  

## Example Runs

# Only add new keys
./update-reference-keys.pl \
  --url http://data-stage.globalchange.gov \
  --file test_refs.yaml \
  --verbose \
  --dry_run

# Add new keys and update existing ones
./update-reference-keys.pl \
  --url http://data-stage.globalchange.gov \
  --file test_refs.yaml \
  --update \
  --verbose \
  --dry_run

## Requirements

[GCIS PL Client](https://github.com/USGCRP/gcis-pl-client)  
API key access in the client for the GCIS url used.  
