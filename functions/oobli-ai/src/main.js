import { createGemini, GeminiError } from './gemini.js';
import * as handlers from './handlers.js';

const ROUTES = {
  '/categorize': handlers.categorize,
  '/parse-sms': handlers.parseSms,
  '/insights': handlers.insights,
  '/plan': handlers.plan,
  '/wrapped': handlers.wrapped,
  '/chat': handlers.chat,
};

function models() {
  return [process.env.GEMINI_MODEL, process.env.GEMINI_FALLBACK_MODEL]
    .flatMap((m) => (m ?? '').split(','))
    .map((m) => m.trim())
    .filter(Boolean)
    .concat(['gemini-3.5-flash-lite', 'gemini-3.1-flash-lite'])
    .filter((m, i, all) => all.indexOf(m) === i);
}

// Appwrite Function entrypoint.
export default async ({ req, res, log, error }) => {
  if (req.method === 'GET' && (req.path === '/' || req.path === '/health')) {
    return res.json({ ok: true, routes: Object.keys(ROUTES) });
  }

  const handler = ROUTES[req.path];
  if (!handler) return res.json({ error: `Unknown route ${req.path}` }, 404);
  if (req.method !== 'POST') return res.json({ error: 'Use POST' }, 405);

  // Executions from the client SDK carry the caller's user id; reject anonymous calls.
  const userId = req.headers['x-appwrite-user-id'];
  if (!userId) return res.json({ error: 'Authentication required' }, 401);

  let body = req.bodyJson;
  if (!body || typeof body !== 'object') {
    try {
      body = JSON.parse(req.bodyText || '{}');
    } catch {
      return res.json({ error: 'Body must be JSON' }, 400);
    }
  }

  try {
    const gemini = createGemini({
      apiKey: process.env.GEMINI_API_KEY,
      models: models(),
      attemptTimeoutMs: Number(process.env.GEMINI_ATTEMPT_TIMEOUT_MS) || 12000,
      log,
    });
    const started = Date.now();
    const result = await handler(gemini, body);
    log(`${req.path} for ${userId} in ${Date.now() - started}ms`);
    return res.json(result);
  } catch (err) {
    if (err instanceof handlers.BadRequest) return res.json({ error: err.message }, 400);
    error(`${req.path} failed: ${err.stack ?? err.message}`);
    const status = err instanceof GeminiError && err.status === 504 ? 504 : 502;
    return res.json({ error: 'Oobli could not reach the AI service. Please try again.' }, status);
  }
};
