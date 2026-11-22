import { useEffect, useState } from 'react';
import { Button } from '../components/Button.jsx';
import { useInView } from '../components/Reveal.jsx';
import { DOWNLOAD_URL } from '../config.js';

const STORIES = [
  { kicker: 'Your November', big: 'KES 48,320', line: 'moved through M-Pesa', bg: 'linear-gradient(160deg,#1CB0F6,#CE82FF)' },
  { kicker: 'Top category', big: '🛒 Groceries', line: 'Naivas saw you 14 times', bg: 'linear-gradient(160deg,#58CC02,#1CB0F6)' },
  { kicker: 'Biggest day', big: 'Friday 15th', line: 'KES 6,800, a birthday?', bg: 'linear-gradient(160deg,#FF9600,#FF4B4B)' },
  { kicker: 'You saved', big: 'KES 9,400', line: '🔥 a 21-day streak!', bg: 'linear-gradient(160deg,#FFC800,#58CC02)' },
];

/** Story-style recap cards that auto-advance; tap to skip ahead. */
export function Wrapped() {
  const [ref, inView] = useInView(0.35);
  const [i, setI] = useState(0);
  useEffect(() => {
    if (!inView) return undefined;
    const t = setTimeout(() => setI((i + 1) % STORIES.length), 3200);
    return () => clearTimeout(t);
  }, [inView, i]);
  const s = STORIES[i];

  return (
    <section id="wrapped" className="wrapped" ref={ref}>
      <div className="container wrapped-inner">
        <button type="button" className="story" style={{ background: s.bg }} onClick={() => setI((i + 1) % STORIES.length)} aria-label="Next recap card">
          <div className="story-bars">
            {STORIES.map((_, n) => (
              <span key={n}><i className={n < i ? 'is-full' : n === i && inView ? 'is-running' : ''} key={`${n}-${i}`} /></span>
            ))}
          </div>
          <div key={i} className="story-body pop-in">
            <small>{s.kicker}</small>
            <b>{s.big}</b>
            <span>{s.line}</span>
          </div>
          <div className="story-tap">tap ›</div>
        </button>
        <div className="wrapped-copy">
          <p className="wrapped-kicker">every month, celebrate with</p>
          <h2 className="wrapped-title">OOBLI WRAPPED</h2>
          <p>Your month in money as a shareable story: top merchants, biggest days, savings wins and a little roast from Oobli.</p>
          <Button variant="light" href={DOWNLOAD_URL}>Get my Wrapped</Button>
        </div>
      </div>
    </section>
  );
}
