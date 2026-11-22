import { CONTACT_URL, DOWNLOAD_URL } from '../config.js';
import { Logo } from './Art.jsx';
import { Button } from './Button.jsx';

export function Header({ compact = false }) {
  return (
    <header className={`site-header ${compact ? 'is-compact' : ''}`}>
      <div className="container header-inner">
        <Logo />
        <nav className="header-nav" aria-label="Main">
          <a href="/#how">How it works</a>
          <a href="/privacy/">Privacy</a>
          <Button size="sm" href={DOWNLOAD_URL}>Get the app</Button>
        </nav>
      </div>
    </header>
  );
}

export function Footer() {
  const year = new Date().getFullYear();
  return (
    <footer className="site-footer">
      <div className="container footer-grid">
        <div className="footer-brand">
          <Logo size={36} />
          <p>Your AI money companion for M-Pesa and bank SMS. Made with ❤️ in Nairobi.</p>
        </div>
        <div>
          <h4>Product</h4>
          <a href="/#how">How it works</a>
          <a href="/#sort">One-tap sorting</a>
          <a href="/#plans">Oobli Plans</a>
          <a href="/#wrapped">Oobli Wrapped</a>
        </div>
        <div>
          <h4>Get Oobli</h4>
          <a href={DOWNLOAD_URL}>Android (APK)</a>
          <a href="/#faq">FAQ</a>
        </div>
        <div>
          <h4>Legal</h4>
          <a href="/terms/">Terms of Service</a>
          <a href="/privacy/">Privacy Policy</a>
          <a href={CONTACT_URL}>Contact us</a>
        </div>
      </div>
      <div className="container footer-bottom">
        <span>© {year} Oobli. Not affiliated with Safaricom or any bank.</span>
        <span>M-Pesa is a trademark of Safaricom PLC.</span>
      </div>
    </footer>
  );
}
