import { useEffect, useRef, useState } from 'react';
import { Cat } from './Cat.jsx';
import { confetti } from './confetti.js';

const SAYINGS = ['Karibu! 👋', 'Every shilling, sorted.', 'Niko na wewe! 💚', 'You saved KES 2,100!'];

const BARS = [
  { x: 30, h: 44 },
  { x: 58, h: 72 },
  { x: 86, h: 32 },
  { x: 114, h: 88 },
  { x: 142, h: 60 },
];

/** Donut slices on the phone screen: [colour, share]. */
const SLICES = [['#58CC02', 0.44], ['#1CB0F6', 0.27], ['#FFC800', 0.15], ['#FF9600', 0.14]];
const R = 30;
const CIRC = 2 * Math.PI * R;

/** One of Oobli's blob friends. Positioned by the outer group, animated by the inner ones. */
function Blob({ id, x, y, size, from, to, mood = 'happy', delay, idle, bouncing, onTap, children }) {
  const eyeY = size * 0.46;
  return (
    <g transform={`translate(${x} ${y})`}>
      <g className="pop" style={{ '--d': `${delay}ms` }}>
        <g className={`char ${bouncing ? 'is-boing' : ''}`} onClick={onTap} role="button" aria-label="Oobli friend" tabIndex={-1}>
          <g className={`tumble ${idle}`}>
            <ellipse cx={size / 2} cy={size + 10} rx={size * 0.36} ry={size * 0.07} fill="#000" opacity="0.07" className="shadow" />
            {children?.behind}
            <rect width={size} height={size} rx={size * 0.375} fill={`url(#${id})`} />
            <rect x={size * 0.14} y={size * 0.1} width={size * 0.3} height={size * 0.12} rx={size * 0.06} fill="#fff" opacity="0.28" />
            {mood === 'joy' ? (
              <path
                d={`M${size * 0.3} ${eyeY}q${size * 0.07} -${size * 0.1} ${size * 0.14} 0M${size * 0.56} ${eyeY}q${size * 0.07} -${size * 0.1} ${size * 0.14} 0`}
                stroke="#131F24" strokeWidth={size * 0.055} strokeLinecap="round" fill="none"
              />
            ) : (
              <g className="blob-eyes">
                <g className="pupil">
                  <rect x={size * 0.33} y={eyeY - size * 0.08} width={size * 0.1} height={size * 0.16} rx={size * 0.05} fill="#131F24" />
                  <rect x={size * 0.57} y={eyeY - size * 0.08} width={size * 0.1} height={size * 0.16} rx={size * 0.05} fill="#131F24" />
                </g>
              </g>
            )}
            <path d={`M${size * 0.4} ${size * 0.68}q${size * 0.1} ${size * 0.09} ${size * 0.2} 0`} stroke="#131F24" strokeWidth={size * 0.045} strokeLinecap="round" fill="none" />
            {children?.front}
          </g>
        </g>
      </g>
    </g>
  );
}

function Coin({ r = 14 }) {
  return (
    <g className="coin-spin">
      <circle r={r} cy={2} fill="#E5A800" />
      <circle r={r} fill="#FFC800" />
      <circle r={r * 0.66} fill="#FFD84D" />
      <text y={r * 0.3} textAnchor="middle" fontFamily="Poppins, sans-serif" fontWeight="800" fontSize={r * 0.62} fill="#B88600">KSh</text>
    </g>
  );
}

function Sparkle({ x, y, s = 1, color = '#FFC800', delay = 0 }) {
  return (
    <g transform={`translate(${x} ${y}) scale(${s})`}>
      <path className="twinkle" style={{ animationDelay: `${delay}s` }} d="M0-12c1 7 5 11 12 12-7 1-11 5-12 12-1-7-5-11-12-12 7-1 11-5 12-12z" fill={color} />
    </g>
  );
}

/**
 * The hero illustration: the cat waving from beside a tilted phone while
 * blob friends tumble around it and coins pop out of the screen. Everything
 * idles on its own; tap a character to make it jump; eyes follow the cursor.
 */
