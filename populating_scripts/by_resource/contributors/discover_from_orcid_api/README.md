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

### Ingesting CSV to GCIS
