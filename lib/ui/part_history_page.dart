import 'package:flutter/material.dart';
import 'package:workout/ui/components/chart.dart';
import 'package:workout/ui/components/custom_expansion_tile.dart' as custom;
import 'package:workout/ui/theme.dart';
import '../models/exercise.dart';
import '../models/part.dart';

class PartHistoryPage extends StatelessWidget {
  final Part part;

  const PartHistoryPage(this.part, {super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: part.exercises.length,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicator: const CircleTabIndicator(color: Colors.grey, radius: 3),
            indicatorColor: Colors.grey,
            isScrollable: true,
            tabs: part.exercises.map((ex) => Tab(text: ex.name)).toList(),
          ),
          title: const Text("History"),
        ),
        body: TabBarView(
          children: part.exercises.map((ex) => TabChild(ex, setTypeToThemeColorConverter(part.setType))).toList(),
        ),
      ),
    );
  }

  Color? setTypeToThemeColorConverter(SetType setType) {
    switch (setType) {
      case SetType.regular:
        return ThemeRegular.accentColor;
      case SetType.drop:
        return ThemeDrop.accentColor;
      case SetType.super_:
        return ThemeSuper.accentColor;
      case SetType.tri:
        return ThemeTri.accentColor;
      case SetType.giant:
        return ThemeGiant.accentColor;
      default:
        return null; //
    }
  }
}

class TabChild extends StatelessWidget {
  final Exercise exercise;
  final Color? foregroundColor;

  const TabChild(this.exercise, this.foregroundColor, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: SizedBox(
            height: 200,
            child: StackedAreaLineChart(exercise, animate: true),
          ),
        ),
        Expanded(child: HistoryExpansionTile(exercise.exHistory, foregroundColor)),
      ],
    );
  }
}

class Year {
  final String year;
  final List<String> dates = <String>[];

  Year(this.year) : assert(year.length == 4 && year.startsWith('20'));
}

class HistoryExpansionTile extends StatelessWidget {
  final Map exHistory;
  final Color? foregroundColor;

  const HistoryExpansionTile(this.exHistory, this.foregroundColor, {super.key});

  @override
  Widget build(BuildContext context) {
    var years = <Year>[];
    for (var date in exHistory.keys) {
      var yearStr = date.toString().split('-').first;
      if (years.isEmpty || yearStr != years.last.year) {
        years.add(Year(yearStr));
      }
      years.last.dates.add(date);
    }

    return ListView.builder(
      itemCount: years.length + 1,
      itemBuilder: (context, i) {
        if (i == years.length) return const SizedBox(height: 48);
        return custom.ExpansionTile(
          foregroundColor: foregroundColor,
          title: Text(years[i].year),
          children: _listViewBuilder(years[i].dates, exHistory),
        );
      },
    );
  }

  List<Widget> _listViewBuilder(List<String> dates, Map exHistory) {
    return dates.asMap().entries.map((entry) {
      int index = entry.key;
      String date = entry.value;
      return Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[340],
              ),
              child: Center(
                child: Text(
                  (index + 1).toString(),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            title: Text(date),
            subtitle: Text(exHistory[date].toString()),
          ),
          const Divider(),
        ],
      );
    }).toList();
  }
}

class CircleTabIndicator extends Decoration {
  final Color color;
  final double radius;

  const CircleTabIndicator({
    required this.color,
    required this.radius,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _CirclePainter(color: color, radius: radius);
}

class _CirclePainter extends BoxPainter {
  final Paint _paint;
  final double radius;

  _CirclePainter({required Color color, required this.radius})
      : _paint = Paint()
    ..color = color
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final Offset circleOffset = offset + Offset(cfg.size!.width / 2, cfg.size!.height - radius - 5);
    canvas.drawCircle(circleOffset, radius, _paint);
  }
}