export function HeroScene() {
  const ref = useRef(null);
  const [boing, setBoing] = useState(null);
  const [saying, setSaying] = useState(0);
  const [showBubble, setShowBubble] = useState(false);

  // Pointer parallax + eyes that follow the cursor.
  useEffect(() => {
    const el = ref.current;
    if (!el || window.matchMedia?.('(prefers-reduced-motion: reduce)').matches) return undefined;
    const move = (e) => {
      const r = el.getBoundingClientRect();
      const px = (e.clientX - r.left) / r.width - 0.5;
      const py = (e.clientY - r.top) / r.height - 0.5;
      el.style.setProperty('--px', px.toFixed(3));
      el.style.setProperty('--py', py.toFixed(3));
      const d = Math.hypot(px, py) || 1;
      const k = Math.min(1, d * 2.5) * 2.6;
      el.style.setProperty('--ex', `${((px / d) * k).toFixed(2)}px`);
      el.style.setProperty('--ey', `${((py / d) * k).toFixed(2)}px`);
    };
    window.addEventListener('pointermove', move, { passive: true });
    return () => window.removeEventListener('pointermove', move);
  }, []);

  // The cat chats every few seconds.
  useEffect(() => {
    let hide;
    const show = () => {
      setShowBubble(true);
      hide = setTimeout(() => setShowBubble(false), 2600);
    };
    const first = setTimeout(show, 1400);
    const loop = setInterval(() => {
      setSaying((n) => (n + 1) % SAYINGS.length);
      show();
    }, 6000);
    return () => { clearTimeout(first); clearTimeout(hide); clearInterval(loop); };
  }, []);

  const tap = (name) => (e) => {
    setBoing(name);
    setTimeout(() => setBoing((b) => (b === name ? null : b)), 750);
    confetti(e.clientX, e.clientY, 26);
    if (name === 'cat') {
      setSaying((n) => (n + 1) % SAYINGS.length);
      setShowBubble(true);
    }
  };

  return (
    <div className="hero-art" ref={ref}>
      <svg viewBox="0 0 540 520" className="hero-svg" aria-hidden="true">
        <defs>
          <linearGradient id="bA" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stopColor="#1CB0F6" /><stop offset="1" stopColor="#CE82FF" /></linearGradient>
          <linearGradient id="bB" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stopColor="#FF9600" /><stop offset="1" stopColor="#FFC800" /></linearGradient>
          <linearGradient id="bC" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stopColor="#FF86B1" /><stop offset="1" stopColor="#FF9600" /></linearGradient>
          <linearGradient id="bD" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stopColor="#58CC02" /><stop offset="1" stopColor="#FFC800" /></linearGradient>
        </defs>

        <circle cx="270" cy="285" r="225" fill="#F2FBE9" className="halo" />

        {/* Phone */}
        <g className="layer l1">
          <g transform="translate(118 112) rotate(-12)">
            <g className="pop" style={{ '--d': '0ms' }}>
              <g className="stage-float">
                <rect x="6" y="12" width="200" height="324" rx="36" fill="#0B1316" />
                <rect width="200" height="324" rx="36" fill="#131F24" />
                <rect x="12" y="14" width="176" height="296" rx="26" fill="#fff" />
                <rect x="78" y="22" width="44" height="10" rx="5" fill="#131F24" />
                <text x="30" y="62" fontFamily="Poppins, sans-serif" fontWeight="800" fontSize="12" fill="#777">Today's Flow</text>
                <text x="30" y="86" fontFamily="Poppins, sans-serif" fontWeight="800" fontSize="20" fill="#4B4B4B">KES 2,450</text>
                {BARS.map((b, i) => (
                  <g key={b.x}>
                    <rect x={b.x} y={110} width="18" height="84" rx="9" fill="#F0F0F0" />
                    <rect className="bar" style={{ animationDelay: `${i * 0.18}s` }} x={b.x} y={194 - b.h} width="18" height={b.h} rx="9" fill={i === 3 ? '#58CC02' : '#C8F0A4'} />
                  </g>
                ))}
                <g className="donut" transform="translate(64 254)">
                  {SLICES.reduce((acc, [color, share]) => {
                    const offset = acc.offset;
                    acc.items.push(
                      <circle key={color} r={R} fill="none" stroke={color} strokeWidth="12" strokeLinecap="round"
                        strokeDasharray={`${share * CIRC - 6} ${CIRC}`} strokeDashoffset={-offset} />,
                    );
                    acc.offset += share * CIRC;
                    return acc;
                  }, { offset: 0, items: [] }).items}
                </g>
                <rect x="108" y="232" width="62" height="10" rx="5" fill="#E5E5E5" />
                <rect x="108" y="250" width="44" height="10" rx="5" fill="#C8F0A4" />
                <rect x="108" y="268" width="54" height="10" rx="5" fill="#E5E5E5" />
              </g>
            </g>
          </g>

          {/* Coins popping out of the screen */}
          {[-96, -40, 30, 92].map((dx, i) => (
            <g key={dx} transform="translate(236 150)">
              <g className="coin-pop" style={{ '--dx': `${dx}px`, animationDelay: `${0.9 + i * 0.65}s` }}>
                <Coin r={13} />
              </g>
            </g>
          ))}
        </g>

        {/* Blob friends */}
        <g className="layer l3">
          <Blob id="bA" x={34} y={64} size={80} delay={180} idle="idle-a" bouncing={boing === 'a'} onTap={tap('a')}>
            {{
              front: (
                <g transform="translate(64 40) rotate(16)">
                  <rect width="26" height="42" rx="6" fill="#131F24" />
                  <rect x="3" y="5" width="20" height="30" rx="3" fill="#58CC02" />
                  <path d="M8 21l4 4 7-8" stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" fill="none" />
                </g>
              ),
            }}
          </Blob>
          <Blob id="bD" x={226} y={6} size={46} mood="joy" delay={420} idle="idle-d" bouncing={boing === 'd'} onTap={tap('d')}>
            {{
              front: (
                <g className="juggle" transform="translate(23 -14)">
                  <Coin r={10} />
                </g>
              ),
            }}
          </Blob>
        </g>
        <g className="layer l2">
          <Blob id="bB" x={18} y={330} size={70} mood="joy" delay={300} idle="idle-b" bouncing={boing === 'b'} onTap={tap('b')}>
            {{
              front: (
                <g transform="translate(50 36)">
                  <path d="M6 6q8-14 16 0" stroke="#7E3FB0" strokeWidth="3.5" fill="none" strokeLinecap="round" />
                  <rect y="4" width="28" height="30" rx="6" fill="#CE82FF" />
                  <rect x="4" y="12" width="20" height="4" rx="2" fill="#fff" opacity="0.5" />
                </g>
              ),
            }}
          </Blob>
          <Blob id="bC" x={360} y={34} size={74} delay={540} idle="idle-c" bouncing={boing === 'c'} onTap={tap('c')}>
            {{
              behind: (
                <g transform="translate(-30 40)">
                  <ellipse cx="22" cy="18" rx="24" ry="18" fill="#FF86B1" />
                  <ellipse cx="0" cy="18" rx="7" ry="6" fill="#FF6F91" />
                  <rect x="16" y="2" width="12" height="3.5" rx="1.75" fill="#C2185B" opacity="0.6" />
                  <rect x="8" y="32" width="6" height="8" rx="3" fill="#FF6F91" />
                  <rect x="30" y="32" width="6" height="8" rx="3" fill="#FF6F91" />
                  <circle cx="12" cy="13" r="2.4" fill="#131F24" />
                </g>
              ),
            }}
          </Blob>
        </g>

        {/* The cat */}
        <g className="layer l2">
          <g transform="translate(292 206)">
            <g className="pop" style={{ '--d': '120ms' }}>
              <g className={`char ${boing === 'cat' ? 'is-boing' : ''}`} onClick={tap('cat')}>
                <ellipse cx="115" cy="246" rx="70" ry="10" fill="#000" opacity="0.07" />
                <Cat width="230" height="250" />
              </g>
            </g>
          </g>
        </g>

        <Sparkle x={300} y={78} />
        <Sparkle x={500} y={190} s={0.7} color="#1CB0F6" delay={0.8} />
        <Sparkle x={70} y={250} s={0.8} color="#CE82FF" delay={1.5} />
        <Sparkle x={196} y={470} s={0.6} color="#58CC02" delay={0.4} />
        <g transform="translate(140 478)"><g className="coin-float"><Coin r={11} /></g></g>
        <g transform="translate(512 300)"><g className="coin-float" style={{ animationDelay: '-1.4s' }}><Coin r={9} /></g></g>
      </svg>
      <div className={`cat-bubble ${showBubble ? 'is-on' : ''}`} role="status" aria-live="polite">{SAYINGS[saying]}</div>
    </div>
  );
}
