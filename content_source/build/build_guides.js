const { writeJson, LAST_UPDATED, REVIEW } = require('./common');
const guides = [...require('./guides_pre'), ...require('./guides_pregnant')];
// Display order: pre first, then pregnant; within a stage by `order`.
const stageRank = { pre: 0, pregnant: 1, postpartum: 2 };
guides.sort((a, b) => stageRank[a.stage] - stageRank[b.stage] || a.order - b.order);
const files = [];
for (const g of guides) {
  const out = { ...g, lastUpdated: LAST_UPDATED, reviewStatus: REVIEW };
  writeJson(`assets/content/guides/${g.id}.json`, out);
  files.push(`${g.id}.json`);
}
writeJson('assets/content/guides/index.json', { version: 1, guides: files });
