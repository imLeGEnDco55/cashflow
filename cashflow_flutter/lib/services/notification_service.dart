import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/finance.dart';

/// Fixed notification IDs
const int _dailyReminderId = 99999;

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
      // Cancel only payment reminders (not daily reminder)
      // Cancel all then re-schedule everything including daily reminder
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

  /// Schedule daily reminder at 9PM: "Psss! No olvides registrar tus gastos"
  static Future<void> scheduleDailyReminder({required bool enabled}) async {
    try {
      // Always cancel existing daily reminder first
      await _notifications.cancel(_dailyReminderId);

      if (!enabled) return;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        21, // 9:00 PM
        0,
      );

      // If 9PM already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        _dailyReminderId,
        '💰 CashFlow',
        'Psss! No olvides registrar tus gastos de hoy',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Recordatorio Diario',
            channelDescription: 'Recordatorio para registrar gastos',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );
    } catch (_) {
      // Notifications not available
    }
  }

  /// Cancel today's daily reminder (user already registered something)
  static Future<void> cancelDailyReminder() async {
    try {
      await _notifications.cancel(_dailyReminderId);
    } catch (_) {}
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
