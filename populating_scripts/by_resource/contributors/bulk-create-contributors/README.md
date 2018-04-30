# Bulk Create Contributors

## Purpose

Creates many contributors based on CSV input of contributor fields.

If the contributor already exists, nothing is changed.

## Use

```
./bulk-create-contributors.pl \
    --url "https://data-stage.globalchange.gov" \
    --input foo.csv \
    --output output_qa_file.csv \
    --verbose
```

## Input

CSV with the fields:

`doi person_id organization_id sort_key contributor_role`

## Output

CSV with the input fields and `contributor_existed`: `TRUE`/`FALSE` and `error` with any error message
