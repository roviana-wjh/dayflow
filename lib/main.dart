import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'journal.dart';
export 'journal.dart';

const ink = Color(0xFF26342F), muted = Color(0xFF77827B);

class DayPalette {
  const DayPalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.background,
    required this.surface,
    required this.soft,
    required this.outline,
  });

  final String id, name;
  final Color primary, background, surface, soft, outline;
}

const dayPalettes = <DayPalette>[
  DayPalette(
      id: 'sage',
      name: '鼠尾草绿',
      primary: Color(0xFF496C5A),
      background: Color(0xFFF7F8F4),
      surface: Colors.white,
      soft: Color(0xFFE9F0E9),
      outline: Color(0xFFE6EAE3)),
  DayPalette(
      id: 'ocean',
      name: '海盐蓝',
      primary: Color(0xFF416B83),
      background: Color(0xFFF3F7F9),
      surface: Color(0xFFFFFFFF),
      soft: Color(0xFFE5EFF4),
      outline: Color(0xFFDCE7EC)),
  DayPalette(
      id: 'lavender',
      name: '柔雾紫',
      primary: Color(0xFF74628B),
      background: Color(0xFFF7F5F9),
      surface: Color(0xFFFFFFFF),
      soft: Color(0xFFEEE9F4),
      outline: Color(0xFFE7E0ED)),
  DayPalette(
      id: 'peach',
      name: '暖杏色',
      primary: Color(0xFF9A644B),
      background: Color(0xFFFAF6F2),
      surface: Color(0xFFFFFFFF),
      soft: Color(0xFFF4EAE2),
      outline: Color(0xFFECE1D7)),
  DayPalette(
      id: 'rose',
      name: '浅玫瑰',
      primary: Color(0xFF955C69),
      background: Color(0xFFFAF5F6),
      surface: Color(0xFFFFFFFF),
      soft: Color(0xFFF3E7EA),
      outline: Color(0xFFEBDDE1)),
];

DayPalette paletteFor(String id) => dayPalettes
    .firstWhere((palette) => palette.id == id, orElse: () => dayPalettes.first);

ThemeData themeForPalette(DayPalette palette) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        surface: palette.surface,
        primary: palette.primary,
        onSurface: ink),
    scaffoldBackgroundColor: palette.background,
    dividerColor: palette.outline,
    cardColor: palette.surface,
    textTheme: const TextTheme(
        headlineLarge:
            TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: ink),
        titleLarge:
            TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: ink),
        titleMedium:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ink),
        bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.6)),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: palette.outline)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: palette.outline)),
        contentPadding: const EdgeInsets.all(16)),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            side: BorderSide(color: palette.outline),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)))),
    navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.soft,
        elevation: 0,
        height: 72));

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DayFlowApp(repository: LocalRepository(), initialize: true));
}

class DayFlowApp extends StatefulWidget {
  const DayFlowApp(
      {super.key, required this.repository, this.initialize = false});
  final LocalRepository repository;
  final bool initialize;

  @override
  State<DayFlowApp> createState() => _DayFlowAppState();
}

class _DayFlowAppState extends State<DayFlowApp> {
  String paletteId = dayPalettes.first.id;

  void changePalette(String id) {
    if (paletteId != id) setState(() => paletteId = id);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DayFlow',
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: themeForPalette(paletteFor(paletteId)),
      home: widget.initialize
          ? Startup(
              repository: widget.repository,
              paletteId: paletteId,
              onPaletteChanged: changePalette)
          : HomeShell(
              repository: widget.repository,
              paletteId: paletteId,
              onPaletteChanged: changePalette));
}

class Startup extends StatefulWidget {
  const Startup(
      {super.key,
      required this.repository,
      required this.paletteId,
      required this.onPaletteChanged});
  final LocalRepository repository;
  final String paletteId;
  final ValueChanged<String> onPaletteChanged;
  @override
  State<Startup> createState() => _StartupState();
}

