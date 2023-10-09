import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    final AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> updateDownloadProgress(int id, int progress) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('download_channel_id', 'Download Channel',
            channelDescription: 'Notification Channel for Downloads',
            importance: Importance.max,
            priority: Priority.high,
            onlyAlertOnce: true,
            showProgress: true,
            maxProgress: 100,
            progress: progress,
            colorized: true,
            actions: [
          AndroidNotificationAction(
            'cancel_button_id',
            'Cancel',
          ),
        ]
            // ledColor: Colors.green,
            );

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      id,
      '${progress.toString()}%',
      'Download in progress...',
      notificationDetails,
    );
  }
}
