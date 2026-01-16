import 'package:flutter/material.dart';

class SpeedTestWidget extends StatefulWidget {
  const SpeedTestWidget({Key? key}) : super(key: key);

  @override
  State<SpeedTestWidget> createState() => _SpeedTestWidgetState();
}

class _SpeedTestWidgetState extends State<SpeedTestWidget> {
  bool _isTesting = false;
  double _speed = 0;

  void _startTest() {
    setState(() {
      _isTesting = true;
      _speed = 0;
    });

    // Simulate speed test
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isTesting = false;
        _speed = 45.67; // Simulated speed
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Velocidad de descarga',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: Theme.of(context).colorScheme.secondary, width: 4),
          ),
          child: Center(
            child: _isTesting
                ? const CircularProgressIndicator()
                : Text('$_speed Mbps',
                    style: Theme.of(context).textTheme.headlineMedium),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isTesting ? null : _startTest,
          child: const Text('START'),
        ),
      ],
    );
  }
}