class _StartupState extends State<Startup> {
  late Future<void> opening;
  @override
  void initState() {
    super.initState();
    opening = widget.repository.open();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
      future: opening,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return HomeShell(
              repository: widget.repository,
              paletteId: widget.paletteId,
              onPaletteChanged: widget.onPaletteChanged,
              persistSettings: true);
        }
        return Scaffold(
            body: Center(
                child: snapshot.hasError
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('暂时无法打开本地记录'),
                          const SizedBox(height: 8),
                          SelectableText('${snapshot.error}',
                              style: const TextStyle(color: muted)),
                          const SizedBox(height: 20),
                          FilledButton(
                              onPressed: () => setState(() {
                                    opening = widget.repository.open();
                                  }),
                              child: const Text('重试'))
                        ]))
                    : const Column(mainAxisSize: MainAxisSize.min, children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(height: 20),
                        Text('正在打开你的记录…')
                      ])));
      });
}

typedef EditRecord = Future<void> Function(RecordKind kind,
    {JournalEntry? entry, String? mood});

class HomeShell extends StatefulWidget {
  const HomeShell(
      {super.key,
      required this.repository,
      required this.paletteId,
      required this.onPaletteChanged,
      this.persistSettings = false});
  final LocalRepository repository;
  final String paletteId;
  final ValueChanged<String> onPaletteChanged;
  final bool persistSettings;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int index = 0, request = 0;
  List<JournalEntry> entries = [];
  bool loading = true;
  String? error;
  Timer? dayTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    reload();
    if (widget.persistSettings) restorePalette();
    scheduleDayRefresh();
  }

  Future<void> restorePalette() async {
    try {
      final id = await widget.repository.paletteId();
      if (id != null && dayPalettes.any((palette) => palette.id == id)) {
        widget.onPaletteChanged(id);
      }
    } catch (_) {
      // A missing preference should not prevent access to the journal.
    }
  }

  Future<void> choosePalette(String id) async {
    widget.onPaletteChanged(id);
    if (!widget.persistSettings) return;
    try {
      await widget.repository.savePaletteId(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('样式已切换，但暂时无法保存设置')));
      }
    }
  }

  Future<void> openSearch() async {
    await Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (_) => SearchPage(
            entries: entries,
            repository: widget.repository,
            edit: edit,
            onDelete: remove)));
  }

  Future<void> openPalettePicker() async {
    await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('选择颜色样式',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600))),
                  const SizedBox(height: 16),
                  ...dayPalettes.map((palette) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                              color: palette.soft,
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.outline)),
                          child: Icon(Icons.circle,
                              color: palette.primary, size: 22)),
                      title: Text(palette.name),
                      trailing: widget.paletteId == palette.id
                          ? Icon(Icons.check_circle,
                              color: Theme.of(sheetContext).colorScheme.primary)
                          : null,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        choosePalette(palette.id);
                      }))
                ]))));
  }

  void scheduleDayRefresh() {
    dayTimer?.cancel();
    final now = DateTime.now();
    dayTimer =
        Timer(DateTime(now.year, now.month, now.day + 1).difference(now), () {
      reload();
      scheduleDayRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      reload();
      scheduleDayRefresh();
    }
  }

  @override
  void dispose() {
    dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> reload() async {
    final current = ++request;
    try {
      final result = await widget.repository.entries();
      if (mounted && current == request) {
        setState(() {
          entries = result;
          loading = false;
          error = null;
        });
      }
    } catch (_) {
      if (mounted && current == request) {
        setState(() {
          loading = false;
          error = '读取失败，请重试。已有记录仍保存在本地。';
        });
      }
    }
  }

  Future<void> edit(RecordKind kind,
      {JournalEntry? entry, String? mood}) async {
    final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => RecordEditor(
            repository: widget.repository,
            kind: kind,
            entry: entry,
            initialMood: mood));
    if (saved == true && mounted) {
      await reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(entry == null ? '记录已保存' : '记录已更新')));
      }
    }
  }

  Future<void> remove(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('删除这条记录？'),
                content: Text('“${entry.title}”将被删除，对应统计会同时更新。'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700),
                      child: const Text('删除'))
                ]));
    if (confirmed != true) return;
    try {
      await widget.repository.delete(entry);
      await reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now(),
        summary = JournalSummary(entries, DateTime.now());
    final colors = paletteFor(widget.paletteId);
    final compactHeader = MediaQuery.sizeOf(context).width < 390;
    final Widget page = switch (index) {
      0 => DashboardPage(
          summary: summary,
          now: now,
          edit: edit,
          navigate: (i) => setState(() => index = i),
          onDelete: remove),
      1 => StudyPage(
          entries: entries.where((e) => e.kind == RecordKind.study).toList(),
          summary: summary,
          now: now,
          edit: edit,
          onDelete: remove),
      2 => MoodPage(
          entries: entries.where((e) => e.kind == RecordKind.mood).toList(),
          edit: edit,
          onDelete: remove),
      _ => ProfilePage(entries: entries, summary: summary)
    };
    return Scaffold(
        body: SafeArea(
            bottom: false,
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(children: [
                      Padding(
                          padding: EdgeInsets.fromLTRB(compactHeader ? 16 : 24,
                              20, compactHeader ? 8 : 16, 8),
                          child: Row(children: [
                            Icon(Icons.spa_outlined,
                                color: colors.primary, size: 23),
                            const SizedBox(width: 10),
                            const Text('DayFlow',
                                style: TextStyle(
                                    fontSize: 19, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            if (!compactHeader)
                              Text(['今日', '学习', '心情', '我的'][index],
                                  style: const TextStyle(color: muted)),
                            IconButton(
                                tooltip: '搜索记录',
                                onPressed: openSearch,
                                icon: const Icon(Icons.search,
                                    size: 21, color: muted)),
                            IconButton(
                                tooltip: '颜色样式',
                                onPressed: openPalettePicker,
                                icon: Icon(Icons.palette_outlined,
                                    size: 20, color: colors.primary)),
                            if (!compactHeader)
                              IconButton(
                                  tooltip: '刷新记录',
                                  onPressed: reload,
                                  icon: const Icon(Icons.refresh,
                                      size: 19, color: muted))
                          ])),
                      if (error != null)
                        Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Expanded(child: Text(error!)),
                              TextButton(
                                  onPressed: reload, child: const Text('重试'))
                            ])),
                      Expanded(
                          child: loading
                              ? const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : RefreshIndicator(
                                  onRefresh: reload, child: page))
                    ])))),
        bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.outline))),
            child: NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (v) => setState(() => index = v),
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      selectedIcon: Icon(Icons.grid_view_rounded),
                      label: '今日'),
                  NavigationDestination(
                      icon: Icon(Icons.menu_book_outlined), label: '学习'),
                  NavigationDestination(
                      icon: Icon(Icons.favorite_border), label: '心情'),
                  NavigationDestination(
                      icon: Icon(Icons.person_outline), label: '我的')
                ])));
  }
}

