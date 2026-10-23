const { chromium } = require('playwright');
const items = [['s1','Track your progress<br>to a pass'],['s2','Timed mock tests,<br>like the real test'],['answered4','Learn 30+<br>Indian road signs'],['s3','Practise by topic,<br>with explanations']];
(async () => {
  const b = await chromium.launch({ args: ['--headless=new'] });
  const p = await b.newPage({ viewport: { width: 1080, height: 1920 } });
  let i = 1;
  for (const [img, cap] of items) {
    await p.goto('file://' + __dirname + '/frame.html');
    await p.evaluate(([img, cap]) => { document.body.innerHTML = `<div class="f"><div class="c">${cap}</div><div class="p"><img src="${img}.png"></div></div>`; }, [img, cap]);
    await p.waitForTimeout(400); await p.evaluate(() => document.fonts.ready);
    await p.screenshot({ path: `${__dirname}/screenshot-${i++}.png` });
  }
  await b.close();
})();
