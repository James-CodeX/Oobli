import {
  CATEGORIES,
  CATEGORY_KEYS,
  CHANNELS,
  categoryGuide,
  normaliseCategory,
  categoryForDirection,
} from './categories.js';

export class BadRequest extends Error {
  constructor(message) {
    super(message);
    this.name = 'BadRequest';
    this.status = 400;
  }
}

const PERSONA = `You are Oobli, a warm, upbeat and concise AI money companion for people in Kenya.
You understand M-Pesa (Pochi la Biashara, Buy Goods tills, Paybills, Send Money, Fuliza, M-Shwari, M-Mali)
and Kenyan bank alerts. Amounts are in Kenyan Shillings (KES). Speak plainly, like a friendly coach:
short sentences, no jargon, no markdown, no emojis unless asked. Never invent numbers that are not in the data.
Always write money as "KES" followed by the amount with thousands separators and no decimals, e.g. KES 18,000.`;

const MAX_BATCH = 60;
const MAX_SMS = 40;
const MAX_TEXT = 600;

// ---------- helpers ----------

function requireArray(value, name, max) {
  if (!Array.isArray(value) || value.length === 0) throw new BadRequest(`"${name}" must be a non-empty array`);
  if (value.length > max) throw new BadRequest(`"${name}" accepts at most ${max} items`);
  return value;
}

function clip(value, max = MAX_TEXT) {
  return String(value ?? '').slice(0, max);
}

function num(value, fallback = 0) {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function compact(obj) {
  return JSON.stringify(obj, null, 0);
}

// ---------- /categorize ----------

export async function categorize(gemini, body) {
  const items = requireArray(body.items, 'items', MAX_BATCH).map((item) => ({
    id: clip(item.id, 64),
    merchant: clip(item.merchant, 160),
    channel: clip(item.channel, 16),
    direction: item.direction === 'in' ? 'in' : 'out',
    amount: num(item.amount),
    raw: item.raw ? clip(item.raw, 320) : undefined,
  }));
  const rules = Array.isArray(body.rules) ? body.rules.slice(0, 40) : [];

  const input = `Categorise each transaction into exactly one category key.

Category keys:
${categoryGuide()}

Rules:
- Incoming money (direction "in") can only be: "income", "bank_withdrawal", "own_transfer", "debt" (loan disbursement), "savings" (savings withdrawal), "transfer" or "other".
- Outgoing money to a bank paybill (Equity, KCB, Co-op...) is usually the user depositing to their own account: "own_transfer" (confidence < 0.7), unless it is clearly a loan repayment ("debt").
- Incoming money from a bank (bank name, "Bank", Pesalink) is "bank_withdrawal": the user moved their own money, it is NOT income.
- Bank "bulk"/B2C accounts are ambiguous: employers pay salaries through them. A large, round, month-start amount is likely "income"; otherwise "bank_withdrawal". Use confidence < 0.6 when unsure.
- "income" and "bank_withdrawal" are never valid for outgoing money (direction "out").
- Pochi la Biashara and tills to small traders selling food produce are usually "groceries".
- "send" to a person's name with no other signal is "transfer".
- Also return a clean, human-friendly merchant name (Title Case, no phone numbers or account numbers).
- confidence is 0..1; use < 0.6 when you are guessing.

The user has corrected these merchants before. Always follow them:
${rules.length ? rules.map((r) => `- "${clip(r.merchant, 160)}" => ${clip(r.category, 24)}`).join('\n') : '- (none)'}

Transactions (JSON):
${compact(items)}`;

  const result = await gemini.generate({
    system: PERSONA,
    input,
    schema: {
      type: 'object',
      properties: {
        results: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              category: { type: 'string', enum: CATEGORY_KEYS },
              merchant: { type: 'string' },
              confidence: { type: 'number' },
            },
            required: ['id', 'category', 'merchant', 'confidence'],
          },
        },
      },
      required: ['results'],
    },
  });

  const ids = new Set(items.map((i) => i.id));
  return {
    results: (result.results ?? [])
      .filter((r) => ids.has(r.id))
      .map((r) => ({
        id: r.id,
        category: categoryForDirection(r.category, items.find((i) => i.id === r.id)?.direction),
        merchant: clip(r.merchant, 160) || items.find((i) => i.id === r.id)?.merchant,
        confidence: Math.max(0, Math.min(1, num(r.confidence, 0.5))),
      })),
  };
}

// ---------- /parse-sms ----------

