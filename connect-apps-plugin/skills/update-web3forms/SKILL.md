---
description: Update the Web3Forms access key in one or all HTML pages
---

The user wants to update the Web3Forms access key used for lead form submissions.

1. Search all `.html` files in the project for `<input type="hidden" name="access_key"` using Grep.
2. List every file that contains an access key and show the current key value.
3. Ask the user which file(s) to update and what the new access key should be (if not already provided).
4. Use the Edit tool to replace the old key value with the new one in each targeted file.
5. After all edits, summarise which files were updated and remind the user that the new key must be generated at web3forms.com and linked to the correct recipient email address.
