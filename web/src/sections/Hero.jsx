import { DOWNLOAD_URL } from '../config.js';
import { Button } from '../components/Button.jsx';

/** First screen: the app's home screen, a headline and two buttons. Nothing else. */
export function Hero() {
  return (
    <section className="hero">
      <div className="container hero-inner">
        <figure className="hero-shot">
          <img
            src="/app-home.webp"
            width="440"
            height="956"
            alt="Oobli's home screen: today's spending, where the money went this week and recent transactions"
            fetchpriority="high"
          />
        </figure>
        <div className="hero-copy">
          <h1>The free, fun way to master your M-Pesa money!</h1>
          <p className="hero-sub">Oobli reads your M-Pesa and bank messages and sorts every shilling for you.</p>
          <div className="hero-actions">
            <Button size="lg" href={DOWNLOAD_URL}>Get the app</Button>
            <Button size="lg" variant="outline" href="#how">See how it works</Button>
          </div>
        </div>
      </div>
    </section>
  );
}
