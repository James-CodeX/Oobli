import { useState } from 'react';
import { kes, PLAN_SPLIT } from '../data.js';

/** Drag the income slider and watch Oobli Plans split it. */
export function PlanSlider() {
  const [income, setIncome] = useState(45000);
  return (
    <div className="plan-card">
      <label className="plan-label" htmlFor="income">
        I expect to earn <output>{kes(income)}</output> this month
      </label>
      <input
        id="income"
        type="range"
        min="5000"
        max="300000"
        step="1000"
        value={income}
        onChange={(e) => setIncome(Number(e.target.value))}
        style={{ '--fill': `${((income - 5000) / 295000) * 100}%` }}
      />
      <div className="plan-bars">
        {PLAN_SPLIT.map((b) => (
          <div className="plan-row" key={b.key}>
            <div className="plan-row-head">
              <b>{b.label} <small>{b.pct}%</small></b>
              <span>{kes((income * b.pct) / 100)}</span>
            </div>
            <div className="plan-track"><div style={{ width: `${b.pct * 2}%`, background: b.color }} /></div>
            <small className="plan-note">{b.note}</small>
          </div>
        ))}
      </div>
    </div>
  );
}