class PageContent extends StatelessWidget {
  const PageContent({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      children: children);
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: muted))
      ]));
}

class Surface extends StatelessWidget {
  const Surface(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
      padding: padding,
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor)),
      child: child);
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        if (trailing != null) trailing!
      ]));
}

class DashboardPage extends StatelessWidget {
  const DashboardPage(
      {super.key,
      required this.summary,
      required this.now,
      required this.edit,
      required this.navigate,
      required this.onDelete});
  final JournalSummary summary;
  final DateTime now;
  final EditRecord edit;
  final ValueChanged<int> navigate;
  final Future<void> Function(JournalEntry) onDelete;
  @override
  Widget build(BuildContext context) => PageContent(children: [
        PageHeading(
            '把今天，慢慢记下来',
            '${DateFormat('M 月 d 日').format(now)} · ${[
              '星期一',
              '星期二',
              '星期三',
              '星期四',
              '星期五',
              '星期六',
              '星期日'
            ][now.weekday - 1]}'),
        LayoutBuilder(builder: (context, size) {
          final cards = [
            MetricCard(
                label: '今日学习',
                value: '${summary.todayMinutes}',
                suffix: '分钟',
                icon: Icons.menu_book_outlined),
            MetricCard(
                label: '今日心情',
                value: summary.todayMood?.title ?? '未记录',
                suffix: summary.todayMood == null
                    ? '留一点时间给自己'
                    : moodEmoji(summary.todayMood!.title),
                icon: Icons.favorite_border)
          ];
          return size.maxWidth < 310
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [cards[0], const SizedBox(height: 12), cards[1]])
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1])
                ]);
        }),
        const SizedBox(height: 16),
        Surface(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
                child: Text('每日学习目标', style: TextStyle(color: muted))),
            Text('${summary.todayMinutes} / 60 分钟')
          ]),
          const SizedBox(height: 14),
          ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                  value: (summary.todayMinutes / 60).clamp(0, 1).toDouble(),
                  minHeight: 5,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest)),
          const SizedBox(height: 18),
          Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.local_fire_department_outlined,
                    size: 19, color: Theme.of(context).colorScheme.primary),
                Text('连续记录 ${summary.streak} 天',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
                const Text('每一天的小积累',
                    style: TextStyle(color: muted, fontSize: 12))
              ])
        ])),
        const SizedBox(height: 20),
        Wrap(spacing: 12, runSpacing: 12, children: [
          FilledButton.icon(
              onPressed: () => edit(RecordKind.study),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('记录学习')),
          OutlinedButton.icon(
              onPressed: () => edit(RecordKind.mood),
              icon: const Icon(Icons.favorite_border, size: 18),
              label: const Text('记录心情'))
        ]),
        const SizedBox(height: 30),
        SectionHeading('本周学习',
            trailing: TextButton(
                onPressed: () => navigate(1), child: const Text('查看全部'))),
        WeekChart(summary: summary, now: now),
        const SizedBox(height: 30),
        const SectionHeading('最近记录'),
        if (summary.recent.isEmpty)
          const EmptyState('从第一条记录开始', '记录一段学习，或此刻的心情。')
        else
          ...summary.recent.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecordTile(entry: e, edit: edit, onDelete: onDelete)))
      ]);
}

