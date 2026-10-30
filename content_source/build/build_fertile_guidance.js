// Builds assets/content/fertile_guidance.json. Run from the repo root:
//   node content_source/build/build_fertile_guidance.js
const { writeJson, LAST_UPDATED, REVIEW } = require('./common');
const { sources, items } = require('./fertile_guidance');

writeJson('assets/content/fertile_guidance.json', {
  version: 1, type: 'fertile_guidance', lastUpdated: LAST_UPDATED, reviewStatus: REVIEW, sources, items,
});
