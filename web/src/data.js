// Content shared by the landing page sections. Keys mirror the app's categories.
export const CATEGORIES = [
  { key: 'groceries', label: 'Groceries', emoji: '🛒', color: '#58CC02', examples: 'Naivas, Carrefour, Mama Mboga' },
  { key: 'food', label: 'Food & Dining', emoji: '🍛', color: '#FF9600', examples: 'Java House, KFC, kibandaski' },
  { key: 'transport', label: 'Transport', emoji: '🚌', color: '#1CB0F6', examples: 'Super Metro, Uber, Bolt, Shell' },
  { key: 'utilities', label: 'Utilities', emoji: '⚡', color: '#FFC800', examples: 'KPLC tokens, Nairobi Water, Zuku' },
  { key: 'rent', label: 'Rent & Housing', emoji: '🏠', color: '#58CC02', examples: 'Rent, service charge' },
  { key: 'shopping', label: 'Shopping', emoji: '🛍️', color: '#CE82FF', examples: 'Jumia, Kilimall, Hotpoint' },
  { key: 'entertainment', label: 'Entertainment', emoji: '🎬', color: '#FF4B4B', examples: 'Netflix, Showmax, Spotify' },
  { key: 'health', label: 'Health', emoji: '💊', color: '#FF4B4B', examples: 'Goodlife Pharmacy, clinics, SHA' },
  { key: 'airtime', label: 'Airtime & Data', emoji: '📱', color: '#1CB0F6', examples: 'Safaricom airtime & bundles' },
  { key: 'transfer', label: 'Sent to someone', emoji: '👤', color: '#FF9600', examples: 'Send Money to friends & family' },
  { key: 'savings', label: 'Savings', emoji: '🐷', color: '#58CC02', examples: 'M-Shwari, Ziidi, MMF, SACCO' },
  { key: 'debt', label: 'Debt & Loans', emoji: '🔥', color: '#FF4B4B', examples: 'Fuliza, KCB M-Pesa, Tala' },
  { key: 'bank_withdrawal', label: 'Bank withdrawal', emoji: '🏦', color: '#1CB0F6', examples: 'Equity, KCB, Co-op → M-Pesa' },
];

export const byKey = Object.fromEntries(CATEGORIES.map((c) => [c.key, c]));

// Sample messages for the one-tap sorting demo.
export const DEMO_SMS = [
  { code: 'TKL4QX81AB', amount: 4250, who: 'NAIVAS WESTLANDS', kind: 'paid to', answer: 'groceries', guess: 'groceries' },
  { code: 'TKM2HD90ZP', amount: 250, who: 'PIUS KINUTHIA', kind: 'sent to', answer: 'transport', guess: 'transfer' },
  { code: 'TKN7RT55LC', amount: 1100, who: 'NETFLIX', kind: 'paid to', answer: 'entertainment', guess: 'entertainment' },
  { code: 'TKP1VB22QE', amount: 5000, who: 'EQUITY BANK', kind: 'received from', answer: 'bank_withdrawal', guess: 'bank_withdrawal' },
  { code: 'TKQ9WS13MJ', amount: 1000, who: 'KPLC PREPAID', kind: 'sent to', answer: 'utilities', guess: 'utilities' },
];

export const INSIGHTS = [
  "You've spent 15% less on transport this week. Super Metro streak! 🚌",
  'Heads up: Netflix renews tomorrow — KES 1,100.',
  'You usually spend KES 800 at Pochi la Biashara on Wednesdays.',
  'KES 5,000 from Equity is your own money, so it is not counted as income. 🏦',
  "Only KES 3,400 to go for your Coast Trip goal! 🏖️",
];

export const PLAN_SPLIT = [
  { key: 'needs', label: 'Needs', pct: 50, color: '#1CB0F6', note: 'Rent, KPLC, food, fare' },
  { key: 'savings', label: 'Savings', pct: 20, color: '#58CC02', note: 'Goals and M-Shwari' },
  { key: 'flex', label: 'Flex', pct: 20, color: '#FF9600', note: 'Eating out, fun' },
  { key: 'emergency', label: 'Emergency', pct: 10, color: '#CE82FF', note: 'Your safety net' },
];

export const kes = (n) => `KES ${Math.round(n).toLocaleString('en-KE')}`;
