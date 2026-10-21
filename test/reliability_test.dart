import 'dart:async';
import 'package:dayflow/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FailureRepository extends LocalRepository {
  int opens = 0, writes = 0;
  final writeGate = Completer<void>();
  @override
  Future<void> open({String? databasePath}) async {
    if (++opens == 1) throw StateError('test database unavailable');
  }

  @override
  Future<List<JournalEntry>> entries() async => [];
  @override
  Future<void> saveStudy(
      {int? id,
      required String title,
      required int minutes,
      required String note,
      required DateTime at}) async {
    writes++;
    if (writes == 1) await writeGate.future;
  }
}

void main() {
  testWidgets('数据库启动失败显示重试，恢复后可进入首页', (tester) async {
    final repo = FailureRepository();
    await tester.pumpWidget(DayFlowApp(repository: repo, initialize: true));
    await tester.pumpAndSettle();
    expect(find.text('暂时无法打开本地记录'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(repo.opens, 2);
    expect(find.text('今日学习'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('保存时防重复提交和返回；失败保留输入并可重试', (tester) async {
    final repo = FailureRepository();
    await tester.pumpWidget(MaterialApp(
        home: RecordEditor(repository: repo, kind: RecordKind.study)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('study-title')), '保存恢复验证');
    await tester.enterText(find.byKey(const ValueKey('study-minutes')), '35');
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(repo.writes, 1);
    final button =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, '保存中…'));
    expect(button.onPressed, isNull);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
    repo.writeGate.completeError(StateError('test storage failure'));
    await tester.pumpAndSettle();
    expect(find.text('保存失败，输入已保留，请重试。'), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('study-title')))
            .controller!
            .text,
        '保存恢复验证');
    expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('study-minutes')))
            .controller!
            .text,
        '35');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repo.writes, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
