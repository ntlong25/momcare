// Shared helpers for MomCare+ content build scripts.
// Run from repo root: node content_source/build/build_all.js
const fs = require('fs');
const path = require('path');

const LAST_UPDATED = '2026-10-29';
const REVIEW = 'draft_requires_medical_review';
const ROOT = path.resolve(__dirname, '..', '..');

function writeJson(rel, data) {
  const file = path.join(ROOT, rel);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(data, null, 2) + '\n', 'utf8');
  console.log('wrote', rel);
}

// checklist item: c(id, text, weekDue?, actionType?, actionLabel?, actionValue?)
function c(id, text, weekDue = null, actionType = 'none', actionLabel = null, actionValue = null) {
  return { id, text, weekDue, actionType, actionLabel, actionValue };
}

// timeline item
function t(id, weekFrom, weekTo, title, description, actionType = 'addAppointment') {
  return { id, weekFrom, weekTo, title, description, actionType };
}

// section
function s(heading, body, bullets = []) {
  return { heading, body, bullets };
}

module.exports = { LAST_UPDATED, REVIEW, ROOT, writeJson, c, t, s };
