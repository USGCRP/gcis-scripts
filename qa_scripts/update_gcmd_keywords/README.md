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

./update_gcmd_keywords.pl \
  --url https://data-stage.globalchange.gov \
  --root "1eb0ea0a-312c-4d74-8d42-6f1ad758f999" \
  --data_only \
  --verbose >./log/YYYY_MM_DD_data_update.out

### Update and move

In this mode, the keywords will adopt new definitions
and labels based on the most up-to-date GCMD version.  
New keywords will be added.  
Keywords will have their parent reassigned to match GCMD.

./update_gcmd_keywords.pl \
  --url https://data-stage.globalchange.gov \
  --root "1eb0ea0a-312c-4d74-8d42-6f1ad758f999" \
  --verbose >./log/YYYY_MM_DD_update.out

### Testing Runs

Run with `--dry` to avoid any actual changes. The hidden argument
`--limit` will make the script only check that many UUIDs. The set of UUIDs
checked with --limit may vary, though it will always include the root UUID.

./update_gcmd_keywords.pl 
  --url https://data-stage.globalchange.gov 
  --root "1eb0ea0a-312c-4d74-8d42-6f1ad758f999" 
  --dry
  --limit 15
  --verbose

## GCMD Keyword Links

[Main Page](https://earthdata.nasa.gov/about/gcmd/global-change-master-directory-gcmd-keywords)

See the latest version of a keyword:  
Command line: `curl -k https://gcmd.nasa.gov/kms/concept/[UUID]?format=xml`  
Web: Go to `https://gcmd.nasa.gov/kms/concept/[UUID]?format=xml`, right click and 'View Page Source'  


