import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/finance.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);
  }

  static Future<void> schedulePaymentReminders(List<FinanceCard> cards) async {
    try {
      await _notifications.cancelAll();

      for (var card in cards) {
        if (card.type == 'credit' && card.paymentDay != null) {
          await _scheduleMonthly(
            id: card.id.hashCode,
            title: '💳 Pago de tarjeta',
            body: 'Hoy es día de pago para "${card.name}"',
            day: card.paymentDay!,
          );
        }
      }
    } catch (_) {
      // Notifications not available on web platform
    }
  }

  static Future<void> _scheduleMonthly({
    required int id,
    required String title,
    required String body,
    required int day,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      day,
      9,
      0,
    ); // 9:00 AM

    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        day,
        9,
        0,
      );
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_reminders',
          'Recordatorios de Pago',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }
}
