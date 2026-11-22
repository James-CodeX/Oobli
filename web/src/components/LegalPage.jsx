import { UPDATED } from '../config.js';
import { Footer, Header } from './Chrome.jsx';

/** Shared layout for Terms and Privacy: title card, table of contents, prose. */
export function LegalPage({ title, intro, sections }) {
  return (
    <>
      <Header compact />
      <main className="legal">
        <div className="legal-hero">
          <div className="container narrow">
            <h1>{title}</h1>
            <p className="legal-updated">Last updated {UPDATED}</p>
            <p className="legal-intro">{intro}</p>
          </div>
        </div>
        <div className="container legal-body">
          <nav className="legal-toc" aria-label="On this page">
            <b>On this page</b>
            {sections.map((s, i) => <a key={s.id} href={`#${s.id}`}>{i + 1}. {s.title}</a>)}
          </nav>
          <article className="prose">
            {sections.map((s, i) => (
              <section key={s.id} id={s.id}>
                <h2>{i + 1}. {s.title}</h2>
                {s.body}
              </section>
            ))}
          </article>
        </div>
      </main>
      <Footer />
    </>
  );
}
