// Canonical category keys. Must stay in sync with lib/data/models/category.dart.
export const CATEGORIES = {
  groceries: 'Groceries (supermarkets, mama mboga, market produce)',
  food: 'Food & Dining (restaurants, cafes, takeaway, food delivery)',
  transport: 'Transport (matatu, Uber/Bolt, fuel, parking, Super Metro)',
  utilities: 'Utilities (KPLC tokens, water, internet, DSTV/GOtv, gas)',
  rent: 'Rent & Housing (rent, service charge, landlord)',
  shopping: 'Shopping (clothes, electronics, household goods, online stores)',
  entertainment: 'Entertainment (Netflix, Spotify, betting, events, games)',
  health: 'Health (pharmacy, hospital, clinic, insurance like NHIF/SHA)',
  education: 'Education (school fees, courses, books, HELB)',
  airtime: 'Airtime & Data (Safaricom airtime, bundles)',
  transfer: 'Sent to someone (person-to-person transfers with no clear purpose)',
  savings: 'Savings & Investments (M-Shwari deposit, M-Mali, MMF, SACCO, stocks)',
  debt: 'Debt & Loans (Fuliza, M-Shwari/KCB-M-Pesa loan repayment, Tala, Branch)',
  fees: 'Fees & Charges (transaction costs, bank charges, withdrawal fees)',
  income: 'Income (salary, money received, business sales, refunds)',
  bank_withdrawal: 'Bank withdrawal (money IN only: the user moving their own money from a bank account to M-Pesa, e.g. sender is Equity, KCB, Co-op Bank, NCBA, Absa, I&M, Stanbic, Family Bank, DTB)',
  other: 'Other (anything that clearly fits none of the above)',
};

export const CATEGORY_KEYS = Object.keys(CATEGORIES);

export const CHANNELS = [
  'pochi', 'till', 'paybill', 'send', 'withdraw', 'airtime',
  'deposit', 'received', 'bank', 'fuliza', 'card', 'other',
];

export function categoryGuide() {
  return Object.entries(CATEGORIES)
    .map(([key, description]) => `- ${key}: ${description}`)
    .join('\n');
}

// Categories that only make sense for money coming in.
export const RECEIVING_ONLY = ['income', 'bank_withdrawal'];
export const RECEIVING = [...RECEIVING_ONLY, 'savings', 'debt', 'transfer', 'other'];

export function normaliseCategory(value, fallback = 'other') {
  return CATEGORY_KEYS.includes(value) ? value : fallback;
}

/** Keeps a category consistent with the money's direction ("in" or "out"). */
export function categoryForDirection(value, direction) {
  const key = normaliseCategory(value);
  if (direction === 'in') return RECEIVING.includes(key) ? key : 'income';
  return RECEIVING_ONLY.includes(key) ? 'other' : key;
}
