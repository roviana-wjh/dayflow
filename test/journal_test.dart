import 'package:dayflow/journal.dart';
import 'package:flutter_test/flutter_test.dart';

JournalEntry entry(int id, RecordKind kind, DateTime at,
        {int minutes = 30, String title = '平静', DateTime? created}) =>
    JournalEntry(
        id: id,
        kind: kind,
        title: title,
        note: '',
        at: at,
        createdAt: created ?? at,
        minutes: kind == RecordKind.study ? minutes : 0);

void main() {
  final now = DateTime(2026, 10, 14, 12);
  test('补记按记录日期计入本周，跨周和未来记录不计入', () {
    final s = JournalSummary([
      entry(1, RecordKind.study, DateTime(2026, 10, 12),
          minutes: 45, created: now),
      entry(2, RecordKind.study, DateTime(2026, 10, 14, 9), minutes: 20),
      entry(3, RecordKind.study, DateTime(2026, 10, 11), minutes: 90),
      entry(4, RecordKind.study, DateTime(2026, 10, 15), minutes: 60),
    ], now);
    expect(s.weekMinutes, [45, 0, 20, 0, 0, 0, 0]);
    expect(s.todayMinutes, 20);
    expect(s.weekTotal, 65);
  });
  test('昨日心情不冒充今日心情，同日取最近一条', () {
    final old = entry(1, RecordKind.mood, DateTime(2026, 10, 13), title: '开心');
    expect(JournalSummary([old], now).todayMood, isNull);
    final latest =
        entry(3, RecordKind.mood, DateTime(2026, 10, 14, 10), title: '满足');
    expect(
        JournalSummary([
          latest,
          old,
          entry(2, RecordKind.mood, DateTime(2026, 10, 14, 8))
        ], now)
            .todayMood,
        latest);
  });
  test('连续天数合并两种记录，同一天不重复；今天未记时保留昨天的连续天数', () {
    final list = [
      entry(1, RecordKind.study, DateTime(2026, 10, 12)),
      entry(2, RecordKind.mood, DateTime(2026, 10, 13)),
      entry(3, RecordKind.study, DateTime(2026, 10, 13))
    ];
    expect(JournalSummary(list, now).streak, 2);
    list.add(entry(4, RecordKind.mood, DateTime(2026, 10, 14, 8)));
    expect(JournalSummary(list, now).streak, 3);
    expect(JournalSummary(list, DateTime(2026, 10, 16)).streak, 0);
  });
  test('连续天数正确跨年', () {
    final s = JournalSummary([
      entry(1, RecordKind.study, DateTime(2025, 12, 31)),
      entry(2, RecordKind.mood, DateTime(2026, 1, 1))
    ], DateTime(2026, 1, 1, 12));
    expect(s.streak, 2);
  });
  test('搜索可匹配主题、笔记、心情和日期，并支持记录类型与日期范围', () {
    final records = [
      entry(1, RecordKind.study, DateTime(2026, 10, 14, 9),
          title: '线性代数', minutes: 45),
      JournalEntry(
          id: 2,
          kind: RecordKind.study,
          title: '英语',
          note: '背单词与阅读',
          at: DateTime(2026, 10, 10, 22),
          createdAt: DateTime(2026, 10, 10),
          minutes: 30),
      JournalEntry(
          id: 3,
          kind: RecordKind.mood,
          title: '开心',
          note: '完成了一小步',
          at: DateTime(2026, 10, 12, 18),
          createdAt: DateTime(2026, 10, 12))
    ];

    expect(filterEntries(records, query: '  线性代数 ').single.id, 1);
    expect(filterEntries(records, query: '阅读').single.id, 2);
    expect(filterEntries(records, query: '完成了一小步').single.id, 3);
    expect(filterEntries(records, query: '2026-10-12').single.id, 3);
    expect(
        filterEntries(records,
                kind: RecordKind.study,
                from: DateTime(2026, 10, 11),
                through: DateTime(2026, 10, 14, 23, 59))
            .map((e) => e.id),
        [1]);
  });
  test('最近记录混合排序，编辑和删除改变统计', () {
    final study = entry(1, RecordKind.study, DateTime(2026, 10, 14, 8));
    final mood = entry(2, RecordKind.mood, DateTime(2026, 10, 14, 10));
    expect(JournalSummary([study, mood], now).recent, [mood, study]);
    final edited =
        entry(1, RecordKind.study, DateTime(2026, 10, 13), minutes: 50);
    expect(JournalSummary([edited, mood], now).todayMinutes, 0);
    expect(JournalSummary([edited, mood], now).weekTotal, 50);
    expect(JournalSummary([mood], now).weekTotal, 0);
  });
  test('拒绝空主题、负数、小数、非法和超大时长', () {
    expect(validateTitle('  '), isNotNull);
    for (final value in ['0', '-3', '1.5', 'abc', '1441', '']) {
      expect(validateMinutes(value), isNotNull);
    }
    expect(validateTitle('数学'), isNull);
    expect(validateMinutes('1440'), isNull);
    expect(validateMinutes(' 30 '), isNull);
  });
}
