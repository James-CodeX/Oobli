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
| Runtime | Node.js 22 (`node-22`) |
| Install command | `npm ci` |
| Build command | `npm run build` |
| Output directory | `./dist` |

With a static runtime (`static-1`) there is no Node.js: builds fail with `npm: command not found`, or, without a build command, Appwrite serves the unbuilt source and the page is blank.