class MetricCard extends StatelessWidget {
  const MetricCard(
      {super.key,
      required this.label,
      required this.value,
      required this.suffix,
      required this.icon});
  final String label, value, suffix;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Surface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: muted, size: 20),
        const SizedBox(height: 14),
        Text(label, style: const TextStyle(color: muted)),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w600, height: 1.3)),
        const SizedBox(height: 5),
        Text(suffix, style: const TextStyle(color: muted, fontSize: 12))
      ]));
}

class WeekChart extends StatelessWidget {
  const WeekChart({super.key, required this.summary, required this.now});
  final JournalSummary summary;
  final DateTime now;
  @override
  Widget build(BuildContext context) {
    final peak = math.max(60, summary.weekMinutes.reduce(math.max));
    final colors = Theme.of(context).colorScheme;
    return Surface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('${summary.weekTotal}',
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
            const Text('分钟', style: TextStyle(color: muted))
          ]),
      Text(
          '${DateFormat('M/d').format(summary.weekStart)} — ${DateFormat('M/d').format(summary.weekStart.add(const Duration(days: 6)))}',
          style: const TextStyle(fontSize: 12, color: muted)),
      const SizedBox(height: 24),
      Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final date = summary.weekStart.add(Duration(days: i)),
                amount = summary.weekMinutes[i];
            final today = dayKey(date) == dayKey(now),
                future = date.isAfter(calendarDay(now));
            return Expanded(
                child: Semantics(
                    label: '${DateFormat('M月d日').format(date)}，$amount 分钟',
                    child: Column(children: [
                      Text(amount == 0 ? (future ? '—' : '0') : '$amount',
                          style: TextStyle(
                              fontSize: 11,
                              color: today ? colors.primary : muted)),
                      const SizedBox(height: 8),
                      SizedBox(
                          height: 80,
                          child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                  width: 18,
                                  height: amount == 0
                                      ? 2
                                      : math.max(4, 80 * amount / peak),
                                  decoration: BoxDecoration(
                                      color: amount == 0
                                          ? Theme.of(context).dividerColor
                                          : today
                                              ? colors.primary
                                              : colors.primaryContainer,
                                      borderRadius:
                                          BorderRadius.circular(4))))),
                      const SizedBox(height: 10),
                      Text(['一', '二', '三', '四', '五', '六', '日'][i],
                          style: TextStyle(
                              fontSize: 12,
                              color: today ? colors.primary : muted))
                    ])));
          })),
      if (summary.weekTotal == 0)
        const Padding(
            padding: EdgeInsets.only(top: 18),
            child: Text('本周还没有学习记录，慢慢来。',
                style: TextStyle(color: muted, fontSize: 12)))
    ]));
  }
}