export async function parseSms(gemini, body) {
  const messages = requireArray(body.messages, 'messages', MAX_SMS).map((m) => ({
    id: clip(m.id, 64),
    sender: clip(m.sender, 40),
    body: clip(m.body, 640),
    receivedAt: clip(m.receivedAt, 40),
  }));

  const input = `Extract financial transactions from these Kenyan SMS alerts (M-Pesa and banks).
For each message decide if it records a completed money movement for the account owner.
Ignore OTPs, promotions, failed transactions, balance enquiries and loan offers (isTransaction=false).
- amount: positive number in KES (no fees).
- direction: "out" for money leaving the account owner, "in" for money received.
- merchant: who was paid or who paid (clean name).
- channel: one of ${CHANNELS.join(', ')}.
- reference: transaction code if present, else empty string.
- balance: account balance after the transaction if stated, else -1.
- occurredAt: ISO-8601 datetime in Africa/Nairobi (+03:00). Use receivedAt if the SMS has no date.
- category: best category key from:
${categoryGuide()}

Messages (JSON):
${compact(messages)}`;

  const result = await gemini.generate({
    system: PERSONA,
    input,
    schema: {
      type: 'object',
      properties: {
        transactions: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              isTransaction: { type: 'boolean' },
              amount: { type: 'number' },
              direction: { type: 'string', enum: ['in', 'out'] },
              merchant: { type: 'string' },
              channel: { type: 'string', enum: CHANNELS },
              reference: { type: 'string' },
              balance: { type: 'number' },
              occurredAt: { type: 'string' },
              category: { type: 'string', enum: CATEGORY_KEYS },
            },
            required: ['id', 'isTransaction'],
          },
        },
      },
      required: ['transactions'],
    },
  });

  const ids = new Set(messages.map((m) => m.id));
  return {
    transactions: (result.transactions ?? [])
      .filter((t) => ids.has(t.id))
      .map((t) => ({
        id: t.id,
        isTransaction: Boolean(t.isTransaction) && num(t.amount) > 0,
        amount: num(t.amount),
        direction: t.direction === 'in' ? 'in' : 'out',
        merchant: clip(t.merchant, 160),
        channel: CHANNELS.includes(t.channel) ? t.channel : 'other',
        reference: clip(t.reference, 40),
        balance: num(t.balance, -1),
        occurredAt: clip(t.occurredAt, 40),
        category: categoryForDirection(t.category, t.direction === 'in' ? 'in' : 'out'),
      })),
  };
}

// ---------- /insights ----------

export async function insights(gemini, body) {
  const stats = body.stats;
  if (!stats || typeof stats !== 'object') throw new BadRequest('"stats" is required');

  const input = `Here is a summary of the user's recent money activity (JSON, KES):
${clip(compact(stats), 6000)}

Write short, specific, data-backed insights for different screens of the app:
- headline: one sentence for the home screen, max 60 characters (e.g. "Your spending is 12% lower than last Tuesday").
- cards: exactly 2 insight cards for the home feed. title max 3 words. body max 140 characters.
  tone is "warning" for something to act on (subscriptions, overspending), "primary" for patterns, "success" for wins, "info" otherwise.
- activityNote: one sentence for the transactions screen comparing spending with the plan or last week.
- analyticsNote: 1-2 sentences for the analytics screen about channel spending (Paybill, Tills, Pochi).
- suggestion: if a large share of "transfer" or Pochi spending goes to one recipient that looks like a trader
  (e.g. a mama mboga, a shop), suggest a better category. Otherwise set merchant to "".
- goalNote: one encouraging sentence about the primary savings goal if present, else "".
Only use facts in the data.`;

  const result = await gemini.generate({
    system: PERSONA,
    input,
    schema: {
      type: 'object',
      properties: {
        headline: { type: 'string' },
        cards: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              title: { type: 'string' },
              body: { type: 'string' },
              tone: { type: 'string', enum: ['warning', 'primary', 'success', 'info'] },
            },
            required: ['title', 'body', 'tone'],
          },
        },
        activityNote: { type: 'string' },
        analyticsNote: { type: 'string' },
        suggestion: {
          type: 'object',
          properties: {
            merchant: { type: 'string' },
            fromCategory: { type: 'string', enum: CATEGORY_KEYS },
            toCategory: { type: 'string', enum: CATEGORY_KEYS },
            body: { type: 'string' },
          },
          required: ['merchant', 'fromCategory', 'toCategory', 'body'],
        },
        goalNote: { type: 'string' },
      },
      required: ['headline', 'cards', 'activityNote', 'analyticsNote', 'suggestion', 'goalNote'],
    },
  });

  return {
    headline: clip(result.headline, 120),
    cards: (result.cards ?? []).slice(0, 2).map((c) => ({
      title: clip(c.title, 40),
      body: clip(c.body, 220),
      tone: c.tone,
    })),
    activityNote: clip(result.activityNote, 220),
    analyticsNote: clip(result.analyticsNote, 320),
    suggestion: result.suggestion?.merchant ? {
      merchant: clip(result.suggestion.merchant, 160),
      fromCategory: normaliseCategory(result.suggestion.fromCategory),
      toCategory: normaliseCategory(result.suggestion.toCategory),
      body: clip(result.suggestion.body, 320),
    } : null,
    goalNote: clip(result.goalNote, 220),
  };
}

