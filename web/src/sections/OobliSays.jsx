import { useEffect, useState } from 'react';
import { Cat } from '../components/Cat.jsx';
import { useInView } from '../components/Reveal.jsx';
import { INSIGHTS } from '../data.js';

/** The cat delivers a rotating "Oobli says…" nudge; tap for the next one. */
export function OobliSays() {
  const [ref, inView] = useInView(0.3);
  const [i, setI] = useState(0);
  useEffect(() => {
    if (!inView) return undefined;
    const t = setInterval(() => setI((n) => (n + 1) % INSIGHTS.length), 3800);
    return () => clearInterval(t);
  }, [inView]);

  return (
    <button type="button" ref={ref} className="says" onClick={() => setI((i + 1) % INSIGHTS.length)} aria-label="Next Oobli tip">
      <Cat className="says-cat" title="" width="150" height="163" />
      <div className="says-bubble">
        <small>Oobli says…</small>
        <p key={i} className="pop-in">{INSIGHTS[i]}</p>
        <span className="says-dots">
          {INSIGHTS.map((_, n) => <i key={n} className={n === i ? 'is-on' : ''} />)}
        </span>
      </div>
    </button>
  );
}
