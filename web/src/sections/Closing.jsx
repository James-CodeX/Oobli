import { useState } from 'react';
import { DOWNLOAD_URL } from '../config.js';
import { Coin, Sparkle } from '../components/Art.jsx';
import { Cat } from '../components/Cat.jsx';
import { Button } from '../components/Button.jsx';
import { Reveal } from '../components/Reveal.jsx';

const GITHUB_URL = 'https://github.com/James-CodeX/Oobli';

const FAQ = [
  ['Is Oobli free?', 'Yes. Oobli is free to download and use.'],
  [
    "My phone won't install Oobli. What do I do?",
    <>
      <p>
        Android's Play Protect is extra careful with apps from outside the Play Store that read SMS, because scam apps
        misuse that permission. Oobli only reads money messages, and its code is open for anyone to check.
      </p>
      <ol>
        <li>If you see a warning, tap <b>More details</b>, then <b>Install anyway</b>.</li>
        <li>
          If it says the app was blocked, open the <b>Play Store</b>, tap your profile picture, then{' '}
          <b>Play Protect</b> and the settings gear. Turn off <b>Scan apps with Play Protect</b>, install Oobli, then
          turn it back on.
        </li>
      </ol>
    </>,
  ],
  ['Do I have to give Oobli my bank or M-Pesa PIN?', 'Never. Oobli only reads the confirmation SMS that M-Pesa and your bank already send you. It cannot move money.'],
  ['Which messages does Oobli read?', 'Only messages from financial senders such as MPESA and bank short codes. Chats from people are skipped on your phone and never uploaded.'],
  ['What does the AI do?', 'It sorts transactions the rules could not place, writes your "Oobli says…" nudges, drafts Oobli Plans and your monthly Wrapped. You can correct any category and Oobli learns from it.'],
  [
    'Is Oobli open source?',
    <p>
      Yes. The full code is on <a href={GITHUB_URL}>GitHub</a> under the MIT license. Read it, build the app yourself,
      or make your own version with the AI of your choice.
    </p>,
  ],
  ['Is it on iPhone?', 'Not yet. iOS does not let apps read SMS, so Oobli is Android-first. You can still add transactions by hand.'],
];

export function Privacy() {
  return (
    <section className="privacy-band">
      <div className="container privacy-inner">
        <Reveal className="shield" aria-hidden="true">
          <svg viewBox="0 0 120 140" width="150" height="175">
            <path d="M60 6 110 24v40c0 34-22 58-50 70C32 122 10 98 10 64V24z" fill="#58CC02" />
            <path d="M60 6 110 24v40c0 34-22 58-50 70z" fill="#4CAD00" />
            <path d="m38 70 15 15 30-32" stroke="#fff" strokeWidth="12" strokeLinecap="round" strokeLinejoin="round" fill="none" />
          </svg>
        </Reveal>
        <Reveal delay={100} className="privacy-copy">
          <h2>private by design</h2>
          <ul className="checks">
            <li>Only financial SMS are read, and the filtering happens on your phone</li>
            <li>No bank logins, no PINs, no access to your money</li>
            <li>Your data is locked to your account and never sold</li>
          </ul>
          <a className="link" href="/privacy/">Read our privacy policy ›</a>
        </Reveal>
      </div>
    </section>
  );
}

export function Faq() {
  const [open, setOpen] = useState(0);
  return (
    <section id="faq" className="faq">
      <div className="container narrow">
        <h2>questions? we've got answers</h2>
        {FAQ.map(([q, a], i) => (
          <div key={q} className={`faq-item ${open === i ? 'is-open' : ''}`}>
            <button type="button" onClick={() => setOpen(open === i ? -1 : i)} aria-expanded={open === i}>
              {q}<span aria-hidden="true">+</span>
            </button>
            <div className="faq-answer"><div className="faq-body">{typeof a === 'string' ? <p>{a}</p> : a}</div></div>
          </div>
        ))}
      </div>
    </section>
  );
}

export function FinalCta() {
  return (
    <section className="final">
      <Reveal className="container final-copy">
        <h2>take charge of your money with Oobli</h2>
        <Button size="lg" href={DOWNLOAD_URL}>Get started</Button>
      </Reveal>
      <div className="final-scene" aria-hidden="true">
        <Coin className="float f1" size={52} />
        <Coin className="float delay-1 f2" size={40} />
        <Coin className="float delay-2 f3" size={46} />
        <Coin className="float f4" size={34} />
        <Sparkle className="twinkle f5" size={24} />
        <Cat className="final-cat" title="" width="170" height="185" />
      </div>
      <svg className="final-wave" viewBox="0 0 1440 160" preserveAspectRatio="none" aria-hidden="true">
        <path d="M0 80c240-70 480-70 720 0s480 70 720 0v80H0z" fill="#58CC02" />
      </svg>
    </section>
  );
}
