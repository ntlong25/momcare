// Build all content JSON from authoring modules. Run from repo root:
//   node content_source/build/build_all.js
const { writeJson, LAST_UPDATED, REVIEW } = require('./common');
require('./build_guides');

writeJson('assets/content/weeks_v2.json', {
  version: 2, lastUpdated: LAST_UPDATED, reviewStatus: REVIEW, weeks: require('./weeks'),
});

const TG_CATS = ['talk', 'music', 'movement', 'reading', 'breathing', 'partner', 'journal'];
const TIP_CATS = { n: 'nutrition', b: 'body', m: 'mental', p: 'prep', s: 'safety' };

function daily(type, src, mapper) {
  const items = [];
  for (let week = 0; week <= 41; week++) {
    const list = src[week];
    if (!list || list.length !== 7) throw new Error(`${type}: week ${week} has ${list && list.length} items`);
    list.forEach((entry, dow) => items.push({ day: week * 7 + dow + 1, week, ...mapper(entry, dow) }));
  }
  return { version: 1, type, lastUpdated: LAST_UPDATED, reviewStatus: REVIEW, items };
}

const tg = { ...require('./thai_giao_a'), ...require('./thai_giao_b') };
writeJson('assets/content/daily/thai_giao.json', daily('thai_giao', tg, ([title, body, durationMin], dow) => ({
  category: TG_CATS[dow], title, body, durationMin, sources: [],
})));

const tips = { ...require('./tips_a'), ...require('./tips_b') };
writeJson('assets/content/daily/daily_tips.json', daily('daily_tip', tips, ([code, title, body]) => {
  if (!TIP_CATS[code]) throw new Error('bad tip code ' + code);
  return { category: TIP_CATS[code], title, body, sources: [] };
}));

writeJson('assets/content/foods.json', {
  version: 1, lastUpdated: LAST_UPDATED, reviewStatus: REVIEW, foods: require('./foods'),
});
