import 'package:flutter/material.dart';

class VehicleOptionsTile extends StatefulWidget {

  final String vehicleType;

  const VehicleOptionsTile({super.key, required this.vehicleType});

  @override
  State<VehicleOptionsTile> createState() => _VehicleOptionsTileState();
}

class _VehicleOptionsTileState extends State<VehicleOptionsTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: 3,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
              side: BorderSide(color: Colors.black.withOpacity(0.1)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Hero(
                    tag: 'vehicle_${widget.vehicleType}',
                    child: Image(
                      image: AssetImage('assets/${widget.vehicleType}.png'),
                      height: 60.0,
                      width: 60.0,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    widget.vehicleType,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
