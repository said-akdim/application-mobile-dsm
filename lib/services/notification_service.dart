import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  /// Notifie si de nouveaux produits ont été trouvés depuis la dernière vérification.
  static Future<void> checkAndNotifyNewProducts(List<dynamic> products) async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt('last_new_products_check') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Ne vérifier qu'une fois par heure maximum
    if (now - lastCheck < 3600 * 1000) return;

    final newOnes = products.where((p) => p.isNew == true).toList();
    if (newOnes.isEmpty) {
      await prefs.setInt('last_new_products_check', now);
      return;
    }

    final lastNotified = prefs.getInt('last_notified_count') ?? 0;
    if (newOnes.length <= lastNotified) {
      await prefs.setInt('last_new_products_check', now);
      return;
    }

    await prefs.setInt('last_new_products_check', now);
    await prefs.setInt('last_notified_count', newOnes.length);

    final count = newOnes.length;
    await _plugin.show(
      1001,
      count == 1
          ? '📚 Nouvelle arrivée !'
          : '📚 $count nouvelles arrivées !',
      count == 1
          ? '${newOnes.first.name} vient d\'être ajouté à notre catalogue.'
          : 'Découvrez les dernières nouveautés de la Librairie DSM.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dsm_news',
          'Nouveautés',
          channelDescription: 'Alertes nouvelles arrivées',
          importance: Importance.high,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
}
