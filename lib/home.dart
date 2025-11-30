import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'sensor_service.dart';
import 'firebase_service.dart';
import 'database_helper.dart';
import 'package:audioplayers/audioplayers.dart';

class HomePage extends StatefulWidget {
  final int userId;

  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final sensor = SensorService();
  final firebase = FirebaseService();
  final audioPlayer = AudioPlayer();
  final db = DatabaseHelper();

  bool isRunning = false;
  bool fallDetected = false;
  int countdown = 10;
  Timer? countdownTimer;

  String userName = '';
  String emergencyContact = '';
  int totalFallsDetected = 0;

  // Fall detection thresholds
  static const double fallThreshold = 40.0;
  static const double gyroThreshold = 5.0;

  // Computed values
  double totalAccel = 0.0;
  double totalGyro = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await db.getUserById(widget.userId);
    final fallCount = await db.getFallEventsCount(widget.userId);

    if (user != null && mounted) {
      setState(() {
        userName = user['name'];
        emergencyContact = user['emergency_contact'];
        totalFallsDetected = fallCount;
      });
    }
  }

  void startUploading() {
    if (!isRunning) {
      isRunning = true;
      fallDetected = false;

      firebase.upload(null);

      sensor.startListening(() {
        totalAccel = sqrt(
            sensor.ax * sensor.ax +
                sensor.ay * sensor.ay +
                sensor.az * sensor.az
        );

        totalGyro = sqrt(
            sensor.gx * sensor.gx +
                sensor.gy * sensor.gy +
                sensor.gz * sensor.gz
        );

        final data = {
          "timestamp": DateTime.now().millisecondsSinceEpoch,
          "ax": sensor.ax,
          "ay": sensor.ay,
          "az": sensor.az,
          "gx": sensor.gx,
          "gy": sensor.gy,
          "gz": sensor.gz,
          "total_accel": totalAccel,
          "total_gyro": totalGyro,
          "user_id": widget.userId,
        };

        if (detectFall()) {
          setState(() {
            fallDetected = true;
            countdown = 10;
          });

          startCountdown();

          // Save fall event to database
          db.insertFallEvent({
            'user_id': widget.userId,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'total_accel': totalAccel,
            'total_gyro': totalGyro,
            'alarm_triggered': 0,
            'user_responded': 0,
          });

          final fallData = {
            ...data,
            "fall_detected": true,
          };
          firebase.upload(fallData);
        } else {
          firebase.upload(data);
        }

        setState(() {});
      });
    }
  }

  void startCountdown() {
    countdownTimer?.cancel();

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        countdown--;
      });

      if (countdown <= 0) {
        timer.cancel();
        if (fallDetected) {
          playEmergencyAlarm();
          _loadUserData(); // Refresh fall count
        }
      }
    });
  }

  Future<void> playEmergencyAlarm() async {
    try {
      // Configure audio context for background playback
      await audioPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );

      await audioPlayer.setVolume(1.0);
      await audioPlayer.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.play(AssetSource('sounds/emergency_alarm.mp3'));

      // Update database that alarm was triggered
      await db.updateFallEventAlarm(widget.userId, triggered: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 EMERGENCY ALARM ACTIVATED 🚨'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error playing alarm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play alarm: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> stopAlarm() async {
    try {
      await audioPlayer.stop();
    } catch (e) {
      print('Error stopping alarm: $e');
    }
  }

  bool detectFall() {
    double gyroThresholdDegrees = gyroThreshold * 180 / pi;
    return totalAccel > fallThreshold || totalGyro > gyroThresholdDegrees;
  }

  void stopUploading() {
    if (isRunning) {
      sensor.stop();
      isRunning = false;
      fallDetected = false;
      countdownTimer?.cancel();
      stopAlarm();
      setState(() {});
    }
  }

  void dismissFallWarning() {
    countdownTimer?.cancel();
    stopAlarm();
    setState(() {
      fallDetected = false;
      countdown = 10;
    });
  }

  @override
  void dispose() {
    sensor.stop();
    countdownTimer?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fall Detection"),
        backgroundColor: fallDetected ? Colors.red : Colors.red.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Show user profile dialog
              _showUserProfile();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fall Warning Banner
              if (fallDetected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    border: Border.all(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.warning_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "⚠️ FALL DETECTED ⚠️",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Emergency alarm will sound in $countdown seconds...",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "🔊 LOUD ALARM WILL PLAY 🔊",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                        child: Center(
                          child: Text(
                            "$countdown",
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: dismissFallWarning,
                        icon: const Icon(Icons.check_circle),
                        label: const Text("I'm OK - Stop Alarm"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // User Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Colors.red),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName.isNotEmpty ? userName : 'Loading...',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Emergency: $emergencyContact',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'Total Falls',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                '$totalFallsDetected',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white30,
                          ),
                          Column(
                            children: [
                              const Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                isRunning ? 'Active' : 'Stopped',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Status indicator
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isRunning
                      ? (fallDetected ? Colors.red.shade50 : Colors.green.shade50)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isRunning
                        ? (fallDetected ? Colors.red : Colors.green)
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isRunning ? Icons.sensors : Icons.sensors_off,
                      color: isRunning
                          ? (fallDetected ? Colors.red : Colors.green)
                          : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRunning
                                ? (fallDetected ? "FALL DETECTED!" : "Monitoring Active")
                                : "Monitoring Stopped",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isRunning
                                  ? (fallDetected ? Colors.red : Colors.green)
                                  : Colors.grey,
                            ),
                          ),
                          if (isRunning)
                            Text(
                              'Total Accel: ${totalAccel.toStringAsFixed(1)} m/s²',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Control buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isRunning ? null : startUploading,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Start"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey.shade300,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isRunning ? stopUploading : null,
                      icon: const Icon(Icons.stop),
                      label: const Text("Stop"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey.shade300,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Profile'),
        content: FutureBuilder<Map<String, dynamic>?>(
          future: db.getUserById(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            final user = snapshot.data;
            if (user == null) {
              return const Text('User not found');
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileRow('Name', user['name']),
                _buildProfileRow('Email', user['email']),
                _buildProfileRow('Phone', user['phone']),
                _buildProfileRow('Emergency Contact', user['emergency_contact']),
                _buildProfileRow('Address', user['address'] ?? 'N/A'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}