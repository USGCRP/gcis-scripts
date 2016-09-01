These scripts and libraries are for harvesting information from data.gov.

Libraries

Ckan.pm - Library for harvesting ckan metadata
Iso.pm - Library for harvesting ISO metadata (may need some changes)
Org.pm - Library for dealing with organizations

Scripts

  add-ckan.pl - addes ckan metadata (from data.gov) to gcis
  check-meta.pl*
  check-org.pl - check to see if all organizations exist in gcis
  ckan-test.pl*
  connect-ids.pl*
  create-ids.pl*
  data-alias.pl*
  get-ckan.pl - reads ckan metadata for climate datasets from data.gov
  get-iso.pl*
  get-tags.pl - get cdi tags for datasets from data.gov
  govman-list.pl*
  map-org.pl*
  org-alias.pl*
  rm-alias.pl*
  rm-dup-org.pl*
  wcs-test.pl*

Steps

1. Read ckan metadata for climate datasets from data.gov and write it to stdout (e.g. get_ckan.yaml).

   ./get-ckan.pl

2. Check to see if all organizations exist in gcis

   ./check_org < get_ckan.yaml

x. Copy metadata from ckan yaml file and put (update) metadata in GCIS

  ./add-ckan.pl < get_ckan.yaml

  Notes 
    a. also reads connect_ids.yaml
    b. have to update gcis url to point to correct instance

x. Get cdi tages for datasets form data.gov, produces yaml formatted output with tags on stdout (e.g. get_tags.yaml).
  ./get-tags.pl
