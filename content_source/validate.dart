// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures
// Validates MomCare+ content JSON against CONTENT_SCHEMA.md.
// Run from repo root:
//   dart run content_source/validate.dart
import 'dart:convert';
import 'dart:io';

final errors = <String>[];
final warnings = <String>[];
final globalItemIds = <String, String>{};
late final Set<String> sourceIds;

const reviewStatuses = {'draft_requires_medical_review', 'approved'};
const stages = {'pre', 'pregnant', 'postpartum'};
const guideCategories = {
  'health', 'nutrition', 'vaccination', 'mental', 'finance', 'lifestyle',
  'partner', 'signs', 'checkup', 'shopping', 'documents', 'hospital_bag', 'warning',
};
const actionTypes = {'none', 'addAppointment', 'openMaps', 'call'};
const thaiGiaoCats = {'talk', 'music', 'movement', 'reading', 'breathing', 'partner', 'journal'};
const tipCats = {'nutrition', 'body', 'mental', 'prep', 'safety'};
const verdicts = {'ok', 'limit', 'avoid'};
final idPattern = RegExp(r'^[a-z0-9_]+$');
final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

void err(String where, String msg) => errors.add('$where: $msg');

dynamic load(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    err(path, 'file not found');
    return null;
  }
  try {
    return jsonDecode(file.readAsStringSync(encoding: utf8));
  } on FormatException catch (e) {
    err(path, 'invalid JSON: ${e.message}');
    return null;
  }
}

bool requireKeys(String where, Map m, List<String> keys) {
  var ok = true;
  for (final k in keys) {
    if (!m.containsKey(k)) {
      err(where, 'missing field "$k"');
      ok = false;
    }
  }
  return ok;
}

void checkString(String where, Map m, String key, {bool nullable = false}) {
  final v = m[key];
  if (v == null && nullable) return;
  if (v is! String || v.trim().isEmpty) err(where, '"$key" must be a non-empty string');
}

void checkStringList(String where, Map m, String key, {bool allowEmpty = true}) {
  final v = m[key];
  if (v is! List || v.any((e) => e is! String || e.trim().isEmpty)) {
    err(where, '"$key" must be a list of non-empty strings');
  } else if (!allowEmpty && v.isEmpty) {
    err(where, '"$key" must not be empty');
  }
}

void checkSources(String where, Map m) {
  final v = m['sources'];
  if (v is! List) {
    err(where, '"sources" must be a list');
    return;
  }
  for (final s in v) {
    if (s is! String || !sourceIds.contains(s)) err(where, 'unknown source id "$s"');
  }
}

void checkMeta(String where, Map m) {
  if (!reviewStatuses.contains(m['reviewStatus'])) err(where, 'bad reviewStatus "${m['reviewStatus']}"');
  if (m['lastUpdated'] is! String || !datePattern.hasMatch(m['lastUpdated'])) {
    err(where, 'lastUpdated must be YYYY-MM-DD');
  }
}

void checkGlobalId(String where, dynamic id) {
  if (id is! String || !idPattern.hasMatch(id)) {
    err(where, 'item id "$id" must be lowercase [a-z0-9_]');
    return;
  }
  final prev = globalItemIds[id];
  if (prev != null) {
    err(where, 'checklist/timeline id "$id" duplicates $prev');
  } else {
    globalItemIds[id] = where;
  }
}

void validateSources() {
  const path = 'assets/content/sources.json';
  final data = load(path);
  final ids = <String>{};
  if (data is Map && data['sources'] is List) {
    for (final s in data['sources']) {
      final where = '$path#${s is Map ? s['id'] : '?'}';
      if (s is! Map) {
        err(path, 'source entry must be an object');
        continue;
      }
      if (!requireKeys(where, s, ['id', 'title', 'organization', 'url'])) continue;
      for (final k in ['id', 'title', 'organization', 'url']) {
        checkString(where, s, k);
      }
      if (!(s['url'] as String).startsWith('https://')) err(where, 'url must be https');
      if (!ids.add(s['id'])) err(where, 'duplicate source id');
    }
    for (final required in ['MOH-MCH', 'WHO-ANC', 'CDC-WARNING']) {
      if (!ids.contains(required)) err(path, 'missing required source $required');
    }
  } else if (data != null) {
    err(path, 'expected {"sources": [...]}');
  }
  sourceIds = ids;
  print('sources.json: ${ids.length} sources');
}

