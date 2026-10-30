// Exports all medical content to one CSV per content type for doctor review.
// Run from the repo root: node content_source/build/export_review.js
// The "Kết luận" columns are filled in by the reviewer. This script never
// changes reviewStatus: only a medical reviewer can approve content.
const fs = require('fs');
const path = require('path');

const CONTENT = 'assets/content';
const OUT = 'content_source/review';
const read = (p) => JSON.parse(fs.readFileSync(path.join(CONTENT, p), 'utf8'));
const cell = (v) => `"${String(v ?? '').replace(/"/g, '""')}"`;
const list = (a) => (a || []).join('; ');
const REVIEW = ['Kết luận (Duyệt/Sửa/Bỏ)', 'Nội dung sửa/Ghi chú', 'Người duyệt', 'Ngày duyệt'];

function write(name, headers, rows) {
  const lines = [headers.concat(REVIEW), ...rows.map((r) => r.concat(REVIEW.map(() => '')))]
    .map((r) => r.map(cell).join(','));
  // BOM so Excel opens the file as UTF-8.
  fs.writeFileSync(path.join(OUT, name), '﻿' + lines.join('\r\n') + '\r\n');
  console.log(`${name}: ${rows.length} rows`);
}

fs.mkdirSync(OUT, { recursive: true });

const guideRows = [];
for (const file of read('guides/index.json').guides) {
  const g = read(`guides/${file}`);
  const src = list(g.sources);
  guideRows.push([g.id, 'Tổng quan', g.stage, g.title, g.summary, src]);
  for (const s of g.sections || []) {
    guideRows.push([g.id, 'Mục', g.stage, s.heading, [s.body, ...(s.bullets || [])].filter(Boolean).join(' | '), src]);
  }
  for (const c of g.checklist || []) {
    guideRows.push([g.id, 'Checklist', g.stage, c.id, c.text, src]);
  }
  for (const t of g.timeline || []) {
    guideRows.push([g.id, 'Mốc', g.stage, `${t.id} (tuần ${t.weekFrom}-${t.weekTo})`, `${t.title}: ${t.description}`, src]);
  }
}
write('1_cam_nang.csv', ['Bài', 'Loại', 'Giai đoạn', 'Mục', 'Nội dung', 'Nguồn'], guideRows);

write('2_tuan_thai.csv',
  ['Tuần', 'So sánh', 'Dài (cm)', 'Nặng (g)', 'Bé phát triển', 'Cơ thể mẹ', 'Triệu chứng', 'Việc nên làm', 'Khám', 'Dinh dưỡng', 'Dấu hiệu cần khám', 'Nguồn'],
  read('weeks_v2.json').weeks.map((w) => [w.week, w.sizeCompare, w.lengthCm, w.weightG, w.babyDevelopment, w.motherChanges,
    list(w.commonSymptoms), list(w.todoThisWeek), list(w.examsThisWeek), list(w.nutritionFocus), list(w.redFlags), list(w.sources)]));

write('3_thuc_pham.csv', ['ID', 'Tên', 'Tên khác', 'Nhóm', 'Kết luận', 'Lý do', 'Mẹo', 'Nguồn'],
  read('foods.json').foods.map((f) => [f.id, f.name, list(f.aliases), f.group, f.verdict, f.reason, f.tip, list(f.sources)]));

const daily = (file) => read(`daily/${file}`).items.map((i) => [i.day, i.week, i.category, i.title, i.body]);
write('4_thai_giao.csv', ['Ngày', 'Tuần', 'Loại', 'Tiêu đề', 'Nội dung'], daily('thai_giao.json'));
write('5_meo_hang_ngay.csv', ['Ngày', 'Tuần', 'Loại', 'Tiêu đề', 'Nội dung'], daily('daily_tips.json'));

const fertile = read('fertile_guidance.json');
write('6_canh_ngay.csv', ['ID', 'Nhóm', 'Nội dung', 'Nguồn'],
  fertile.items.map((i) => [i.id, i.group, i.text, list(fertile.sources)]));