class StudyPage extends StatelessWidget {
  const StudyPage(
      {super.key,
      required this.entries,
      required this.summary,
      required this.now,
      required this.edit,
      required this.onDelete});
  final List<JournalEntry> entries;
  final JournalSummary summary;
  final DateTime now;
  final EditRecord edit;
  final Future<void> Function(JournalEntry) onDelete;
  @override
  Widget build(BuildContext context) => PageContent(children: [
        const PageHeading('每一份专注，都算数', '记录学习，也看见自己的进步。'),
        WeekChart(summary: summary, now: now),
        const SizedBox(height: 20),
        Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
                onPressed: () => edit(RecordKind.study),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('记录学习'))),
        const SizedBox(height: 30),
        SectionHeading('学习记录',
            trailing: Text('${entries.length} 条',
                style: const TextStyle(color: muted, fontSize: 12))),
        ...recordGroups(context, entries, edit, onDelete),
        if (entries.isEmpty) const EmptyState('还没有学习记录', '可以记录今天，也可以补记过去的学习。')
      ]);
}

class MoodPage extends StatelessWidget {
  const MoodPage(
      {super.key,
      required this.entries,
      required this.edit,
      required this.onDelete});
  final List<JournalEntry> entries;
  final EditRecord edit;
  final Future<void> Function(JournalEntry) onDelete;
  @override
  Widget build(BuildContext context) => PageContent(children: [
        const PageHeading('此刻的你，感觉如何', '每一种心情，都值得被温柔记录。'),
        Surface(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionHeading('选一个心情'),
          Wrap(
              spacing: 10,
              runSpacing: 10,
              children: moodOptions
                  .map((m) => ActionChip(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 10),
                      avatar: Text(m.$2, style: const TextStyle(fontSize: 20)),
                      label: Text(m.$1),
                      onPressed: () => edit(RecordKind.mood, mood: m.$1)))
                  .toList())
        ])),
        const SizedBox(height: 30),
        SectionHeading('心情记录',
            trailing: Text('${entries.length} 条',
                style: const TextStyle(color: muted, fontSize: 12))),
        ...recordGroups(context, entries, edit, onDelete),
        if (entries.isEmpty) const EmptyState('留一点空间给自己', '写下感受，不需要很长，也不需要完美。')
      ]);
}

class SearchPage extends StatefulWidget {
  const SearchPage(
      {super.key,
      required this.entries,
      required this.repository,
      required this.edit,
      required this.onDelete});

  final List<JournalEntry> entries;
  final LocalRepository repository;
  final EditRecord edit;
  final Future<void> Function(JournalEntry) onDelete;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController query;
  late List<JournalEntry> entries;
  RecordKind? kind;
  DateTime? from, through;

  @override
  void initState() {
    super.initState();
    query = TextEditingController();
    entries = widget.entries;
    query.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    query
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  Future<void> pickRange() async {
    final now = calendarDay(DateTime.now());
    final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: now,
        initialDateRange: from == null || through == null
            ? null
            : DateTimeRange(start: from!, end: through!),
        helpText: '筛选日期范围',
        cancelText: '取消',
        confirmText: '确定');
    if (picked != null && mounted) {
      setState(() {
        from = calendarDay(picked.start);
        through = calendarDay(picked.end);
      });
    }
  }

