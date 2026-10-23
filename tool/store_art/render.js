const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch({ args: ['--headless=new'] });
  const p = await b.newPage({ deviceScaleFactor: 1 });
  await p.goto('file://' + __dirname + '/art.html');
  await p.evaluate(() => document.fonts.ready);
  for (const id of ['icon', 'fg', 'feature'])
    await (await p.$('#' + id)).screenshot({ path: `${process.argv[2]}/${id}.png`, omitBackground: true });
  await b.close();
})();
