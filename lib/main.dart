import 'package:dress_ai/firebase_options.dart';
import 'package:dress_ai/screens/closet_screen.dart';
import 'package:dress_ai/screens/home_screen.dart';
import 'package:dress_ai/screens/import_url_screen.dart';
import 'package:dress_ai/screens/upload_photo_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        '/importUrl': (_) => ImportUrlScreen(),
        '/uploadPhoto': (_) => UploadPhotoScreen(),
        '/closet': (_) => ClosetScreen(),
      },
    );
  }
}