  void setRecentDays(int days) {
    final today = calendarDay(DateTime.now());
    setState(() {
      from = today.subtract(Duration(days: days - 1));
      through = today;
    });
  }

  void clearFilters() {
    query.clear();
    setState(() {
      kind = null;
      from = null;
      through = null;
    });
  }

  Future<void> refreshEntries() async {
    try {
      final updated = await widget.repository.entries();
      if (mounted) setState(() => entries = updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('刷新记录失败，请稍后重试')));
      }
    }
  }

  Future<void> editEntry(JournalEntry entry) async {
    await widget.edit(entry.kind, entry: entry);
    await refreshEntries();
  }

  Future<void> deleteEntry(JournalEntry entry) async {
    await widget.onDelete(entry);
    await refreshEntries();
  }

  @override
  Widget build(BuildContext context) {
    final results = filterEntries(entries,
        query: query.text, kind: kind, from: from, through: through);
    final today = calendarDay(DateTime.now());
    final isSevenDays =
        from == today.subtract(const Duration(days: 6)) && through == today;
    final isThirtyDays =
        from == today.subtract(const Duration(days: 29)) && through == today;
    final hasFilters = query.text.trim().isNotEmpty ||
        kind != null ||
        from != null ||
        through != null;
    final rangeLabel = from == null
        ? '自定义日期'
        : through == null || from == through
            ? DateFormat('M 月 d 日').format(from!)
            : '${DateFormat('M/d').format(from!)} – ${DateFormat('M/d').format(through!)}';

    return Scaffold(
        appBar: AppBar(title: const Text('搜索记录'), actions: [
          if (hasFilters)
            TextButton.icon(
                onPressed: clearFilters,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('清除')),
          const SizedBox(width: 8)
        ]),
        body: SafeArea(
            top: false,
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                            key: const ValueKey('search-keyword'),
                            controller: query,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                                hintText: '主题、笔记、心情或日期，如 2026-10-14',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: query.text.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: '清空关键词',
                                        onPressed: query.clear,
                                        icon:
                                            const Icon(Icons.cancel_outlined)),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12))),
                        const SizedBox(height: 16),
                        const Text('记录类型',
                            style: TextStyle(
                                fontSize: 12,
                                color: muted,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, children: [
                          _SearchChip(
                              label: '全部',
                              selected: kind == null,
                              onSelected: () => setState(() => kind = null)),
                          _SearchChip(
                              label: '学习',
                              selected: kind == RecordKind.study,
                              onSelected: () =>
                                  setState(() => kind = RecordKind.study)),
                          _SearchChip(
                              label: '心情',
                              selected: kind == RecordKind.mood,
                              onSelected: () =>
                                  setState(() => kind = RecordKind.mood))
                        ]),
                        const SizedBox(height: 14),
                        const Text('日期范围',
                            style: TextStyle(
                                fontSize: 12,
                                color: muted,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          _SearchChip(
                              label: '全部日期',
                              selected: from == null && through == null,
                              onSelected: () => setState(() {
                                    from = null;
                                    through = null;
                                  })),
                          _SearchChip(
                              label: '近 7 天',
                              selected: isSevenDays,
                              onSelected: () => setRecentDays(7)),
                          _SearchChip(
                              label: '近 30 天',
                              selected: isThirtyDays,
                              onSelected: () => setRecentDays(30)),
                          OutlinedButton.icon(
                              onPressed: pickRange,
                              icon: const Icon(Icons.calendar_month_outlined,
                                  size: 17),
                              label: Text(rangeLabel))
                        ])
                      ])),
              const Divider(height: 1),
              Expanded(
                  child: results.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child:
                              EmptyState('没有找到匹配记录', '试试其他关键词，或调整日期范围和记录类型。'))
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                          children: [
                              SectionHeading('搜索结果',
                                  trailing: Text('${results.length} 条',
                                      style: const TextStyle(
                                          color: muted, fontSize: 12))),
                              ...recordGroups(
                                  context,
                                  results,
                                  (kind, {entry, mood}) => editEntry(entry!),
                                  deleteEntry)
                            ]))
            ])));
  }
}

