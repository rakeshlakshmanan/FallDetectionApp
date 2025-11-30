import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription? _accSub;
  StreamSubscription? _gyroSub;

  double ax = 0, ay = 0, az = 0;
  double gx = 0, gy = 0, gz = 0;

  void startListening(void Function() onUpdate) {
    _accSub = accelerometerEvents.listen((event) {
      ax = event.x;
      ay = event.y;
      az = event.z;
      onUpdate();
    });

    _gyroSub = gyroscopeEvents.listen((event) {
      gx = event.x;
      gy = event.y;
      gz = event.z;
      onUpdate();
    });
  }

  void stop() {
    _accSub?.cancel();
    _gyroSub?.cancel();
  }
}
