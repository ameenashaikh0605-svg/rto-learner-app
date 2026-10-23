const { chromium } = require('playwright');
const out = process.argv[2], step = process.argv[3] || 'home';
(async () => {
  const b = await chromium.launch({ args: ['--headless=new', '--enable-unsafe-swiftshader'] });
  const p = await b.newPage({ viewport: { width: 360, height: 640 }, deviceScaleFactor: 3, locale: 'en-IN' });
  await p.addInitScript(() => {
    const ids = Array.from({ length: 64 }, (_, i) => String(i + 1));
    localStorage.setItem('flutter.correct_ids', JSON.stringify(ids));
    localStorage.setItem('flutter.missed_ids', JSON.stringify(['70', '71', '75', '80', '88']));
    localStorage.setItem('flutter.best_mock', '13');
    localStorage.setItem('flutter.mocks_taken', '3'); localStorage.setItem('flutter.unlocked', 'true');
  });
  p.on('console', m => console.log('C:', m.text().slice(0,300))); p.on('pageerror', e => console.log('E:', String(e).slice(0,300)));
  await p.goto('http://localhost:8765/');
  await p.waitForTimeout(12000);
  const taps = JSON.parse(process.argv[4] || '[]');
  for (const [x, y, w] of taps) { await p.mouse.click(x, y); await p.waitForTimeout(w || 1500); }
  await p.screenshot({ path: `${out}/${step}.png` });
  await b.close();
})();