class _SearchChip extends StatelessWidget {
  const _SearchChip(
      {required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
      label: Text(label), selected: selected, onSelected: (_) => onSelected());
}

List<Widget> recordGroups(BuildContext context, List<JournalEntry> entries,
    EditRecord edit, Future<void> Function(JournalEntry) onDelete) {
  String? previous;
  final result = <Widget>[];
  for (final e in entries) {
    final key = dayKey(e.at);
    if (previous != key) {
      result.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(DateFormat('yyyy 年 M 月 d 日').format(e.at),
              style: const TextStyle(color: muted, fontSize: 12))));
      previous = key;
    }
    result.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: RecordTile(entry: e, edit: edit, onDelete: onDelete)));
  }
  return result;
}

class RecordTile extends StatelessWidget {
  const RecordTile(
      {super.key,
      required this.entry,
      required this.edit,
      required this.onDelete});
  final JournalEntry entry;
  final EditRecord edit;
  final Future<void> Function(JournalEntry) onDelete;
  @override
  Widget build(BuildContext context) {
    final study = entry.kind == RecordKind.study;
    return Surface(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child: study
                      ? Icon(Icons.menu_book_outlined,
                          size: 19,
                          color: Theme.of(context).colorScheme.primary)
                      : Text(moodEmoji(entry.title),
                          style: const TextStyle(fontSize: 23)))),
          const SizedBox(width: 12),
          Expanded(
              child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => edit(entry.kind, entry: entry),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                            '${study ? '${entry.minutes} 分钟 · ' : ''}${DateFormat('M/d HH:mm').format(entry.at)}',
                            style: const TextStyle(color: muted, fontSize: 12)),
                        if (entry.note.isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(entry.note,
                                  style: const TextStyle(color: muted),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis))
                      ]))),
          PopupMenuButton<String>(
              tooltip: '管理记录',
              icon: const Icon(Icons.more_horiz, size: 20, color: muted),
              onSelected: (action) => action == 'edit'
                  ? edit(entry.kind, entry: entry)
                  : onDelete(entry),
              itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('编辑')),
                    PopupMenuItem(value: 'delete', child: Text('删除'))
                  ])
        ]));
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Surface(
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(children: [
            const Icon(Icons.edit_note_outlined, color: muted, size: 30),
            const SizedBox(height: 12),
            Text(title),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted, fontSize: 12))
          ])));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.entries, required this.summary});
  final List<JournalEntry> entries;
  final JournalSummary summary;
  @override
  Widget build(BuildContext context) => PageContent(children: [
        const PageHeading('属于你的日常', '一点一滴，都是生活的痕迹。'),
        Surface(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionHeading('记录概览'),
          InfoRow('学习记录',
              '${entries.where((e) => e.kind == RecordKind.study).length} 条'),
          InfoRow('累计学习', '${summary.totalStudyMinutes} 分钟'),
          InfoRow('心情记录',
              '${entries.where((e) => e.kind == RecordKind.mood).length} 条'),
          InfoRow('连续记录', '${summary.streak} 天')
        ])),
        const SizedBox(height: 20),
        const Surface(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeading('关于 DayFlow'),
          Text('一个简单的学习与心情记录本。', style: TextStyle(color: muted)),
          SizedBox(height: 16),
          Text('连续记录：当天有学习或心情记录即计为一天。如果今天尚未记录，延续截至昨天的连续天数。',
              style: TextStyle(color: muted, fontSize: 12)),
          SizedBox(height: 12),
          Text('每日学习目标暂定 60 分钟。本周从周一开始，统计按记录日期计算。',
              style: TextStyle(color: muted, fontSize: 12)),
          SizedBox(height: 12),
          Text('数据保存在当前设备。备份与设备同步将在后续版本提供。',
              style: TextStyle(color: muted, fontSize: 12))
        ]))
      ]);
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: muted))),
        Text(value)
      ]));
}

