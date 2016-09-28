These scripts and libraries are for harvesting dataset metadata information from data.gov.

Libraries

- Ckan.pm - Library for harvesting ckan metadata
- Iso.pm - Library for harvesting ISO metadata (may need some changes)
- Org.pm - Library for dealing with organizations

Scripts used for adding datasets

- add-ckan.pl - addes ckan metadata (from data.gov) to gcis
- check-org.pl - check to see if all organizations exist in gcis
- connect-ids.pl - generates gcids for data.gov datasets
- get-ckan.pl - reads ckan metadata for all climate tagged datasets from data.gov
- get-ckan-ds.pl - reads ckan metadata for specific datasets from data.gov
- get-tags.pl - get cdi tags for datasets from data.gov
- org-alias.pl - create aliases for organizations

Steps

- Note that in many scripts the url for the gcis instance is hardcoded.

1. Read ckan metadata for climate datasets from data.gov and write it in yaml format to stdout (e.g. get_ckan.yaml).

   ./get-ckan.pl

   Notes
   - For a list of specific data sets to get from data.gov, use get-ckan-ds.pl instead. 
     It takes as input a text file with a list of data.gov dataset names.

2. Check to see if all organizations exist in gcis.

   ./check_org < get_ckan.yaml

3. Add org aliases to gcis in lexicon datagov/Organization (if the organization does not exist, 
   see step 2).

   ./org-alias.pl < org_alias.yaml
   
   Notes
   - The input (org_alias.yaml) contains an array of manually entered mappings between data.gov 
     organizations (term) and gcids (gcid).
   - Use step 2 to get the organizations that need to be mapped and then repeat this step until 
     all organizations are mapped.

4. Generate gcids for data.gov datasets and write them in yaml format to stdout (e.g. connect_ids.yaml).

   ./connect-ids < get_ckan.yaml

   Notes
   - Also reads other_ids.yaml which contains an array of manually entered mappings between 
     data.gov ids (term) and gcids (gcid).

5. Copy metadata from ckan yaml file and put (update) metadata in GCIS

  ./add-ckan.pl < get_ckan.yaml

  Notes 
  - Also reads connect_ids.yaml

6. Get cdi tages for datasets form data.gov, produces yaml formatted output with tags on stdout (e.g. get_tags.yaml).

  ./get-tags.pl

  Notes
  - Also reads tags.yaml which contains a heirarchy of tags.

    tags.pl example:

```
---
Arctic:
  Arctic Ocean, Sea Ice and Coasts:
  Melting Glaciers, Snow and Ice:
```

  - There is no current script to add tags to gcis.

Other scripts

- ckan-test.pl - simple test script for testing ckan access
- check-gcis.pl - checks to see if data.gov datasets already exist in gcis (by data.gov name or id)
- rm-alias.pl - removes aliases (terms) from datagov lexicon (currently Organization context)
- rm-dup-org.pl - removes duplicates (terms) for organzations from datagov lexicon, checks for duplicates against 
    govman lexicon (agencyName and Agency)

Out of date or broken scripts

- check-meta.pl - compare Iso metadata for NASA archives (a bit out of date -- needs rework)
- create-ids.pl - create ids for NASA datasets (a bit out of date -- no longer used)
- data-alias.pl - create lexicon entries for datasets (functionality replaced by add-ckan.pl)
- get-iso.pl - at one point this would retrieve ISO metadata from data.gov (seems that this functionality is 
    currently broken in data.gov or authentication is required
- govman-list.pl - check acronyms (not really sure what this did)
- map-org.pl - maps data.gov organizations to gcis (a bit out of date -- no longer used)
- wcs-test.pl - tests wcs call to data.gov lexicon (this may not currently work)