// ---------- /plan ----------

const PLAN_BUCKETS = [
  { key: 'needs', label: 'Fixed Needs' },
  { key: 'savings', label: 'Savings Goal' },
  { key: 'flex', label: 'Flex Spending' },
  { key: 'emergency', label: 'Emergency' },
];

export async function plan(gemini, body) {
  const income = num(body.income);
  if (income <= 0) throw new BadRequest('"income" must be a positive number');
  const goal = clip(body.goal, 200);
  const focus = clip(body.focus, 40);
  const month = clip(body.month, 20);

  const input = `Draft a monthly spending plan.
Month: ${month}
Anticipated income: KES ${income}
Main goal: ${goal || '(not specified)'}
Focus: ${focus || 'just tracking'}
Spending history (JSON, KES): ${clip(compact(body.history ?? {}), 4000)}

Split income into exactly these buckets: ${PLAN_BUCKETS.map((b) => `${b.key} (${b.label})`).join(', ')}.
- percent values are whole numbers summing to 100.
- reason: max 90 characters, grounded in their history (e.g. "Rent, Utilities & Internet based on last month's Paybills.").
- If focus is debt, use savings for debt repayment and say so in the reason.
- summary: one sentence explaining the plan.`;

  const result = await gemini.generate({
    system: PERSONA,
    input,
    schema: {
      type: 'object',
      properties: {
        summary: { type: 'string' },
        allocations: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              key: { type: 'string', enum: PLAN_BUCKETS.map((b) => b.key) },
              percent: { type: 'number' },
              reason: { type: 'string' },
            },
            required: ['key', 'percent', 'reason'],
          },
        },
      },
      required: ['summary', 'allocations'],
    },
  });

  return { summary: clip(result.summary, 240), allocations: normaliseAllocations(result.allocations, income) };
}

export function normaliseAllocations(raw, income) {
  const defaults = { needs: 50, savings: 20, flex: 20, emergency: 10 };
  const byKey = new Map((raw ?? []).map((a) => [a.key, a]));
  const rows = PLAN_BUCKETS.map((b) => ({
    key: b.key,
    label: b.label,
    percent: Math.max(0, num(byKey.get(b.key)?.percent, defaults[b.key])),
    reason: clip(byKey.get(b.key)?.reason, 140),
  }));

  const total = rows.reduce((s, r) => s + r.percent, 0) || 100;
  rows.forEach((r) => { r.percent = Math.round((r.percent / total) * 100); });
  // Push any rounding drift into the largest bucket so the plan sums to exactly 100%.
  const drift = 100 - rows.reduce((s, r) => s + r.percent, 0);
  rows.reduce((a, b) => (b.percent > a.percent ? b : a)).percent += drift;

  return rows.map((r) => ({ ...r, amount: Math.round((income * r.percent) / 100) }));
}

// ---------- /wrapped ----------

export async function wrapped(gemini, body) {
  const stats = body.stats;
  if (!stats || typeof stats !== 'object') throw new BadRequest('"stats" is required');

  const input = `Create a fun "Oobli Wrapped" monthly recap from this data (JSON, KES):
${clip(compact(stats), 5000)}

- insight: 1-2 sentences about an interesting pattern (e.g. a weekday peak, AI re-categorisations).
- badges: 1-3 short earned titles (max 3 words) each with an icon key from: saver, power, streak, star, shield, trend.
- win: a positive comparison vs the previous month (title max 3 words, body max 110 characters).
  If nothing improved, celebrate consistency instead.`;

  const result = await gemini.generate({
    system: PERSONA,
    input,
    schema: {
      type: 'object',
      properties: {
        insight: { type: 'string' },
        badges: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              label: { type: 'string' },
              icon: { type: 'string', enum: ['saver', 'power', 'streak', 'star', 'shield', 'trend'] },
            },
            required: ['label', 'icon'],
          },
        },
        win: {
          type: 'object',
          properties: { title: { type: 'string' }, body: { type: 'string' } },
          required: ['title', 'body'],
        },
      },
      required: ['insight', 'badges', 'win'],
    },
  });

  return {
    insight: clip(result.insight, 320),
    badges: (result.badges ?? []).slice(0, 3).map((b) => ({ label: clip(b.label, 32), icon: b.icon })),
    win: { title: clip(result.win?.title, 40), body: clip(result.win?.body, 200) },
  };
}

