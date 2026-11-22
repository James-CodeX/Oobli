import { useEffect, useRef } from 'react';

/** The app's blob mascot: a gradient squircle whose eyes follow the cursor. */
export function Blob({ size = 72, from = '#58CC02', to = '#FFC800', mood = 'happy', className = '', style }) {
  const ref = useRef(null);
  useEffect(() => {
    const el = ref.current;
    if (!el) return undefined;
    const move = (e) => {
      const r = el.getBoundingClientRect();
      const dx = e.clientX - (r.left + r.width / 2);
      const dy = e.clientY - (r.top + r.height / 2);
      const d = Math.hypot(dx, dy) || 1;
      const m = Math.min(1, d / 300) * size * 0.05;
      el.style.setProperty('--ex', `${(dx / d) * m}px`);
      el.style.setProperty('--ey', `${(dy / d) * m}px`);
    };
    window.addEventListener('pointermove', move, { passive: true });
    return () => window.removeEventListener('pointermove', move);
  }, [size]);
  return (
    <div
      ref={ref}
      className={`blob blob-${mood} ${className}`}
      style={{ width: size, height: size, background: `linear-gradient(135deg, ${from}, ${to})`, ...style }}
      aria-hidden="true"
    >
      <span className="blob-eye" />
      <span className="blob-eye" />
      {mood === 'joy' && <span className="blob-smile" />}
    </div>
  );
}

export function Coin({ size = 44, className = '', style }) {
  return (
    <svg className={`coin ${className}`} style={style} width={size} height={size} viewBox="0 0 48 48" aria-hidden="true">
      <ellipse cx="24" cy="27" rx="20" ry="18" fill="#E5A800" />
      <ellipse cx="24" cy="23" rx="20" ry="18" fill="#FFC800" />
      <ellipse cx="24" cy="23" rx="14" ry="12.5" fill="#FFD84D" />
      <text x="24" y="28" textAnchor="middle" fontFamily="Nunito, sans-serif" fontWeight="900" fontSize="13" fill="#B88600">KES</text>
    </svg>
  );
}

export function Sparkle({ size = 22, color = '#FFC800', className = '', style }) {
  return (
    <svg className={className} style={style} width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 0c1 6.5 5.5 11 12 12-6.5 1-11 5.5-12 12-1-6.5-5.5-11-12-12C6.5 11 11 6.5 12 0z" fill={color} />
    </svg>
  );
}

/** A tilted phone frame; children render on its screen. */
export function Phone({ children, className = '', style }) {
  return (
    <div className={`phone ${className}`} style={style}>
      <div className="phone-notch" />
      <div className="phone-screen">{children}</div>
    </div>
  );
}

export function Logo({ size = 40 }) {
  return (
    <a className="logo" href="/" aria-label="Oobli home">
      <img src="/logo.webp" width={size} height={size} alt="" />
      <span>oobli</span>
    </a>
  );
}
