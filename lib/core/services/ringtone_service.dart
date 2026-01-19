// // lib/core/services/ringtone_service.dart
// import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
// import 'package:vibration/vibration.dart';
//
// class RingtoneService {
//   static bool _isPlaying = false;
//
//   static Future<void> playIncomingRingtone() async {
//     if (_isPlaying) return;
//
//     try {
//       await FlutterRingtonePlayer.play(
//         android: AndroidRingtoneType.ringtone,
//         ios: IosRingtoneType.calling,
//         looping: true,
//         volume: 1.0,
//       );
//
//       _isPlaying = true;
//
//       // تشغيل الاهتزاز
//       _startVibration();
//     } catch (e) {
//       print('Error playing ringtone: $e');
//     }
//   }
//
//   static Future<void> stopRingtone() async {
//     try {
//       await FlutterRingtonePlayer.stop();
//       _isPlaying = false;
//     } catch (e) {
//       print('Error stopping ringtone: $e');
//     }
//   }
//
//   static void _startVibration() {
//     Timer.periodic(Duration(seconds: 2), (timer) async {
//       if (await Vibration.hasVibrator() ?? false) {
//         Vibration.vibrate(
//           pattern: [0, 500, 200, 500],
//           intensities: [0, 255, 0, 255],
//         );
//       }
//     });
//   }
//
//   static bool get isPlaying => _isPlaying;
// }