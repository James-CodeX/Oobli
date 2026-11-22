import { act, fireEvent, render, screen, within } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { App } from '../App.jsx';
import { LegalPage } from '../components/LegalPage.jsx';
import { DEMO_SMS } from '../data.js';
import { QuickSortDemo } from '../sections/QuickSortDemo.jsx';
import { PlanSlider } from '../sections/PlanSlider.jsx';

describe('landing page', () => {
  it('renders every section and links to the legal pages', () => {
    render(<App />);
    expect(screen.getByRole('heading', { level: 1 }).textContent).toMatch(/M-Pesa money/);
    for (const title of ['reads your m-pesa for you', 'sort anything in one tap', 'plans that fit your pay', 'OOBLI WRAPPED', 'private by design']) {
      expect(screen.getByRole('heading', { name: title })).toBeTruthy();
    }
    const footer = screen.getByRole('contentinfo');
    expect(within(footer).getByRole('link', { name: 'Terms of Service' }).getAttribute('href')).toBe('/terms/');
    expect(within(footer).getByRole('link', { name: 'Privacy Policy' }).getAttribute('href')).toBe('/privacy/');
  });

  it('shows example merchants when a category is tapped', () => {
    render(<App />);
    fireEvent.click(screen.getByRole('button', { name: /Bank withdrawal/i, pressed: false }));
    expect(screen.getByText(/Equity, KCB, Co-op/)).toBeTruthy();
  });
});

const LABELS = { groceries: 'Groceries', transport: 'Transport', entertainment: 'Entertainment', bank_withdrawal: 'Bank withdrawal', utilities: 'Utilities' };
const tap = (key) => {
  fireEvent.click(screen.getByRole('button', { name: new RegExp(`^\\S+\\s*${LABELS[key]}$`) }));
  act(() => vi.advanceTimersByTime(400));
};

describe('quick sort demo', () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it('files each transaction with one tap and celebrates at the end', () => {
    render(<QuickSortDemo />);
    expect(screen.getByText(`${DEMO_SMS.length} left`)).toBeTruthy();
    for (const tx of DEMO_SMS) tap(tx.answer);
    expect(screen.getByText(/All sorted in 5 taps/)).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: 'Try again' }));
    expect(screen.getByText(`${DEMO_SMS.length} left`)).toBeTruthy();
  });

  it('offers money-in categories for money received', () => {
    render(<QuickSortDemo />);
    for (const tx of DEMO_SMS.slice(0, 3)) tap(tx.answer);
    expect(screen.getByRole('button', { name: /Income/ })).toBeTruthy();
    expect(screen.queryByRole('button', { name: /Groceries/ })).toBeNull();
  });
});

describe('plan slider', () => {
  it('splits income 50/20/20/10', () => {
    render(<PlanSlider />);
    fireEvent.change(screen.getByRole('slider'), { target: { value: '100000' } });
    for (const amount of ['KES 50,000', 'KES 20,000', 'KES 10,000']) {
      expect(screen.getAllByText(amount).length).toBeGreaterThan(0);
    }
  });
});

describe('legal pages', () => {
  it('lists every section in the table of contents', () => {
    const sections = [
      { id: 'a', title: 'First', body: <p>one</p> },
      { id: 'b', title: 'Second', body: <p>two</p> },
    ];
    render(<LegalPage title="Privacy Policy" intro="Hi" sections={sections} />);
    const toc = screen.getByRole('navigation', { name: 'On this page' });
    expect(within(toc).getByRole('link', { name: '2. Second' }).getAttribute('href')).toBe('#b');
    expect(screen.getByRole('heading', { name: '1. First' })).toBeTruthy();
  });
});

describe('plan split', () => {
  it('adds up to 100%', async () => {
    const { PLAN_SPLIT } = await import('../data.js');
    expect(PLAN_SPLIT.map((b) => b.key)).toEqual(['needs', 'savings', 'flex', 'emergency']);
    expect(PLAN_SPLIT.reduce((s, b) => s + b.pct, 0)).toBe(100);
  });
});
