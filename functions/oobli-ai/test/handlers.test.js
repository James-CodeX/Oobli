import { test } from 'node:test';
import assert from 'node:assert/strict';

import { createGemini, extractText, parseJson } from '../src/gemini.js';
import { categorize, normaliseAllocations, BadRequest } from '../src/handlers.js';
import main from '../src/main.js';

function interaction(text) {
  return { steps: [{ type: 'thought' }, { type: 'model_output', content: [{ type: 'text', text }] }] };
}

function fakeFetch(responses) {
  const calls = [];
  const impl = async (url, init) => {
    calls.push(JSON.parse(init.body));
    const next = responses.shift();
    return { ok: next.status === 200, status: next.status, json: async () => next.body };
  };
  return { impl, calls };
}

test('extractText joins model_output text parts', () => {
  assert.equal(extractText(interaction('{"a":1}')), '{"a":1}');
});

test('parseJson tolerates fenced json', () => {
  assert.deepEqual(parseJson('```json\n{"a":1}\n```'), { a: 1 });
});

test('normaliseAllocations sums to exactly 100% and computes amounts', () => {
  const rows = normaliseAllocations([
    { key: 'needs', percent: 33, reason: 'r' },
    { key: 'savings', percent: 33, reason: 'r' },
    { key: 'flex', percent: 33, reason: 'r' },
  ], 85000);
  assert.equal(rows.length, 4);
  assert.equal(rows.reduce((s, r) => s + r.percent, 0), 100);
  const needs = rows.find((r) => r.key === 'needs');
  assert.equal(needs.amount, Math.round((85000 * needs.percent) / 100));
});

test('gemini falls back to the next model on 503', async () => {
  const { impl, calls } = fakeFetch([
    { status: 503, body: { error: { message: 'busy' } } },
    { status: 200, body: interaction('{"results":[{"id":"1","category":"groceries","merchant":"Naivas","confidence":0.9}]}') },
  ]);
  const gemini = createGemini({ apiKey: 'k', models: ['a', 'b'], fetchImpl: impl });
  const out = await categorize(gemini, { items: [{ id: '1', merchant: 'NAIVAS WESTLANDS', channel: 'till', amount: 100 }] });
  assert.deepEqual(calls.map((c) => c.model), ['a', 'b']);
  assert.equal(out.results[0].category, 'groceries');
});

test('categorize drops unknown ids and normalises categories', async () => {
  const { impl } = fakeFetch([{
    status: 200,
    body: interaction('{"results":[{"id":"x","category":"groceries","merchant":"m","confidence":1},{"id":"1","category":"nope","merchant":"m","confidence":2}]}'),
  }]);
  const gemini = createGemini({ apiKey: 'k', models: ['a'], fetchImpl: impl });
  const out = await categorize(gemini, { items: [{ id: '1', merchant: 'm', channel: 'till', amount: 1 }] });
  assert.equal(out.results.length, 1);
  assert.equal(out.results[0].category, 'other');
  assert.equal(out.results[0].confidence, 1);
});

test('categorize rejects empty batches', async () => {
  const gemini = createGemini({ apiKey: 'k', models: ['a'], fetchImpl: async () => ({}) });
  await assert.rejects(categorize(gemini, { items: [] }), BadRequest);
});

test('main rejects anonymous executions', async () => {
  let sent;
  const res = { json: (body, status = 200) => { sent = { body, status }; return sent; } };
  await main({ req: { method: 'POST', path: '/chat', headers: {}, bodyJson: {} }, res, log() {}, error() {} });
  assert.equal(sent.status, 401);
});

test('categorize keeps categories consistent with direction', async () => {
  const { impl } = fakeFetch([{
    status: 200,
    body: interaction('{"results":[' +
      '{"id":"1","category":"bank_withdrawal","merchant":"Equity Bank","confidence":0.9},' +
      '{"id":"2","category":"groceries","merchant":"Acme","confidence":0.9},' +
      '{"id":"3","category":"income","merchant":"Naivas","confidence":0.9}]}'),
  }]);
  const gemini = createGemini({ apiKey: 'k', models: ['a'], fetchImpl: impl });
  const out = await categorize(gemini, {
    items: [
      { id: '1', merchant: 'EQUITY BANK', channel: 'received', direction: 'in', amount: 5000 },
      { id: '2', merchant: 'ACME', channel: 'received', direction: 'in', amount: 900 },
      { id: '3', merchant: 'NAIVAS', channel: 'till', direction: 'out', amount: 300 },
    ],
  });
  const byId = Object.fromEntries(out.results.map((r) => [r.id, r.category]));
  assert.deepEqual(byId, { 1: 'bank_withdrawal', 2: 'income', 3: 'other' });
});
