# Populating Contributors via Querying the OrcID API

## Overview

OrcID allows us to query their API with our Article DOIs, and will return
to us the list of OrcIDs it has associated with those DOIs.  

With this, we can create new persons, new organizations, and associate them
with the Articles. We can also find existing Persons in GCIS who lack their
OrcID, and update them with it.

## Process

We start by collecting a list of DOIs, one perline, and query the OrcID API
with them. This produces a CSV that we QA and fill in extra information. Once
the CSV is completely filled out, it is few into the final script which will
go through and create or update Persons (if needed), create Organizations (if
needed), and create the Contributor.

### Collecting DOIs

A list of DOIs that exist in GCIS should be obtained.

**Format**:  
```
doi.org/10.1126/science.1159196
doi.org/10.1038/nature11018
doi.org/10.1097/EDE.0b013e31816a1ce3
```

### Querying OrcID

**Input**: DOI List  
**Script**: find-authors-from-orcid.pl  
**Output**: QA CSV  

This is a read-only script to be run against GCIS.

```
./find-authors-from-orcid.pl \
   --url "https://data.globalchange.gov" \  #The GCIS instance you want to read from
   --doi doi-file.txt \                     #DOI file collected above
   --csv output.csv                         #Filename to be used for the QA csv
```

The script asks OrcID for any information it has on the article. It then takes each person
return from OrcID and checks if that OrcID already exists in GCIS, or if a Person with the
same full name exists. If so, it adds that Person to the line to be QA'd.

See `perldoc find-authors-from-orcid.pl` for technical details.

### Processing CSV

#### Initial CSV
The previous script will produce a CSV with these columns containing data:

 - `last_name`    - Person's last name according to OrcID
 - `first_name`   - Person's first name according to OrcID
 - `orcid`        - Person's OrcID according to OrcID
 - `doi`          - the DOI we queried OrcID with
 - `person_id`    - if GCIS found a person in GCIS with this orcid or the full name
 - `match_method` - if we found a person_id, did we find it via orcid (reliable) or full name (error prone)

It will also provide the following rows to fill out:

 - `confirm_person_match`
 - `organization_id`
 - `person_url`
 - `org_name`
 - `org_type`
 - `org_url`
 - `org_country_code`
 - `org_international_flag`
 - `sort_key`
 - `contributor_role`

#### CSV Processing Steps

If the row should be ignored, enter ignore into the confirm_person_match field.

##### Person info
**Confirm Person Match, if any**  

Confirm the Person in GCIS and the Person in OrcID are actually a match.  

If a match, enter "Yes" in the confirm_person_match field.  
If not a match, remove the `person_id` and proceed to the next step.  

**Confirm New Person, if no Match**  

If no `person_id` is provided, the script didn't find this person in GCIS.  
Confirm via checking the last name.  

If a matching GCIS person is found, add their `person_id` to the column and enter "Yes" in the confirm_person_match field.  

If no person is found, enter "New" in the confirm_person_match field (required)  
Research to find an appropriate URL and add to the `person_url` column. (optional, but encouraged).  

**Person Update**  

If the GCIS person exists but requires an update to their name or URL, enter the correct name/url in the appropriate field and set the confirm_person_match to "Update [thing] in GCIS".  

##### Organization info

Research to find the Organization the person was affiliated with in the creation of this article.  

If the organization already exists in GCIS, enter the organization identifier in `organization_id`.  
If the organization is new to GCIS, enter the correct information in the fields:  

 - `org_name`
 - `org_type`
 - `org_url`
 - `org_country_code`
 - `org_international_flag`

##### Contributor info

Enter the desired role_type and sort_key for this contributor.  
Blank role type will be treated as 'author'  

### Ingesting CSV to GCIS

**Input**: CSV List  
**Script**: create-contributions-from-orcid-authors.pl  
**Output**: CSV of changes made  

This script will update the GCIS istance it is run against.

```
./create-contributions-from-orcid-authors.pl \
   --url https://data-review.globalchange.gov \
   --input example_orcid_results.csv \
   --verbose
```

The script takes the combined CSV information and handles these situations:

  - Persons
    - Finds existing person
    - Creates a new person
    - Updates an existing persons name and/or URL
    - Will error if the person in GCIS has a different OrcID
  - Organizations
    - Finds existing orgs
    - Creates a new org
  - Contributor
    - Creates new contributors
    - Asserts the contributor with the role exists

Output CSV will have the following columns:

  - doi              - DOI of the line
  - orcid            - OrcID of the line
  - contrib_role     - Contributor role of the line
  - ignored          - If we skipped the line
  - person           - Whether the person existed or was created in GCIS, any updates applied.
  - skipping_contrib - If, after updating the person, we skip out on the org and contrib sections.
  - org              - Whether the org existed in GCIS, was created, or was not even processed
  - contrib          - Whether the contributor existed in GCIS, was created, or was not even processed
  - qa_contributor   - When the contributor exists we flag for additional QA on this item
  - error            - If the line couldn't be processed, this will say why. QA these lines

### Followup Work

Related Organizations and Organization Alternate Names for the organization must be handled by hand, for now.
