import 'package:flutter/material.dart';

class DigitTickerController extends ValueNotifier<int> {
  DigitTickerController({int initialValue = 0}) : super(initialValue) {
    assert(initialValue >= 0 && initialValue < 10, 'Number must be in the range [0, 9].');
  }

  int get number => value;
  set number(int newValue) {
    assert(newValue >= 0 && newValue < 10, 'Number must be in the range [0, 9].');
    value = newValue;
  }
}

class DigitTicker extends StatefulWidget {
  final Color backgroundColor;
  final Curve curve;
  final Duration duration;
  final int initialNumber;
  final TextStyle textStyle;
  final DigitTickerController controller;

  const DigitTicker({
    super.key,
    this.backgroundColor = Colors.transparent,
    this.curve = Curves.ease,
    required this.controller,
    required this.textStyle,
    required this.initialNumber,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<DigitTicker> createState() => _DigitTickerState();
}

class _DigitTickerState extends State<DigitTicker> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.textStyle.fontSize! * (4 / 3) * widget.initialNumber,
    );
    widget.controller.addListener(_onValueChanged);
  }

  void _onValueChanged() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        widget.controller.number * widget.textStyle.fontSize! * (4 / 3),
        duration: widget.duration,
        curve: widget.curve,
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onValueChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      height: widget.textStyle.fontSize! * (4 / 3),
      width: widget.textStyle.fontSize! * (7 / 10),
      child: ListView.builder(
        controller: _scrollController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 10,
        itemBuilder: (context, index) => SizedBox(
          height: widget.textStyle.fontSize! * (4 / 3),
          child: Center(
            child: Text(
              "$index",
              style: widget.textStyle,
            ),
          ),
        ),
      ),
    );
  }
}

class NumberTickerController extends ValueNotifier<double> {
  NumberTickerController({double initialValue = 0}) : super(initialValue);

  double get number => value;
  set number(double newValue) {
    value = newValue < 0 ? 0 : newValue;
  }
}

class NumberTicker extends StatefulWidget {
  final Color backgroundColor;
  final Curve curve;
  final double initialNumber;
  final Duration duration;
  final int fractionDigits;
  final NumberTickerController controller;
  final TextStyle textStyle;

  const NumberTicker({
    super.key,
    this.backgroundColor = Colors.transparent,
    this.curve = Curves.ease,
    required this.controller,
    this.textStyle = const TextStyle(color: Colors.black, fontSize: 12),
    required this.initialNumber,
    this.duration = const Duration(milliseconds: 300),
    this.fractionDigits = 0,
  });

  @override
  State<NumberTicker> createState() => _NumberTickerState();
}

class _NumberTickerState extends State<NumberTicker> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late String _currentNumString;
  late List<DigitTickerController> _digitControllers;
  bool _isLonger = false;
  bool _isShorter = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _currentNumString = widget.initialNumber.toStringAsFixed(widget.fractionDigits);
    _digitControllers = _createDigitControllers(_currentNumString);
    widget.controller.addListener(_onNumberChanged);
    _animationController.addStatusListener(_onAnimationStatusChanged);
  }

  List<DigitTickerController> _createDigitControllers(String numString) {
    return numString.split('').map((char) {
      final digit = int.tryParse(char);
      return digit != null ? DigitTickerController(initialValue: digit) : null;
    }).whereType<DigitTickerController>().toList();
  }

  void _onNumberChanged() {
    if (_animationController.isAnimating) {
      _animationController.forward(from: 0);
    }
    final newNumString = widget.controller.number.toStringAsFixed(widget.fractionDigits);
    _updateDigitControllers(newNumString);
    setState(() {
      _currentNumString = newNumString;
    });
  }

  void _updateDigitControllers(String newNumString) {
    _isLonger = newNumString.length > _currentNumString.length;
    _isShorter = newNumString.length < _currentNumString.length;

    if (_isLonger) {
      _digitControllers.insert(0, DigitTickerController(initialValue: int.parse(newNumString[0])));
    }

    final minLength = _isLonger ? _currentNumString.length : newNumString.length;
    for (int i = _isLonger ? 1 : 0; i < minLength; i++) {
      final newDigit = int.parse(newNumString[i]);
      _digitControllers[i].number = newDigit;
    }

    if (_isShorter) {
      _digitControllers = _digitControllers.sublist(0, newNumString.length);
    }

    if (_isLonger || _isShorter) {
      _animationController.forward(from: 0);
    }
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _isLonger = false;
        _isShorter = false;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onNumberChanged);
    _animationController.dispose();
    for (var controller in _digitControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < _digitControllers.length; i++)
              _buildDigitTicker(i),
          ],
        );
      },
    );
  }

  Widget _buildDigitTicker(int index) {
    final width = widget.textStyle.fontSize! * 0.8;
    final isFirstDigit = index == 0;
    final isLastDigit = index == _digitControllers.length - 1;

    return SizedBox(
      width: isFirstDigit && _isLonger
          ? _animationController.value * width
          : isLastDigit && _isShorter
          ? (1 - _animationController.value) * width
          : width,
      child: DigitTicker(
        backgroundColor: widget.backgroundColor,
        controller: _digitControllers[index],
        curve: widget.curve,
        duration: widget.duration,
        textStyle: widget.textStyle,
        initialNumber: int.parse(_currentNumString[index]),
      ),
    );
  }
}