class RecordEditor extends StatefulWidget {
  const RecordEditor(
      {super.key,
      required this.repository,
      required this.kind,
      this.entry,
      this.initialMood});
  final LocalRepository repository;
  final RecordKind kind;
  final JournalEntry? entry;
  final String? initialMood;
  @override
  State<RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<RecordEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, minutes, note;
  late DateTime at;
  late String mood;
  bool saving = false;
  String? error;
  bool get study => widget.kind == RecordKind.study;
  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.entry?.title ?? '');
    minutes = TextEditingController(text: '${widget.entry?.minutes ?? 30}');
    note = TextEditingController(text: widget.entry?.note ?? '');
    at = widget.entry?.at ?? DateTime.now();
    mood = widget.entry?.title ?? widget.initialMood ?? '平静';
  }

  @override
  void dispose() {
    title.dispose();
    minutes.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
        context: context,
        initialDate: at.isAfter(now)
            ? now
            : at.isBefore(DateTime(2000))
                ? DateTime(2000)
                : at,
        firstDate: DateTime(2000),
        lastDate: now,
        helpText: '选择记录日期',
        cancelText: '取消',
        confirmText: '确定');
    if (selected != null && mounted) {
      setState(() {
        at = DateTime(selected.year, selected.month, selected.day, at.hour,
            at.minute, at.second);
        if (at.isAfter(now)) at = now;
      });
    }
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      if (study) {
        await widget.repository.saveStudy(
            id: widget.entry?.id,
            title: title.text,
            minutes: int.parse(minutes.text.trim()),
            note: note.text,
            at: at);
      } else {
        await widget.repository.saveMood(
            id: widget.entry?.id, mood: mood, note: note.text, at: at);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = '保存失败，输入已保留，请重试。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !saving,
      child: AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(
              '${widget.entry == null ? '记录' : '编辑'}${study ? '学习' : '心情'}'),
          scrollable: true,
          content: SizedBox(
              width: 420,
              child: Form(
                  key: form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (study) ...[
                          TextFormField(
                              key: const ValueKey('study-title'),
                              controller: title,
                              enabled: !saving,
                              validator: validateTitle,
                              maxLength: 80,
                              decoration: const InputDecoration(
                                  labelText: '学习主题',
                                  hintText: '今天学了什么？',
                                  counterText: '')),
                          const SizedBox(height: 16),
                          TextFormField(
                              key: const ValueKey('study-minutes'),
                              controller: minutes,
                              enabled: !saving,
                              validator: validateMinutes,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: '时长（分钟）', helperText: '1–1440 分钟'))
                        ] else ...[
                          const Text('此刻的心情', style: TextStyle(color: muted)),
                          const SizedBox(height: 10),
                          Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: moodOptions
                                  .map((m) => ChoiceChip(
                                      label: Text('${m.$2} ${m.$1}'),
                                      selected: mood == m.$1,
                                      onSelected: saving
                                          ? null
                                          : (_) => setState(() {
                                                mood = m.$1;
                                              }),
                                      showCheckmark: false))
                                  .toList())
                        ],
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                            onPressed: saving ? null : pickDate,
                            icon: const Icon(Icons.calendar_today_outlined,
                                size: 17),
                            label:
                                Text(DateFormat('yyyy 年 M 月 d 日').format(at))),
                        const SizedBox(height: 8),
                        const Text('可以补记过去的日期，统计会按所选日期更新。',
                            style: TextStyle(fontSize: 12, color: muted)),
                        const SizedBox(height: 16),
                        TextFormField(
                            key: const ValueKey('record-note'),
                            controller: note,
                            enabled: !saving,
                            minLines: 3,
                            maxLines: 6,
                            maxLength: 2000,
                            decoration: InputDecoration(
                                labelText: study ? '学习笔记（可选）' : '心情随记（可选）',
                                alignLabelWithHint: true)),
                        if (error != null)
                          Text(error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))
                      ]))),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(context, false),
                child: const Text('取消')),
            FilledButton(
                onPressed: saving ? null : save,
                child: Text(saving ? '保存中…' : '保存'))
          ]));
}
