// Thin client for the Gemini Interactions API (REST), with model fallback,
// per-attempt timeouts and retries on transient errors (429 / 5xx).

const ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/interactions';
const API_REVISION = '2026-05-20';

export class GeminiError extends Error {
  constructor(message, status) {
    super(message);
    this.name = 'GeminiError';
    this.status = status;
  }
}

export function createGemini({
  apiKey,
  models,
  attemptTimeoutMs = 12000,
  fetchImpl = globalThis.fetch,
  log = () => {},
}) {
  if (!apiKey) throw new GeminiError('GEMINI_API_KEY is not configured', 500);
  if (!models?.length) throw new GeminiError('No Gemini models configured', 500);

  async function callOnce(model, body) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), attemptTimeoutMs);
    try {
      const response = await fetchImpl(ENDPOINT, {
        method: 'POST',
        signal: controller.signal,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
          'Api-Revision': API_REVISION,
        },
        body: JSON.stringify({ model, store: false, ...body }),
      });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) {
        const message = payload?.error?.message ?? `HTTP ${response.status}`;
        throw new GeminiError(message, response.status);
      }
      return extractText(payload);
    } catch (err) {
      if (err.name === 'AbortError') {
        throw new GeminiError(`Timed out after ${attemptTimeoutMs}ms`, 504);
      }
      throw err;
    } finally {
      clearTimeout(timer);
    }
  }

  async function generate({ system, input, schema }) {
    const body = { system_instruction: system, input };
    if (schema) {
      body.response_format = { type: 'text', mime_type: 'application/json', schema };
    }

    let lastError;
    for (const model of models) {
      try {
        const text = await callOnce(model, body);
        if (!schema) return text;
        return parseJson(text);
      } catch (err) {
        lastError = err;
        const retriable = !(err instanceof GeminiError) || err.status === 429 || err.status >= 500;
        log(`Gemini model ${model} failed (${err.status ?? 'n/a'}): ${err.message}`);
        if (!retriable) break;
      }
    }
    throw lastError ?? new GeminiError('All Gemini models failed', 502);
  }

  return { generate };
}

export function extractText(interaction) {
  const parts = [];
  for (const step of interaction?.steps ?? []) {
    if (step.type !== 'model_output') continue;
    for (const content of step.content ?? []) {
      if (content.type === 'text' && typeof content.text === 'string') parts.push(content.text);
    }
  }
  const text = parts.join('').trim();
  if (!text) throw new GeminiError('Gemini returned an empty response', 502);
  return text;
}

export function parseJson(text) {
  const cleaned = text.replace(/^```(?:json)?\s*/i, '').replace(/```\s*$/, '').trim();
  try {
    return JSON.parse(cleaned);
  } catch {
    throw new GeminiError('Gemini returned malformed JSON', 502);
  }
}
