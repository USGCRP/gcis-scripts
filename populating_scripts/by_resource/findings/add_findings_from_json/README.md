# Add Findings From JSON

## Use Case

When producing a GCIS Assessment Report, TSU develops the "Key Findings" or
"Key Messages" on a chapter by chapter basis. Once they're ready we import
them into GCIS with this script.

## Usage

### Prereqs

[GCIS Perl Client](https://github.com/USGCRP/gcis-pl-client)  
[GCIS API credentials](https://github.com/USGCRP/gcis-pl-client#configuration)

### Showtime 

Run against a test instance of with dry run on first.

Updated Findings can be imported with the `--update`
flag.

Exmaple Run:

    ./add_findings_from_json.pl \
      --url https://data-stage.globalchange.gov \
      --file chapter_5_kf.json \
      --update

### Expected format

    {
      "chapter": 5,
      "process": "<p>This is a process.</p><p>This is a cite {{< tbib '6' '3ff0e30a-c5ee-4ed9-8034-288be428125b' >}} and emphasis: <em>Climate Science Special Report</em>.</p>",
      "kf": [
        {
          "identifier": "key-message-5-1",
          "ordinal": 1,
          "statement":  "<p>this is a statement</p>",
          "evidence": "<p>evidence with cites {{< tbib '37' 'd9661451-b35d-4e0c-9551-cbc60c45c5ef' >}}<sup class='cm'>,</sup>{{<tbib '38' 'd1069afd-d9c4-4cc1-bd29-c50f637502bd' >}}</p>",
          "uncertainties": "<p>There is uncertainty </p>",
          "confidence": "<p>Increasing temperature is <em>highly likely</em> to result in early snowmelt and increased consumptive use.</p>"
        },
        {
          "identifier": "key-message-5-2",
          "ordinal": 2,
          "statement":  "<p>this is another statement</p>",
          "evidence": "<p>evidence with cites {{< tbib '37' 'd9661451-b35d-4e0c-9551-cbc60c45c5ef' >}}<sup class='cm'>,</sup>{{<tbib '38' 'd1069afd-d9c4-4cc1-bd29-c50f637502bd' >}}</p>",
          "uncertainties": "<p>There is uncertainty </p>",
          "confidence": "<p>Increasing temperature is <em>highly likely</em> to result in early snowmelt and increased consumptive use.</p>"
        }
      ]
    }
