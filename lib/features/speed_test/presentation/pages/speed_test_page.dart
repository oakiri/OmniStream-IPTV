import 'package:flutter/material.dart';
import 'package:omnistream_iptv/features/speed_test/presentation/widgets/speed_test_widget.dart';

class SpeedTestPage extends StatelessWidget {
  const SpeedTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SpeedTestWidget(),
      ),
    );
  }
}
