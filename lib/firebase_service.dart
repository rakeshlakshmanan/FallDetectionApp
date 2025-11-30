import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final db = FirebaseDatabase.instance.ref("rakesh_sensor_data");

  void upload(Map<String, dynamic>? data) {
    // If no data is provided, use sample data
    final uploadData = data ?? {
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "ax": 1.23,
      "ay": 4.56,
      "az": 7.89,
      "gx": 0.12,
      "gy": 0.34,
      "gz": 0.56,
    };

    db.push().set(uploadData).then((_) {
      print("Data uploaded: $uploadData");
    }).catchError((error) {
      print("Firebase upload error: $error");
    });
  }
}
