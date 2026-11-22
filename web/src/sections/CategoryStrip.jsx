import { useRef, useState } from 'react';
import { CATEGORIES } from '../data.js';

/** Scrollable category bar; tapping a category shows where Oobli files it. */
export function CategoryStrip() {
  const track = useRef(null);
  const [open, setOpen] = useState(null);
  const scroll = (dir) => track.current?.scrollBy({ left: dir * 320, behavior: 'smooth' });
  const active = CATEGORIES.find((c) => c.key === open);

  return (
    <section className="strip" aria-label="Categories Oobli understands">
      <div className="container strip-inner">
        <button type="button" className="strip-arrow" onClick={() => scroll(-1)} aria-label="Scroll left">‹</button>
        <div className="strip-track" ref={track}>
          {CATEGORIES.map((c) => (
            <button
              type="button"
              key={c.key}
              className={`strip-item ${open === c.key ? 'is-open' : ''}`}
              onClick={() => setOpen(open === c.key ? null : c.key)}
              aria-pressed={open === c.key}
            >
              <span className="strip-emoji" style={{ background: `${c.color}22` }}>{c.emoji}</span>
              {c.label}
            </button>
          ))}
        </div>
        <button type="button" className="strip-arrow" onClick={() => scroll(1)} aria-label="Scroll right">›</button>
      </div>
      <div className={`strip-tip ${active ? 'is-open' : ''}`} role="status">
        {active && <><b>{active.emoji} {active.label}:</b> {active.examples}</>}
      </div>
    </section>
  );
}
