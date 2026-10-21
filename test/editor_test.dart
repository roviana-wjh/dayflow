import 'package:dayflow/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryRepository extends LocalRepository {
  List<JournalEntry> records = [];
  int saves = 0;
  @override
  Future<List<JournalEntry>> entries() async =>
      records.toList()..sort(compareEntries);
  @override
  Future<void> saveStudy(
      {int? id,
      required String title,
      required int minutes,
      required String note,
      required DateTime at}) async {
    saves++;
    records.removeWhere((e) => e.id == id);
    records.add(JournalEntry(
        id: id ?? saves,
        kind: RecordKind.study,
        title: title.trim(),
        note: note,
        at: at,
        createdAt: DateTime.now(),
        minutes: minutes));
  }

  @override
  Future<void> delete(JournalEntry entry) async =>
      records.removeWhere((e) => e.id == entry.id);

  @override
  Future<void> saveMood(
      {int? id,
      required String mood,
      required String note,
      required DateTime at}) async {
    saves++;
    records.removeWhere((e) => e.id == id);
    records.add(JournalEntry(
        id: id ?? saves,
        kind: RecordKind.mood,
        title: mood,
        note: note.trim(),
        at: at,
        createdAt: DateTime.now()));
  }
}

void main() {
  testWidgets('学习表单阻止无效输入，保存后首页同步；编辑与删除确认有效', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryRepository();
    await tester.pumpWidget(DayFlowApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('记录学习'));
    await tester.tap(find.text('记录学习'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('请输入学习主题'), findsOneWidget);
    expect(repo.saves, 0);
    await tester.enterText(find.byKey(const ValueKey('study-title')), '线性代数');
    await tester.enterText(find.byKey(const ValueKey('study-minutes')), '-1');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('请输入 1–1440 之间的整数分钟'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('study-minutes')), '45');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repo.saves, 1);
    expect(find.text('45 / 60 分钟'), findsOneWidget);
    await tester.tap(find.text('学习').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('线性代数'));
    await tester.tap(find.text('线性代数'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('study-minutes')), '60');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repo.records.single.minutes, 60);
    await tester.ensureVisible(find.byTooltip('管理记录'));
    await tester.tap(find.byTooltip('管理记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(repo.records, hasLength(1));
    await tester.tap(find.byTooltip('管理记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(repo.records, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('小屏幕和键盘下表单可以滚动，不发生布局溢出', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final repo = MemoryRepository();
    await tester.pumpWidget(DayFlowApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记录学习'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('record-note')));
    await tester.enterText(find.byKey(const ValueKey('record-note')), '笔记');
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(repo.saves, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('心情新增及修改同步到首页，日期选择使用中文', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryRepository();
    await tester.pumpWidget(DayFlowApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记录心情'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('😊 开心'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('record-note')), '完成了一小步');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repo.records.single.title, '开心');
    expect(find.text('开心'), findsWidgets);
    await tester.tap(find.text('心情').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('管理记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('😌 满足'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    expect(find.text('选择记录日期'), findsOneWidget);
    await tester.tap(find.text('取消').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repo.records.single.title, '满足');
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('全局搜索可查找学习笔记，颜色按钮切换主题', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryRepository()
      ..records = [
        JournalEntry(
            id: 1,
            kind: RecordKind.study,
            title: '数学复习',
            note: '专注练习积分题',
            at: DateTime.now(),
            createdAt: DateTime.now(),
            minutes: 40),
        JournalEntry(
            id: 2,
            kind: RecordKind.mood,
            title: '开心',
            note: '今天状态很好',
            at: DateTime.now().subtract(const Duration(days: 1)),
            createdAt: DateTime.now())
      ];
    await tester.pumpWidget(DayFlowApp(repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('搜索记录'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('search-keyword')), '专注练习');
    await tester.pumpAndSettle();
    expect(find.text('数学复习'), findsOneWidget);
    expect(find.text('开心'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('颜色样式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('海盐蓝'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .theme!
            .colorScheme
            .primary,
        paletteFor('ocean').primary);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