// ---------- /chat ----------

export async function chat(gemini, body) {
  const messages = requireArray(body.messages, 'messages', 30)
    .map((m) => ({ role: m.role === 'model' ? 'model' : 'user', text: clip(m.text, 1200) }))
    .filter((m) => m.text);
  if (!messages.length || messages.at(-1).role !== 'user') {
    throw new BadRequest('The last message must be from the user');
  }

  const transcript = messages
    .map((m) => `${m.role === 'user' ? 'User' : 'Oobli'}: ${m.text}`)
    .join('\n');

  const input = `The user's financial context (JSON, KES):
${clip(compact(body.context ?? {}), 5000)}

Conversation so far:
${transcript}

Reply as Oobli to the user's last message in at most 90 words. Use the context for specific numbers.
If they ask for something outside personal finance, gently steer back.`;

  const reply = await gemini.generate({ system: PERSONA, input });
  return { reply: clip(reply, 1500) };
}

// ---------- /similar ----------

/** Which candidate merchants belong in the same category as the example. */
export async function similar(gemini, body) {
  const merchant = clip(body.merchant, 160);
  if (!merchant) throw new BadRequest('"merchant" is required');
  const category = normaliseCategory(body.category, '');
  if (!category) throw new BadRequest('"category" must be a category key');
  const candidates = [...new Set(requireArray(body.candidates, 'candidates', 80).map((c) => clip(c, 120)).filter(Boolean))];

  const input = `The user just filed "${merchant}" under "${category}" (${CATEGORIES[category]}).

From the merchant names below, pick ONLY the ones that are the same kind of business or payee and clearly belong in "${category}" too
(for example other branches of the same chain, other matatu SACCOs, other pharmacies). When unsure, leave it out.
People's personal names only match if the example is also a person and the category is about people.

Candidates (JSON):
${compact(candidates)}`;

  const result = await gemini.generate({
    system: PERSONA,
    input,
    schema: {
      type: 'object',
      properties: { matches: { type: 'array', items: { type: 'string' } } },
      required: ['matches'],
    },
  });
  const allowed = new Set(candidates);
  return { matches: (result.matches ?? []).filter((m) => allowed.has(m)) };
}

// ---------- /search ----------

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

/** Turns a plain-English question into transaction filters. */
export async function search(gemini, body) {
  const query = clip(body.query, 200);
  if (!query) throw new BadRequest('"query" is required');
  const today = ISO_DATE.test(body.today ?? '') ? body.today : new Date().toISOString().slice(0, 10);

  const input = `Today is ${today}. Convert the user's search over their M-Pesa transactions into filters.

Category keys:
${categoryGuide()}

Rules:
- from is inclusive, to is EXCLUSIVE, both YYYY-MM-DD, or "" when the search has no time limit. "last month" = the whole previous calendar month. Weeks start on Monday.
- Map everyday words to categories (boda, matatu, fare, fuel -> transport; lunch -> food; KPLC, tokens -> utilities; Netflix -> entertainment).
- terms are lowercase words to find in merchant names (e.g. "naivas", "pius"). Do not repeat words already captured by a category or date.
- direction: "out" for spending, "in" for money received, "any" otherwise.
- minAmount / maxAmount in KES, 0 when not given.
- label: a short human summary like "Transport · October".

Search: ${JSON.stringify(query)}`;

  const result = await gemini.generate({
    system: PERSONA,
    input,
    schema: {
      type: 'object',
      properties: {
        from: { type: 'string' },
        to: { type: 'string' },
        categories: { type: 'array', items: { type: 'string', enum: CATEGORY_KEYS } },
        terms: { type: 'array', items: { type: 'string' } },
        direction: { type: 'string', enum: ['in', 'out', 'any'] },
        minAmount: { type: 'number' },
        maxAmount: { type: 'number' },
        label: { type: 'string' },
      },
      required: ['from', 'to', 'categories', 'terms', 'direction', 'minAmount', 'maxAmount', 'label'],
    },
  });

  const date = (v) => (ISO_DATE.test(v ?? '') ? v : '');
  return {
    from: date(result.from),
    to: date(result.to),
    categories: (result.categories ?? []).filter((c) => CATEGORY_KEYS.includes(c)),
    terms: (result.terms ?? []).map((t) => clip(String(t).toLowerCase(), 40)).filter(Boolean).slice(0, 6),
    direction: ['in', 'out'].includes(result.direction) ? result.direction : 'any',
    minAmount: Math.max(0, num(result.minAmount)),
    maxAmount: Math.max(0, num(result.maxAmount)),
    label: clip(result.label, 80) || query,
  };
}
