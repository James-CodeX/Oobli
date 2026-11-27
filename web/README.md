# Oobli website

Landing page, Terms and Privacy. Vite + React, three static pages.

```bash
npm install
npm run dev     # http://localhost:5173
npm test
npm run build   # → dist/
```

## Deploying

Appwrite Sites (site `oobli-web`) is connected to this repository and redeploys on every push to `main`. Its build settings must be:

| Setting | Value |
| --- | --- |
| Root directory | `./web` |
| Framework | Vite |
| Install command | `npm ci` |
| Build command | `npm run build` |
| Output directory | `./dist` |

Without the build command and output directory, Appwrite serves the unbuilt source and the page is blank.
