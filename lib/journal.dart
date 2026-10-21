import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

enum RecordKind { study, mood }

const moodOptions = [
  ('开心', '😊'),
  ('平静', '🙂'),
  ('满足', '😌'),
  ('难过', '😔'),
  ('焦虑', '😣'),
  ('生气', '😠')
];
String moodEmoji(String mood) => moodOptions
    .firstWhere((item) => item.$1 == mood, orElse: () => ('未记录', '—'))
    .$2;
DateTime calendarDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);
String dayKey(DateTime value) => DateFormat('yyyy-MM-dd').format(value);
String? validateTitle(String? value) => value == null || value.trim().isEmpty
    ? '请输入学习主题'
    : value.trim().length > 80
        ? '学习主题最多 80 个字符'
        : null;
String? validateMinutes(String? value) {
  final n = int.tryParse(value?.trim() ?? '');
  return n == null || n < 1 || n > 1440 ? '请输入 1–1440 之间的整数分钟' : null;
}

class JournalEntry {
  const JournalEntry(
      {required this.id,
      required this.kind,
      required this.title,
      required this.note,
      required this.at,
      required this.createdAt,
      this.minutes = 0});
  final int id;
  final RecordKind kind;
  final String title, note;
  final DateTime at, createdAt;
  final int minutes;
  factory JournalEntry.fromRow(RecordKind kind, Map<String, Object?> row) {
    final study = kind == RecordKind.study;
    return JournalEntry(
        id: row['id'] as int,
        kind: kind,
        title: row[study ? 'title' : 'mood_type'] as String,
        note: row[study ? 'content' : 'note'] as String? ?? '',
        minutes: study ? row['duration_minutes'] as int : 0,
        at: DateTime.parse(row[study ? 'started_at' : 'recorded_at'] as String)
            .toLocal(),
        createdAt: DateTime.parse(row['created_at'] as String).toLocal());
  }
}

/// Filters the locally stored journal records without changing their ordering.
/// Date bounds are inclusive calendar days in the device's local timezone.
List<JournalEntry> filterEntries(
  List<JournalEntry> source, {
  String query = '',
  RecordKind? kind,
  DateTime? from,
  DateTime? through,
}) {
  final needle = query.trim().toLowerCase();
  final firstDay = from == null ? null : calendarDay(from);
  final lastDay = through == null ? null : calendarDay(through);
  return source.where((entry) {
    if (kind != null && entry.kind != kind) return false;
    final day = calendarDay(entry.at);
    if (firstDay != null && day.isBefore(firstDay)) return false;
    if (lastDay != null && day.isAfter(lastDay)) return false;
    if (needle.isEmpty) return true;
    final searchable =
        '${entry.title} ${entry.note} ${dayKey(entry.at)}'.toLowerCase();
    return searchable.contains(needle);
  }).toList();
}

int compareEntries(JournalEntry a, JournalEntry b) => b.at.compareTo(a.at) != 0
    ? b.at.compareTo(a.at)
    : b.createdAt.compareTo(a.createdAt);

