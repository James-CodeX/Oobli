import { DOWNLOAD_URL } from '../config.js';
import { Blob, Coin, Phone, Sparkle } from '../components/Art.jsx';
import { Button } from '../components/Button.jsx';
import { Reveal } from '../components/Reveal.jsx';

const BARS = [38, 62, 24, 48, 70, 54, 92];

/** "Money on the go" band: floating phones, coins and blobs. */
export function Anywhere() {
  return (
    <section className="anywhere">
      <Reveal className="container anywhere-copy">
        <h2>your money, anytime, anywhere</h2>
        <p>Matatu, market or mall: Oobli sorts it as it happens, even offline.</p>
        <Button href={DOWNLOAD_URL} size="lg" className="store-btn">
          <svg width="22" height="22" viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M3.6 1.8 13.8 12 3.6 22.2c-.4-.2-.6-.7-.6-1.2V3c0-.5.2-1 .6-1.2zm11.6 8.8 2.6-2.6 3.4 2c.9.5.9 1.6 0 2.1l-3.4 2-2.6-2.6-1.4-.9zm-1.4-.1L4.9 1.6l10.9 6.3-2 2.6zm0 3 2 2.6-10.9 6.3 8.9-8.9z" /></svg>
          Download for Android
        </Button>
      </Reveal>
      <div className="anywhere-scene" aria-hidden="true">
        <Phone className="scene-phone p1">
          <div className="mini-head">Today's Flow</div>
          <div className="mini-bars">{BARS.map((h, i) => <i key={i} style={{ height: `${h}%` }} className={i === 6 ? 'is-hot' : ''} />)}</div>
        </Phone>
        <Phone className="scene-phone p2">
          <div className="mini-head">Where it went</div>
          <div className="mini-donut" />
        </Phone>
        <Phone className="scene-phone p3">
          <div className="mini-head">Coast Trip</div>
          <div className="mini-goal"><i style={{ width: '70%' }} /></div>
          <div className="mini-sub">KES 21,000 / 30,000</div>
        </Phone>
        <Coin className="float s1" size={46} />
        <Coin className="float delay-2 s2" size={34} />
        <Blob className="float delay-1 s3" size={58} from="#FF9600" to="#FFC800" mood="joy" />
        <Blob className="float delay-2 s4" size={40} from="#1CB0F6" to="#58CC02" />
        <Sparkle className="twinkle s5" size={26} color="#fff" />
        <div className="float delay-1 s6 cube">🏦</div>
        <div className="float s7 cube">📱</div>
        <div className="float delay-2 s8 cube">🛒</div>
      </div>
    </section>
  );
}
