import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Screens
import 'screens/signup_page.dart';
import 'screens/login_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/animal_profiles_page.dart';
import 'screens/animal_detail_page.dart';
import 'screens/edit_animal_page.dart';
import 'screens/add_animal_page.dart';
import 'screens/animal_analytics_page.dart';
import 'screens/alerts_page.dart';
import 'screens/settings_page.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Notification permissions
  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint(
      '🔔 Notification permission status: ${settings.authorizationStatus}');

  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('📱 FCM token: $token');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      debugPrint("📩 Foreground notification: ${message.notification!.title}");
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text(message.notification!.title ?? 'New alert')),
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("👉 Notification clicked!");
    navigatorKey.currentState?.pushNamed('/alerts');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Cattle Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.pink[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 24,
          ),
        ),
      ),
      home: const AuthGate(),

      // Standard routes
      routes: {
        '/signup': (context) => const SignUpPage(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => DashboardPage(),
        '/profiles': (context) => const AnimalProfilesPage(),
        '/add_animal': (context) => AddAnimalPage(),
        '/analytics': (context) => AnimalAnalyticsPage(),
        '/alerts': (context) => AlertsPage(),
        '/settings': (context) => SettingsPage(),
      },

      // Routes with arguments
      onGenerateRoute: (settings) {
        if (settings.name == '/animalDetail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => AnimalDetailPage(
              animalId: args['animalId'],
              animalData: args['animalData'],
            ),
          );
        }

        if (settings.name == '/editAnimal') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => EditAnimalPage(
              animalDocId: args['animalDocId'],
              animalData: args['animalData'],
            ),
          );
        }

        return null;
      },
    );
  }
}

/// 🔹 AuthGate listens to FirebaseAuth state and decides which screen to show
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Error connecting to Firebase")),
          );
        }
        if (!snapshot.hasData) {
          return const LoginPage(); // Show login if not signed in
        }
        return DashboardPage(); // Show dashboard if signed in
      },
    );
  }
}
