# Add Tables From JSON

## Use Case

Given the fields for a GCIS table, create it.

## Usage

### Prereqs

[GCIS Perl Client](https://github.com/USGCRP/gcis-pl-client)  
[GCIS API credentials](https://github.com/USGCRP/gcis-pl-client#configuration)

### Showtime 

Run against a test instance of with dry run on first.

Updated Tables can be imported with the `--update`
flag.

Exmaple Run:

    ./add_tables_from_json.pl \
      --url https://data-stage.globalchange.gov \
      --file tables.json \
      --update

### Expected format

    [
      {
        "ordinal": 1,
        "identifier": "historic-and-decadal-global-mean-emissions-and-their-partitioning-to-the-carbon-reservoirs-of-atmosphere-ocean-and-land",
        "chapter_name": "overview-of-the-global-carbon-cycle",
        "report": "second-state-carbon-cycle-report-soccr2-sustained-assessment-report",
        "title": "Historic (a) and Decadal (b) Global Mean Emissions and Their Partitioning to the Carbon Reservoirs of Atmosphere, Ocean, and Land"
      },
      {
      ...
      }
    ]

