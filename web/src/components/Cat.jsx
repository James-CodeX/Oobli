/**
 * Oobli's cat, drawn as vector art so every part can move: the head tilts,
 * the eyes blink and follow the cursor, the tail swishes and the raised paw
 * waves a coin. Animation classes live in styles.css (.cat-*).
 */
const FUR = '#FF9F43';
const FUR_DARK = '#F07F1F';
const CREAM = '#FFF4E6';
const INK = '#2B1D16';
const PINK = '#FF8FA3';

export function Cat({ className = '', title = 'Oobli the cat', coin = true, ...svgProps }) {
  return (
    <svg className={`cat ${className}`} viewBox="0 0 230 250" role="img" aria-label={title} {...svgProps}>
      <g className="cat-bob">
        {/* Tail, behind the body */}
        <g className="cat-tail">
          <path
            d="M150 214c46 4 66-30 56-60-4-12-16-14-20-6-3 6 2 10 5 16 8 18-6 36-42 34z"
            fill={FUR}
          />
          <path d="M196 150c-4-12-16-14-20-6l6 6c4-4 10-4 14 0z" fill={FUR_DARK} />
        </g>

        {/* Body */}
        <ellipse cx="112" cy="190" rx="58" ry="48" fill={FUR} />
        <ellipse cx="112" cy="200" rx="33" ry="33" fill={CREAM} />
        <path d="M70 178q-6 10-2 22M154 178q6 10 2 22" stroke={FUR_DARK} strokeWidth="4" strokeLinecap="round" fill="none" />
        <ellipse cx="86" cy="236" rx="20" ry="11" fill={CREAM} />
        <ellipse cx="138" cy="236" rx="20" ry="11" fill={CREAM} />

        {/* Resting paw */}
        <path d="M70 176q-12 28 4 50" stroke={FUR} strokeWidth="21" strokeLinecap="round" fill="none" />
        <circle cx="76" cy="226" r="12" fill={CREAM} />

        {/* Waving paw with a coin */}
        <g className="cat-arm">
          <path d="M156 168q32-16 46-62" stroke={FUR} strokeWidth="21" strokeLinecap="round" fill="none" />
          <circle cx="203" cy="102" r="14" fill={CREAM} />
          {coin && (
            <g className="cat-coin">
              <circle cx="212" cy="74" r="18" fill="#E5A800" />
              <circle cx="212" cy="71" r="18" fill="#FFC800" />
              <circle cx="212" cy="71" r="12" fill="#FFD84D" />
              <text x="212" y="76" textAnchor="middle" fontFamily="Nunito, sans-serif" fontWeight="900" fontSize="12" fill="#B88600">
                KSh
              </text>
            </g>
          )}
        </g>

        {/* Collar and tag */}
        <path d="M68 146q44 24 88 0" stroke="#58CC02" strokeWidth="11" strokeLinecap="round" fill="none" />
        <circle cx="112" cy="164" r="9" fill="#FFC800" stroke="#E5A800" strokeWidth="2" />

        {/* Head */}
        <g className="cat-head">
          <path d="M54 72 62 20l38 30z" fill={FUR} stroke={FUR} strokeWidth="10" strokeLinejoin="round" />
          <path d="M170 72l-8-52-38 30z" fill={FUR} stroke={FUR} strokeWidth="10" strokeLinejoin="round" />
          <path d="M66 60l3-26 20 16z" fill={PINK} stroke={PINK} strokeWidth="4" strokeLinejoin="round" />
          <path d="M158 60l-3-26-20 16z" fill={PINK} stroke={PINK} strokeWidth="4" strokeLinejoin="round" />
          <ellipse cx="112" cy="98" rx="68" ry="57" fill={FUR} />
          <path d="M101 46q4 10 0 18M112 44v20M123 46q-4 10 0 18" stroke={FUR_DARK} strokeWidth="4.5" strokeLinecap="round" fill="none" />
          <ellipse cx="93" cy="121" rx="25" ry="18" fill={CREAM} />
          <ellipse cx="131" cy="121" rx="25" ry="18" fill={CREAM} />
          <ellipse cx="66" cy="112" rx="11" ry="7" fill={PINK} opacity="0.55" />
          <ellipse cx="158" cy="112" rx="11" ry="7" fill={PINK} opacity="0.55" />

          <g className="cat-eyes">
            <g className="pupil">
              <ellipse cx="86" cy="93" rx="9" ry="11.5" fill={INK} />
              <circle cx="89.5" cy="88.5" r="3.4" fill="#fff" />
            </g>
            <g className="pupil">
              <ellipse cx="138" cy="93" rx="9" ry="11.5" fill={INK} />
              <circle cx="141.5" cy="88.5" r="3.4" fill="#fff" />
            </g>
          </g>

          <path d="M105 110h14l-7 8z" fill="#FF6F91" stroke="#FF6F91" strokeWidth="4" strokeLinejoin="round" />
          <path d="M99 121q13 20 26 0z" fill="#8A2E2E" />
          <path d="M105 128q7 6 14 0q-7-5-14 0z" fill="#FF6F91" />
          <path d="M62 120l-24-5M62 127l-24 4M162 120l24-5M162 127l24 4" stroke="#C9773B" strokeWidth="2.6" strokeLinecap="round" />
        </g>
      </g>
    </svg>
  );
}
