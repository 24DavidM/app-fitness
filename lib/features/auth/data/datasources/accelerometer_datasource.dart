import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/step_data.dart';

abstract class AccelerometerDataSource {
  Stream<StepData> get stepStream;
  Future<void> startCounting();
  Future<void> stopCounting();
  Future<bool> requestPermissions();
}

class AccelerometerDataSourceImpl implements AccelerometerDataSource {
  final StreamController<StepData> _controller = StreamController.broadcast();
  StreamSubscription<AccelerometerEvent>? _sub;
  int _steps = 0;
  bool _stepInProgress = false;

  @override
  Stream<StepData> get stepStream => _controller.stream;

  @override
  Future<void> startCounting() async {
    _sub = accelerometerEvents.listen((event) {
      final mag =
          math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      // High-pass approximation (remove gravity)
      final accel = (mag - 9.81).abs();

      // Simple peak detection
      const threshold = 1.8; // tweak as needed
      const resetThreshold = 0.9;

      if (!_stepInProgress && accel > threshold) {
        _stepInProgress = true;
        _steps++;
        final activity =
            accel > 4.0 ? ActivityType.running : ActivityType.walking;
        _controller.add(StepData(
            stepCount: _steps, activityType: activity, magnitude: accel));
      } else if (_stepInProgress && accel < resetThreshold) {
        _stepInProgress = false;
      }
    });
  }

  @override
  Future<void> stopCounting() async {
    await _sub?.cancel();
    _sub = null;
  }

  @override
  Future<bool> requestPermissions() async {
    final activityStatus = await Permission.activityRecognition.request();
    final sensorsStatus = await Permission.sensors.request();
    return activityStatus.isGranted && sensorsStatus.isGranted;
  }
}
