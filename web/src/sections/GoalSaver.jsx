import { useState } from 'react';
import { confetti } from '../components/confetti.js';
import { kes } from '../data.js';

const TARGET = 30000;

/** Tap to stash KES 1,500 toward a goal; the ring and streak grow. */
export function GoalSaver() {
  const [saved, setSaved] = useState(21000);
  const [streak, setStreak] = useState(12);
  const pct = Math.min(1, saved / TARGET);
  const r = 64;
  const circ = 2 * Math.PI * r;

  const save = (e) => {
    if (saved >= TARGET) { setSaved(21000); setStreak(12); return; }
    const next = Math.min(TARGET, saved + 1500);
    setSaved(next);
    setStreak(streak + 1);
    if (next >= TARGET) {
      const b = e.currentTarget.getBoundingClientRect();
      confetti(b.left + b.width / 2, b.top);
    }
  };

  return (
    <div className="goal-card">
      <div className="goal-ring">
        <svg viewBox="0 0 160 160" width="160" height="160" aria-hidden="true">
          <circle cx="80" cy="80" r={r} stroke="#E5E5E5" strokeWidth="16" fill="none" />
          <circle
            cx="80" cy="80" r={r} stroke="#58CC02" strokeWidth="16" fill="none" strokeLinecap="round"
            strokeDasharray={circ} strokeDashoffset={circ * (1 - pct)} transform="rotate(-90 80 80)"
            className="goal-progress"
          />
        </svg>
        <div className="goal-center"><span>🏖️</span><b>{Math.round(pct * 100)}%</b></div>
      </div>
      <div className="goal-info">
        <b>Coast Trip</b>
        <span>{kes(saved)} of {kes(TARGET)}</span>
        <div className="streak" key={streak}>🔥 <b>{streak}</b> day streak</div>
        <button type="button" className="btn btn-primary btn-sm" onClick={save}>
          {saved >= TARGET ? 'Goal reached! Reset' : 'Save KES 1,500'}
        </button>
      </div>
    </div>
  );
}
