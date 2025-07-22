import 'package:dress_ai/firebase_options.dart';
import 'package:dress_ai/screens/closet_screen.dart';
import 'package:dress_ai/screens/home_screen.dart';
import 'package:dress_ai/screens/looks_screen.dart';
import 'package:dress_ai/screens/upload_photo_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Autenticación anónima si no está logueado
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }
  await EasyLocalization.ensureInitialized();
  runApp(EasyLocalization(
    supportedLocales: [Locale('en'), Locale('es')],
    path: 'assets/translations',
    fallbackLocale: Locale('en'),
    child: MyApp(),
  ),);
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Closet App',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      initialRoute: '/',
      routes: {
        '/': (_) => HomeScreen(),
        '/uploadPhoto': (_) => UploadPhotoScreen(),
        '/closet': (_) => ClosetScreen(),
        '/looks': (_) => LooksScreen(),
      },
    );
  }
}