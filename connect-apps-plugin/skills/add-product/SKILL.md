---
description: Add a new product tab to the BeautyPolisa navigation bar in bp-nav.js
---

The user wants to add a new insurance product to the `PRODUCTS` array in `bp-nav.js`.

Context:
- The `PRODUCTS` array in `bp-nav.js` defines the navigation tabs shown in the shared header.
- Each entry has: `id` (unique string), `href` (page filename or `"#"` if not yet live), `icon` (single emoji), `name` (short display name), `title` (full tooltip text).

Steps:
1. Read `bp-nav.js` and display the current `PRODUCTS` array.
2. Ask the user for the five required fields (`id`, `href`, `icon`, `name`, `title`) if not already provided.
3. Confirm that the `id` is not already used in the array.
4. Insert the new product entry at the position the user specifies (default: end of the array) using the Edit tool.
5. If `href` points to a new `.html` file that doesn't exist yet, note this and ask if the user wants a stub page created.
6. After editing, confirm the updated `PRODUCTS` array with the user.
