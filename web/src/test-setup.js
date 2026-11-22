// jsdom lacks these browser APIs used by the page's animations.
class IO {
  constructor(cb) { this.cb = cb; }
  observe(el) { this.cb([{ isIntersecting: true, target: el }]); }
  unobserve() {}
  disconnect() {}
}
globalThis.IntersectionObserver = IO;
globalThis.matchMedia ??= () => ({ matches: false, addEventListener() {}, removeEventListener() {} });
HTMLCanvasElement.prototype.getContext = () => null;

// Unmount between tests (vitest runs without globals, so RTL can't auto-clean).
import { cleanup } from '@testing-library/react';
import { afterEach } from 'vitest';

afterEach(cleanup);
