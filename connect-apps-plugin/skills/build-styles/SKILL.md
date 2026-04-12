---
description: Compile Tailwind CSS from input.css into the minified style.css
---

The user wants to build/rebuild the Tailwind CSS stylesheet.

1. Verify that `node_modules/.bin/tailwindcss` (or a global `tailwindcss`) is available by running `npx tailwindcss --version`.
2. If not installed, run `npm install -D tailwindcss` and wait for it to complete.
3. Run the build command:
   ```
   npx tailwindcss -i ./input.css -o ./style.css --minify
   ```
4. Report the exit code and any output from the command.
5. If the build succeeds, confirm the file size of `style.css` so the user can verify it is non-empty.
6. If `input.css` does not exist, inform the user and ask whether they want to create a minimal `input.css` with `@tailwind base; @tailwind components; @tailwind utilities;`.
