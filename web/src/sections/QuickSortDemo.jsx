import { useState } from 'react';
import { confetti } from '../components/confetti.js';
import { Button } from '../components/Button.jsx';
import { byKey, CATEGORIES, DEMO_SMS } from '../data.js';

const SPEND = CATEGORIES.filter((c) => c.key !== 'bank_withdrawal');
const RECEIVE = ['bank_withdrawal', 'savings', 'debt'].map((k) => byKey[k]).concat({ key: 'income', label: 'Income', emoji: '💰', color: '#58CC02' });

/** Try the app's Quick sort: one tap files a transaction and opens the next. */
export function QuickSortDemo() {
  const [index, setIndex] = useState(0);
  const [picked, setPicked] = useState([]);
  const [leaving, setLeaving] = useState(null);
  const done = index >= DEMO_SMS.length;
  const tx = DEMO_SMS[index];
  const choices = tx?.kind === 'received from' ? RECEIVE : SPEND;

  const pick = (cat, e) => {
    if (leaving) return;
    setLeaving(cat.key);
    const rect = e.currentTarget.getBoundingClientRect();
    setTimeout(() => {
      const next = [...picked, { ...tx, cat }];
      setPicked(next);
      setLeaving(null);
      setIndex(index + 1);
      if (next.length === DEMO_SMS.length) confetti(rect.left + rect.width / 2, rect.top);
    }, 320);
  };
  const reset = () => { setIndex(0); setPicked([]); };

  return (
    <div className="sort-demo" aria-live="polite">
      <div className="sort-head">
        <span>⚡ Quick sort</span>
        <span className="sort-left">{done ? 'All done!' : `${DEMO_SMS.length - index} left`}</span>
      </div>
      <div className="sort-progress"><div style={{ width: `${(picked.length / DEMO_SMS.length) * 100}%` }} /></div>

      {done ? (
        <div className="sort-done pop-in">
          <div className="sort-done-emoji">🎉</div>
          <b>All sorted in {DEMO_SMS.length} taps!</b>
          <p>That's how fast it is in the app, and Oobli remembers each merchant for next time.</p>
          <ul className="sort-recap">
            {picked.map((p) => (
              <li key={p.code}><span>{p.cat.emoji}</span>{p.who.toLowerCase()} <em>{p.cat.label}</em></li>
            ))}
          </ul>
          <Button variant="outline" size="sm" onClick={reset}>Try again</Button>
        </div>
      ) : (
        <div key={tx.code} className={`sort-card ${leaving ? 'is-leaving' : 'slide-in'}`}>
          <div className="sort-sms">
            <b>{tx.code}</b> Confirmed. Ksh{tx.amount.toLocaleString('en-KE')}.00 {tx.kind} <b>{tx.who}</b>
          </div>
          <div className="sort-guess">
            Oobli guessed <b>{byKey[tx.guess].emoji} {byKey[tx.guess].label}</b>
            {tx.guess !== tx.answer && <span className="sort-hint"> (hint: it was a matatu fare)</span>}
          </div>
          <div className="sort-chips">
            {choices.map((c) => (
              <button
                type="button"
                key={c.key}
                className={`chip ${c.key === tx.guess ? 'is-guess' : ''} ${leaving === c.key ? 'is-picked' : ''}`}
                style={{ '--c': c.color }}
                onClick={(e) => pick(c, e)}
              >
                <span>{c.emoji}</span>{c.label}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
