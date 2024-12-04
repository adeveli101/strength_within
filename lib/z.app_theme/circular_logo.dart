import 'package:flutter/material.dart';
import 'app_theme.dart';

class CircularLogo extends StatefulWidget {
  final double size;
  final bool showBorder;
  final VoidCallback? onTap;
  final bool animate;

  const CircularLogo({
    super.key,
    this.size = 40,
    this.showBorder = true,
    this.onTap,
    this.animate = true,
  });

  @override
  State<CircularLogo> createState() => _CircularLogoState();
}

class _CircularLogoState extends State<CircularLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.quickAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.animate ? _controller.forward() : null,
      onExit: (_) => widget.animate ? _controller.reverse() : null,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => widget.animate ? _controller.forward() : null,
        onTapUp: (_) => widget.animate ? _controller.reverse() : null,
        onTapCancel: () => widget.animate ? _controller.reverse() : null,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.darkBackground,
                  border: Border.all(
                    color: AppTheme.primaryRed.withOpacity(0.5),
                    width: widget.showBorder ? 1.5 : 0,
                  ),
                  boxShadow: widget.showBorder ? [
                    BoxShadow(
                      color: AppTheme.primaryRed.withOpacity(0.2),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ] : null,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo_circle.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
