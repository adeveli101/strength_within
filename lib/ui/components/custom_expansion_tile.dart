import 'package:flutter/material.dart';

const Duration _kExpand = Duration(milliseconds: 200);

class ExpansionTile extends StatefulWidget {
  const ExpansionTile({
    super.key,
    this.headerBackgroundColor,
    this.leading,
    required this.title,
    this.backgroundColor,
    this.foregroundColor,
    this.iconColor,
    this.onExpansionChanged,
    this.children = const <Widget>[],
    this.trailing,
    this.initiallyExpanded = false,
  });

  final Widget? leading;
  final Widget title;
  final ValueChanged<bool>? onExpansionChanged;
  final List<Widget> children;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? headerBackgroundColor;
  final Color? iconColor;
  final Widget? trailing;
  final bool initiallyExpanded;

  @override
  State<ExpansionTile> createState() => _ExpansionTileState();
}

class _ExpansionTileState extends State<ExpansionTile> with SingleTickerProviderStateMixin {
  static final Animatable<double> _easeOutTween = CurveTween(curve: Curves.easeOut);
  static final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _halfTween = Tween<double>(begin: 0.0, end: 0.5);

  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;
  late Animation<Color?> _borderColor;
  late Animation<Color?> _headerColor;
  late Animation<Color?> _iconColor;
  late Animation<Color?> _backgroundColor;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _kExpand, vsync: this);
    _heightFactor = _controller.drive(_easeInTween);
    _iconTurns = _controller.drive(_halfTween.chain(_easeInTween));
    _borderColor = _controller.drive(ColorTween().chain(_easeOutTween));
    _headerColor = _controller.drive(ColorTween().chain(_easeInTween));
    _iconColor = _controller.drive(ColorTween().chain(_easeInTween));
    _backgroundColor = _controller.drive(ColorTween().chain(_easeOutTween));

    _isExpanded = PageStorage.of(context).readState(context) as bool? ?? widget.initiallyExpanded;
    if (_isExpanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse().then<void>((void value) {
          if (!mounted) return;
          setState(() {});
        });
      }
      PageStorage.of(context).writeState(context, _isExpanded);
    });
    widget.onExpansionChanged?.call(_isExpanded);
  }

  Widget _buildChildren(BuildContext context, Widget? child) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor.value ?? Colors.transparent,
        border: Border(
          top: BorderSide(color: _borderColor.value ?? Colors.transparent),
          bottom: BorderSide(color: _borderColor.value ?? Colors.transparent),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconTheme.merge(
            data: IconThemeData(color: _iconColor.value),
            child: Container(
              color: widget.headerBackgroundColor ?? Colors.transparent,
              child: ListTile(
                onTap: _handleTap,
                leading: widget.leading,
                title: DefaultTextStyle(
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(color: _headerColor.value),
                  child: widget.title,
                ),
                trailing: widget.trailing ?? RotationTransition(
                  turns: _iconTurns,
                  child: Icon(Icons.expand_more, color: widget.iconColor ?? Colors.grey),
                ),
              ),
            ),
          ),
          ClipRect(
            child: Align(
              heightFactor: _heightFactor.value,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    _borderColor = _controller.drive(ColorTween(end: theme.dividerColor));
    _headerColor = _controller.drive(ColorTween(
      begin: theme.textTheme.titleMedium!.color,
      end: widget.foregroundColor,
    ));
    _iconColor = _controller.drive(ColorTween(
      begin: theme.unselectedWidgetColor,
      end: theme.colorScheme.secondary,
    ));
    _backgroundColor = _controller.drive(ColorTween(end: widget.backgroundColor));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final bool closed = !_isExpanded && _controller.isDismissed;
    return AnimatedBuilder(
      animation: _controller.view,
      builder: _buildChildren,
      child: closed ? null : Column(children: widget.children),
    );
  }
}