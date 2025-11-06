import 'package:flutter/material.dart';
import 'package:pakyaw/shared/size_config.dart';

class DriverFound extends StatefulWidget {
  final Map<String, dynamic> driver;
  final Map<String, dynamic> vehicle;
  const DriverFound({super.key, required this.driver, required this.vehicle});

  @override
  _DriverFoundState createState() => _DriverFoundState();
}

class _DriverFoundState extends State<DriverFound> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    int duration = getDuration(widget.driver['duration']);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.vehicle['vehicle_image'],
                        width: SizeConfig.blockSizeHorizontal * 14,
                        height: SizeConfig.blockSizeVertical * 7,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator());
                        },
                      ),
                    ),
                    title: Text(
                      widget.vehicle['model'],
                      style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'PLATE: ${widget.vehicle['plate_num']}',
                      style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 4,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: SizeConfig.blockSizeHorizontal * 5,
                      backgroundImage: NetworkImage(widget.driver['driver_profile']),
                      backgroundColor: Colors.grey[200],
                    ),
                    title: Text(
                      widget.driver['driver_name'],
                      style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 4.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(Icons.star, 
                          size: SizeConfig.safeBlockHorizontal * 5,
                          color: Colors.amber,
                        ),
                        Text(
                          ' ${widget.driver['rating'].toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 4,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    trailing: duration < 60 ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Arriving in',
                          style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 3.5,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          duration < 60 ? '$duration sec' : '$duration min',
                          style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 4,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ) : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int getDuration(String time) {
    int seconds = int.parse(time.replaceAll('s', ''));
    if(seconds >= 60){
      int minute = (seconds/60).round();
      return minute;
    }else{
      return seconds;
    }
  }
}