void validateGuides() {
  const dir = 'assets/content/guides';
  final index = load('$dir/index.json');
  if (index is! Map || index['guides'] is! List) {
    err('$dir/index.json', 'expected {"guides": [...]}');
    return;
  }
  final listed = (index['guides'] as List).cast<String>();
  if (listed.toSet().length != listed.length) err('$dir/index.json', 'duplicate entries');
  final onDisk = Directory(dir)
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .where((n) => n.endsWith('.json') && n != 'index.json')
      .toSet();
  for (final n in onDisk.difference(listed.toSet())) {
    warnings.add('$dir/$n exists but is not listed in index.json');
  }
  final guideIds = <String>{};
  var items = 0;
  for (final name in listed) {
    final path = '$dir/$name';
    final g = load(path);
    if (g is! Map) continue;
    if (!requireKeys(path, g, [
      'id', 'stage', 'category', 'title', 'summary', 'order', 'weekFrom', 'weekTo',
      'sections', 'checklist', 'timeline', 'sources', 'lastUpdated', 'reviewStatus',
    ])) continue;
    if (!idPattern.hasMatch(g['id'] ?? '')) err(path, 'bad id');
    if ('${g['id']}.json' != name) err(path, 'file name should match id');
    if (!guideIds.add(g['id'])) err(path, 'duplicate guide id');
    if (!stages.contains(g['stage'])) err(path, 'bad stage "${g['stage']}"');
    if (!guideCategories.contains(g['category'])) err(path, 'bad category "${g['category']}"');
    checkString(path, g, 'title');
    checkString(path, g, 'summary');
    if (g['order'] is! int) err(path, 'order must be int');
    for (final k in ['weekFrom', 'weekTo']) {
      if (g[k] != null && (g[k] is! int || g[k] < 0 || g[k] > 42)) err(path, '$k must be null or 0–42');
    }
    for (final s in (g['sections'] as List? ?? [])) {
      if (s is! Map || !requireKeys('$path#section', s, ['heading', 'body', 'bullets'])) continue;
      checkString('$path#section', s, 'heading');
      checkStringList('$path#section', s, 'bullets');
      if ((s['body'] as String? ?? '').trim().isEmpty && (s['bullets'] as List).isEmpty) {
        err('$path#section "${s['heading']}"', 'section has neither body nor bullets');
      }
    }
    for (final c in (g['checklist'] as List? ?? [])) {
      final where = '$path#checklist:${c is Map ? c['id'] : '?'}';
      if (c is! Map || !requireKeys(where, c, ['id', 'text', 'weekDue', 'actionType', 'actionLabel', 'actionValue'])) continue;
      checkGlobalId(where, c['id']);
      checkString(where, c, 'text');
      if (c['weekDue'] != null && (c['weekDue'] is! int || c['weekDue'] < 0 || c['weekDue'] > 42)) err(where, 'bad weekDue');
      if (!actionTypes.contains(c['actionType'])) err(where, 'bad actionType "${c['actionType']}"');
      if ((c['actionType'] == 'openMaps' || c['actionType'] == 'call') &&
          (c['actionValue'] is! String || (c['actionValue'] as String).isEmpty)) {
        err(where, '${c['actionType']} requires actionValue');
      }
      if (c['actionType'] != 'none') checkString(where, c, 'actionLabel');
      items++;
    }
    for (final t in (g['timeline'] as List? ?? [])) {
      final where = '$path#timeline:${t is Map ? t['id'] : '?'}';
      if (t is! Map || !requireKeys(where, t, ['id', 'weekFrom', 'weekTo', 'title', 'description', 'actionType'])) continue;
      checkGlobalId(where, t['id']);
      checkString(where, t, 'title');
      checkString(where, t, 'description');
      if (t['weekFrom'] is! int || t['weekTo'] is! int || t['weekFrom'] > t['weekTo']) err(where, 'bad week range');
      if (!actionTypes.contains(t['actionType'])) err(where, 'bad actionType');
      items++;
    }
    checkSources(path, g);
    checkMeta(path, g);
  }
  print('guides: ${listed.length} articles, $items checklist/timeline items');
}

void validateDaily(String path, String type, Set<String> cats) {
  final d = load(path);
  if (d is! Map) return;
  requireKeys(path, d, ['version', 'type', 'lastUpdated', 'reviewStatus', 'items']);
  if (d['type'] != type) err(path, 'type must be "$type"');
  checkMeta(path, d);
  final days = <int>{};
  for (final it in (d['items'] as List? ?? [])) {
    final where = '$path#day:${it is Map ? it['day'] : '?'}';
    if (it is! Map) continue;
    final keys = ['day', 'week', 'category', 'title', 'body', 'sources'];
    if (type == 'thai_giao') keys.add('durationMin');
    if (!requireKeys(where, it, keys)) continue;
    final day = it['day'], week = it['week'];
    if (day is! int || day < 1 || day > 294) {
      err(where, 'day out of range');
      continue;
    }
    if (!days.add(day)) err(where, 'duplicate day');
    if (week is! int || week != (day - 1) ~/ 7) err(where, 'week $week does not match day $day');
    if (!cats.contains(it['category'])) err(where, 'bad category "${it['category']}"');
    checkString(where, it, 'title');
    checkString(where, it, 'body');
    if (type == 'thai_giao' && (it['durationMin'] is! int || it['durationMin'] <= 0)) err(where, 'durationMin must be positive int');
    checkSources(where, it);
  }
  final missing = [for (var i = 1; i <= 294; i++) if (!days.contains(i)) i];
  if (missing.isNotEmpty) err(path, 'missing days: ${missing.take(20).join(', ')}${missing.length > 20 ? '…' : ''}');
  print('${path.split('/').last}: ${days.length} days');
}

