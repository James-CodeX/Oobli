import { Reveal } from '../components/Reveal.jsx';

/** Alternating two-column feature row: lowercase green headline + art. */
export function Feature({ id, title, children, art, flip = false, tint }) {
  return (
    <section id={id} className={`feature ${flip ? 'is-flipped' : ''} ${tint ? `tint-${tint}` : ''}`}>
      <div className="container feature-inner">
        <Reveal className="feature-copy">
          <h2>{title}</h2>
          {children}
        </Reveal>
        <Reveal className="feature-art" delay={120}>{art}</Reveal>
      </div>
    </section>
  );
}
