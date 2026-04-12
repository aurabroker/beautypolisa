---
description: Update the insurance pricing table (PRICING constant) in bp-app.js
---

The user wants to change the premium rates in the `PRICING` object inside `bp-app.js`.

Context:
- `PRICING` maps tariff group (1–4) to an object with keys `s100`, `s200`, `s300` representing the annual premium for sum-insured variants 100k, 200k, 300k PLN.
- The object is located after the `/* ── TARIFFS ──` comment in `bp-app.js`.

Steps:
1. Read `bp-app.js` and display the current `PRICING` object to the user.
2. Ask which tariff group(s) and/or sum-insured variant(s) the user wants to change, and what the new values should be (if not already provided).
3. Validate that all new values are positive integers.
4. Apply the changes using the Edit tool, preserving the existing code style.
5. After editing, read back the updated `PRICING` block and confirm the new values with the user.