void validateWeeks() {
  const path = 'assets/content/weeks_v2.json';
  final d = load(path);
  if (d is! Map) return;
  requireKeys(path, d, ['version', 'lastUpdated', 'reviewStatus', 'weeks']);
  checkMeta(path, d);
  final seen = <int>{};
  for (final w in (d['weeks'] as List? ?? [])) {
    final where = '$path#week:${w is Map ? w['week'] : '?'}';
    if (w is! Map) continue;
    if (!requireKeys(where, w, [
      'week', 'image', 'sizeCompare', 'lengthCm', 'weightG', 'babyDevelopment', 'motherChanges',
      'commonSymptoms', 'todoThisWeek', 'examsThisWeek', 'nutritionFocus', 'redFlags', 'sources',
    ])) continue;
    final n = w['week'];
    if (n is! int || n < 0 || n > 42) {
      err(where, 'week out of range');
      continue;
    }
    if (!seen.add(n)) err(where, 'duplicate week');
    final img = 'assets/images/weeks/week_${n.toString().padLeft(2, '0')}.webp';
    if (w['image'] != img) err(where, 'image should be $img');
    checkString(where, w, 'sizeCompare', nullable: true);
    for (final k in ['lengthCm', 'weightG']) {
      if (w[k] != null && (w[k] is! num || w[k] <= 0)) err(where, '$k must be null or positive number');
    }
    checkString(where, w, 'babyDevelopment');
    checkString(where, w, 'motherChanges');
    for (final k in ['commonSymptoms', 'todoThisWeek', 'nutritionFocus', 'redFlags']) {
      checkStringList(where, w, k, allowEmpty: false);
    }
    checkStringList(where, w, 'examsThisWeek');
    checkSources(where, w);
  }
  final missing = [for (var i = 0; i <= 42; i++) if (!seen.contains(i)) i];
  if (missing.isNotEmpty) err(path, 'missing weeks: ${missing.join(', ')}');
  // Duplicate text check: every week should be individually written.
  final dev = <String, int>{};
  for (final w in (d['weeks'] as List? ?? [])) {
    if (w is! Map) continue;
    final prev = dev[w['babyDevelopment']];
    if (prev != null) err('$path#week:${w['week']}', 'babyDevelopment identical to week $prev');
    dev[w['babyDevelopment'] as String? ?? ''] = w['week'];
  }
  print('weeks_v2.json: ${seen.length} weeks');
}

void validateFoods() {
  const path = 'assets/content/foods.json';
  final d = load(path);
  if (d is! Map) return;
  requireKeys(path, d, ['version', 'lastUpdated', 'reviewStatus', 'foods']);
  checkMeta(path, d);
  final ids = <String>{};
  final names = <String>{};
  final counts = <String, int>{};
  for (final f in (d['foods'] as List? ?? [])) {
    final where = '$path#${f is Map ? f['id'] : '?'}';
    if (f is! Map || !requireKeys(where, f, ['id', 'name', 'aliases', 'group', 'verdict', 'reason', 'tip', 'sources'])) continue;
    if (f['id'] is! String || !idPattern.hasMatch(f['id'])) err(where, 'bad id');
    if (!ids.add(f['id'])) err(where, 'duplicate id');
    if (!names.add((f['name'] as String).toLowerCase())) err(where, 'duplicate name');
    checkString(where, f, 'name');
    checkStringList(where, f, 'aliases');
    checkString(where, f, 'group');
    if (!verdicts.contains(f['verdict'])) err(where, 'bad verdict "${f['verdict']}"');
    counts[f['verdict']] = (counts[f['verdict']] ?? 0) + 1;
    checkString(where, f, 'reason');
    checkString(where, f, 'tip');
    checkSources(where, f);
  }
  print('foods.json: ${ids.length} foods $counts');
}

void main() {
  validateSources();
  validateGuides();
  validateWeeks();
  validateDaily('assets/content/daily/thai_giao.json', 'thai_giao', thaiGiaoCats);
  validateDaily('assets/content/daily/daily_tips.json', 'daily_tip', tipCats);
  validateFoods();
  for (final w in warnings) {
    print('WARNING: $w');
  }
  if (errors.isEmpty) {
    print('OK: all content files valid.');
  } else {
    for (final e in errors) {
      print('ERROR: $e');
    }
    print('${errors.length} error(s).');
    exit(1);
  }
}