class JournalSummary {
  JournalSummary(List<JournalEntry> source, DateTime now) {
    final today = calendarDay(now);
    weekStart = today.subtract(Duration(days: today.weekday - 1));
    final all = source.where((e) => !e.at.isAfter(now)).toList()
      ..sort(compareEntries);
    recent = all.take(5).toList();
    todayMinutes = all
        .where(
            (e) => e.kind == RecordKind.study && dayKey(e.at) == dayKey(today))
        .fold(0, (s, e) => s + e.minutes);
    final moods = all.where(
        (e) => e.kind == RecordKind.mood && dayKey(e.at) == dayKey(today));
    todayMood = moods.isEmpty ? null : moods.first;
    weekMinutes = List.generate(7, (i) {
      final key = dayKey(weekStart.add(Duration(days: i)));
      return all
          .where((e) => e.kind == RecordKind.study && dayKey(e.at) == key)
          .fold<int>(0, (s, e) => s + e.minutes);
    });
    final dates = all.map((e) => dayKey(e.at)).toSet();
    var cursor = today;
    if (!dates.contains(dayKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (dates.contains(dayKey(cursor))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    streak = count;
    totalStudyMinutes = all
        .where((e) => e.kind == RecordKind.study)
        .fold(0, (s, e) => s + e.minutes);
  }
  late final DateTime weekStart;
  late final List<int> weekMinutes;
  late final List<JournalEntry> recent;
  late final JournalEntry? todayMood;
  late final int todayMinutes, totalStudyMinutes;
  late final int streak;
  int get weekTotal => weekMinutes.fold(0, (a, b) => a + b);
}

class LocalRepository {
  late Database db;
  Future<void> open({String? databasePath}) async {
    if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
    db = await openDatabase(
        databasePath ??
            (kIsWeb
                ? 'dayflow.db'
                : join(await getDatabasesPath(), 'dayflow.db')),
        version: 2, onCreate: (db, _) async {
      await db.execute(
          'CREATE TABLE study_records(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, content TEXT, duration_minutes INTEGER NOT NULL, started_at TEXT NOT NULL, created_at TEXT NOT NULL)');
      await db.execute(
          'CREATE TABLE mood_records(id INTEGER PRIMARY KEY AUTOINCREMENT, mood_type TEXT NOT NULL, note TEXT, recorded_at TEXT NOT NULL, created_at TEXT NOT NULL)');
      await db.execute(
          'CREATE TABLE app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute(
            'CREATE TABLE app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      }
    });
  }

  Future<String?> paletteId() async {
    final rows = await db.query('app_settings',
        columns: ['value'], where: 'key = ?', whereArgs: ['palette'], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> savePaletteId(String value) async {
    await db.insert('app_settings', {'key': 'palette', 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<JournalEntry>> entries() async {
    final rows = await Future.wait(
        [db.query('study_records'), db.query('mood_records')]);
    return [
      ...rows[0].map((r) => JournalEntry.fromRow(RecordKind.study, r)),
      ...rows[1].map((r) => JournalEntry.fromRow(RecordKind.mood, r))
    ]..sort(compareEntries);
  }

  void checkDate(DateTime at) {
    if (at.isAfter(DateTime.now()) || at.isBefore(DateTime(2000))) {
      throw ArgumentError('记录日期应在 2000 年至今天之间');
    }
  }

  Future<void> saveStudy(
      {int? id,
      required String title,
      required int minutes,
      required String note,
      required DateTime at}) async {
    final error = validateTitle(title) ?? validateMinutes('$minutes');
    if (error != null) throw ArgumentError(error);
    checkDate(at);
    await save('study_records', id, {
      'title': title.trim(),
      'content': note.trim(),
      'duration_minutes': minutes,
      'started_at': at.toIso8601String()
    });
  }

  Future<void> saveMood(
      {int? id,
      required String mood,
      required String note,
      required DateTime at}) async {
    if (!moodOptions.any((e) => e.$1 == mood)) throw ArgumentError('请选择心情');
    checkDate(at);
    await save('mood_records', id, {
      'mood_type': mood,
      'note': note.trim(),
      'recorded_at': at.toIso8601String()
    });
  }

  Future<void> save(String table, int? id, Map<String, Object?> values) async {
    if (id == null) {
      await db.insert(
          table, {...values, 'created_at': DateTime.now().toIso8601String()});
    } else if (await db
            .update(table, values, where: 'id = ?', whereArgs: [id]) !=
        1) {
      throw StateError('这条记录已不存在，请刷新后重试');
    }
  }

  Future<void> delete(JournalEntry entry) => db.delete(
      entry.kind == RecordKind.study ? 'study_records' : 'mood_records',
      where: 'id = ?',
      whereArgs: [entry.id]);
}
