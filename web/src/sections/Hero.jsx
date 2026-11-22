import { DOWNLOAD_URL } from '../config.js';
import { Button } from '../components/Button.jsx';
import { HeroScene } from '../components/HeroScene.jsx';

/** First screen: the animated scene, a headline and two buttons. Nothing else. */
export function Hero() {
  return (
    <section className="hero">
      <div className="container hero-inner">
        <HeroScene />
        <div className="hero-copy">
          <h1>The free, fun way to master your M-Pesa money!</h1>
          <div className="hero-actions">
            <Button size="lg" href={DOWNLOAD_URL}>Get the app</Button>
            <Button size="lg" variant="outline" href="#how">See how it works</Button>
          </div>
        </div>
      </div>
    </section>
  );
}
