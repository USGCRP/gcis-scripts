# GCMD Keyword Updating

## Purpose

This script, when run, will update the GCMD keywords to the latest versions available
from GCMD's XML endpoint.

See the `example_gcmd.xml` for the output format the script expects.

See the logs folder for the previous updates' run logs.

## Examples

This script can be run in two distinct modes.

### Update in-place only

In this mode, the keywords will adopt new definitions
and labels based on the most up-to-date GCMD version.  
New keywords will be added.

```
./update_gcmd_keywords.pl \
  --url https://data-stage.globalchange.gov \
  --root "1eb0ea0a-312c-4d74-8d42-6f1ad758f999" \
  --data_only \
  --verbose >./log/YYYY_MM_DD_data_update.out
```

### Update and move

In this mode, the keywords will adopt new definitions
and labels based on the most up-to-date GCMD version.  
New keywords will be added.  
Keywords will have their parent reassigned to match GCMD.

```
./update_gcmd_keywords.pl \
  --url https://data-stage.globalchange.gov \
  --root "1eb0ea0a-312c-4d74-8d42-6f1ad758f999" \
  --verbose >./log/YYYY_MM_DD_update.out
```

### Testing Runs

Run with `--dry` to avoid any actual changes. The hidden argument
`--limit` will make the script only check that many UUIDs. The set of UUIDs
checked with --limit may vary, though it will always include the root UUID.

```
./update_gcmd_keywords.pl 
  --url https://data-stage.globalchange.gov 
  --root "1eb0ea0a-312c-4d74-8d42-6f1ad758f999" 
  --dry
  --limit 15
  --verbose
```

## Defunct Keywords

The script does not delete keywords. Instead it outputs the message:

> Checking keyword [UUID] -  ([label]) now defunct

The data manager takes this list and researches to confirm it is defunct, reassign any publications tied to that keyword, and then removes it.

TODO: Consider an active/inactive field, instead?

## GCMD Keyword Links

[Main Page](https://earthdata.nasa.gov/about/gcmd/global-change-master-directory-gcmd-keywords)

See the latest version of a keyword:  
Command line: `curl -k https://gcmd.nasa.gov/kms/concept/[UUID]?format=xml`  
Web: Go to `https://gcmd.nasa.gov/kms/concept/[UUID]?format=xml`, right click and 'View Page Source'  

# GCMD Keyword Import

This script can import new GCMD keyword sets, so long as they follow the XML format. As of 2018-03, they all seem to do so.

For example, to import the GCMD Locations keyword set:  
 
  - locate the top keyword's UUID: `713eb469-abe4-4b6b-bad6-134187deabd8`
  - dryrun the script with it:
    ```
    ./update_gcmd_keywords.pl 
      --url https://data-stage.globalchange.gov 
      --root "713eb469-abe4-4b6b-bad6-134187deabd8" 
      --dry
      --verbose
    ```
  - if all looks right, run without the `dry` flag to import them.
    ```
    ./update_gcmd_keywords.pl 
      --url https://data-stage.globalchange.gov 
      --root "713eb469-abe4-4b6b-bad6-134187deabd8" 
      --verbose >./log/YYYY_MM_DD_locations_import.out
    ```
