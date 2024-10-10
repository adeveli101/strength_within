import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/part.dart';
import 'components/chart.dart';

class PartHistoryPage extends StatelessWidget {
  final Part part;

  PartHistoryPage(this.part);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: part.exercises.length,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          bottom: TabBar(
            indicator: CircleTabIndicator(color: Theme.of(context).colorScheme.secondary, radius: 3),
            isScrollable: true,
            tabs: _getTabs(part),
          ),
          title: Text("History", style: Theme.of(context).textTheme.titleLarge),
        ),
        body: TabBarView(
          children: _getTabChildren(part),
        ),
      ),
    );
  }

  List<Widget> _getTabs(Part part) {
    return part.exercises.map((ex) => Tab(text: ex.name)).toList();
  }

  List<Widget> _getTabChildren(Part part) {
    return part.exercises.map((ex) => TabChild(ex, setTypeToThemeColorConverter(part.setType))).toList();
  }

  Color setTypeToThemeColorConverter(SetType setType) {
    switch (setType) {
      case SetType.regular:
        return Colors.blueAccent;
      case SetType.drop:
        return Colors.redAccent;
      case SetType.super_:
        return Colors.greenAccent;
      case SetType.tri:
        return Colors.orangeAccent;
      case SetType.giant:
        return Colors.purpleAccent;
      default:
        throw Exception('Inside setTypeToThemeConverter');
    }
  }
}

class TabChild extends StatelessWidget {
  final Exercise exercise;
  final Color foregroundColor;

  TabChild(this.exercise, this.foregroundColor);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Container(height: 200, child: StackedAreaLineChart(exercise, animate: false)),
          ),
          Expanded(child: HistoryExpansionTile(exercise.exHistory, foregroundColor)),
        ],
      ),
    );
  }
}

class Year {
  final String year;
  final List<String> dates = <String>[];

  Year(this.year) : assert(year.length == 4 && year[0] == '2' && year[1] == '0');
}

class HistoryExpansionTile extends StatelessWidget {
  final Map exHistory;
  final Color foregroundColor;

  HistoryExpansionTile(this.exHistory, this.foregroundColor)
      : assert(exHistory != null),
        assert(foregroundColor != null);

  @override
  Widget build(BuildContext context) {
    var years = <Year>[];
    for (var date in exHistory.keys) {
      if (years.isEmpty || date.toString().substring(0, 4) != years.last.year) {
        years.add(Year(date.toString().split('-').first));
      }
      years.last.dates.add(date);
    }

    return ListView.builder(
      itemCount: years.length + 1,
      itemBuilder: (context, i) {
        if (i == years.length) return SizedBox(height: 48);

        return ExpansionTile(
          collapsedIconColor: foregroundColor,
          title: Text(years[i].year),
          children: _listViewBuilder(years[i].dates, exHistory),
        );
      },
    );
  }

  List<Widget> _listViewBuilder(List<String> dates, Map exHistory) {
    return dates.map((date) => Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[350],
            child: Text((dates.indexOf(date) + 1).toString(), style: TextStyle(fontSize: 16)),
          ),
          title: Text(date),
          subtitle: Text(exHistory[date]),
        ),
        Divider(),
      ],
    )).toList();
  }
}

class CircleTabIndicator extends Decoration {
  final BoxPainter _painter;

  CircleTabIndicator({required Color color, required double radius})
      : _painter = _CirclePainter(color, radius);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _painter;
}

class _CirclePainter extends BoxPainter {
  final Paint _paint;
  final double radius;

  _CirclePainter(Color color, this.radius)
      : _paint = Paint()
    ..color = color
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final Offset circleOffset = offset + Offset(cfg.size!.width / 2, cfg.size!.height - radius - 5);
    canvas.drawCircle(circleOffset, radius, _paint);
  }
}
