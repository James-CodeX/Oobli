import { useEffect, useState } from 'react';
import { Phone } from '../components/Art.jsx';
import { useInView } from '../components/Reveal.jsx';

const FLOW = [
  { sms: 'TKL4QX81AB Confirmed. Ksh4,250.00 paid to NAIVAS WESTLANDS on 21/11/26 at 6:40 PM.', icon: '🛒', label: 'Groceries', who: 'Naivas Westlands', amt: '-KES 4,250', color: '#58CC02' },
  { sms: 'TKM2HD90ZP Confirmed. Ksh100.00 sent to SUPER METRO LTD on 21/11/26 at 7:15 AM.', icon: '🚌', label: 'Transport', who: 'Super Metro', amt: '-KES 100', color: '#1CB0F6' },
  { sms: 'TKP1VB22QE Confirmed. You have received Ksh5,000.00 from EQUITY BANK on 20/11/26.', icon: '🏦', label: 'Bank withdrawal', who: 'Equity Bank', amt: '+KES 5,000', color: '#1CB0F6' },
];

/** Loops: an SMS lands, Oobli thinks, and it becomes a sorted transaction. */
export function SmsPhone() {
  const [ref, inView] = useInView(0.4);
  const [i, setI] = useState(0);
  const [stage, setStage] = useState(0); // 0 sms, 1 thinking, 2 sorted
  useEffect(() => {
    if (!inView) return undefined;
    const t = setTimeout(() => {
      if (stage < 2) setStage(stage + 1);
      else { setStage(0); setI((i + 1) % FLOW.length); }
    }, stage === 2 ? 2200 : 1200);
    return () => clearTimeout(t);
  }, [inView, stage, i]);
  const f = FLOW[i];

  return (
    <div ref={ref} className="sms-phone-wrap">
      <Phone className="tilt-left">
        <div className="screen-head">Messages · M-PESA</div>
        <div key={`s${i}`} className="bubble pop-in">{f.sms}</div>
        <div className={`thinking ${stage === 1 ? 'is-on' : ''}`}><span /><span /><span /></div>
        <div className={`sorted-card ${stage === 2 ? 'is-on' : ''}`}>
          <span className="sorted-icon" style={{ background: `${f.color}22` }}>{f.icon}</span>
          <div>
            <b>{f.who}</b>
            <small style={{ color: f.color }}>✓ {f.label}</small>
          </div>
          <strong>{f.amt}</strong>
        </div>
      </Phone>
    </div>
  );
}
