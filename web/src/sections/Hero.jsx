import { useEffect, useRef } from 'react';
import { DOWNLOAD_URL } from '../config.js';
import { Blob, Coin, Sparkle } from '../components/Art.jsx';
import { Button } from '../components/Button.jsx';

/** Mascot cluster with gentle parallax that follows the pointer. */
function HeroArt() {
  const ref = useRef(null);
  useEffect(() => {
    const el = ref.current;
    if (!el || window.matchMedia?.('(prefers-reduced-motion: reduce)').matches) return undefined;
    const move = (e) => {
      const r = el.getBoundingClientRect();
      el.style.setProperty('--px', ((e.clientX - r.left) / r.width - 0.5).toFixed(3));
      el.style.setProperty('--py', ((e.clientY - r.top) / r.height - 0.5).toFixed(3));
    };
    window.addEventListener('pointermove', move, { passive: true });
    return () => window.removeEventListener('pointermove', move);
  }, []);

  return (
    <div className="hero-art" ref={ref} aria-hidden="true">
      <div className="hero-halo" />
      <img className="hero-cat depth-1" src="/logo.webp" alt="" width="300" height="300" />
      <div className="float depth-3" style={{ top: '4%', left: '6%' }}>
        <div className="sms-chip"><b>M-PESA</b> Ksh450 paid to MAMA MBOGA</div>
      </div>
      <div className="float depth-2 delay-1" style={{ bottom: '10%', left: '-2%' }}>
        <div className="tx-chip"><span>🛒</span><div><b>Groceries</b><small>-KES 4,250 · Naivas</small></div></div>
      </div>
      <div className="float depth-3 delay-2" style={{ top: '14%', right: '0%' }}>
        <div className="says-chip">Oobli says… <b>You saved KES 2,100 this week!</b></div>
      </div>
      <Blob className="float depth-2 delay-2" size={64} style={{ bottom: '4%', right: '8%' }} mood="joy" />
      <Blob className="float depth-3 delay-1" size={42} from="#1CB0F6" to="#CE82FF" style={{ top: '46%', left: '-4%' }} />
      <Coin className="float depth-3" size={50} style={{ top: '-2%', right: '30%' }} />
      <Coin className="float depth-2 delay-2" size={36} style={{ bottom: '28%', right: '-3%' }} />
      <Sparkle className="twinkle" style={{ position: 'absolute', top: '30%', right: '22%' }} />
      <Sparkle className="twinkle delay-1" size={16} color="#1CB0F6" style={{ position: 'absolute', bottom: '34%', left: '20%' }} />
    </div>
  );
}

export function Hero() {
  return (
    <section className="hero">
      <div className="container hero-inner">
        <HeroArt />
        <div className="hero-copy">
          <h1>The free, fun way to master your M-Pesa money.</h1>
          <p className="hero-sub">Oobli reads your M-Pesa and bank SMS, sorts every shilling with AI and helps you plan, save and celebrate.</p>
          <div className="hero-actions">
            <Button size="lg" href={DOWNLOAD_URL}>Get the app — it's free</Button>
            <Button size="lg" variant="outline" href="#how">See how it works</Button>
          </div>
          <p className="hero-note">Android · No bank logins · Your SMS never leave your phone</p>
        </div>
      </div>
    </section>
  );
}
