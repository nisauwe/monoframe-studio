import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/providers/app_setting_provider.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/package_provider.dart';
import 'data/providers/booking_provider.dart';
import 'data/providers/payment_provider.dart';
import 'data/providers/tracking_provider.dart';
import 'data/providers/call_center_provider.dart';
import 'data/providers/front_office_provider.dart';
import 'data/providers/photographer_provider.dart';
import 'data/providers/edit_request_provider.dart';
import 'data/providers/editor_provider.dart';
import 'data/providers/print_order_provider.dart';
import 'data/providers/front_office_print_order_provider.dart';
import 'data/providers/review_provider.dart';
import 'data/providers/client_notification_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MonoframeClientApp());
}

class MonoframeClientApp extends StatelessWidget {
  const MonoframeClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PackageProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
        ChangeNotifierProvider(create: (_) => CallCenterProvider()),
        ChangeNotifierProvider(create: (_) => FrontOfficeProvider()),
        ChangeNotifierProvider(create: (_) => PhotographerProvider()),
        ChangeNotifierProvider(create: (_) => EditRequestProvider()),
        ChangeNotifierProvider(create: (_) => EditorProvider()),
        ChangeNotifierProvider(create: (_) => PrintOrderProvider()),
        ChangeNotifierProvider(create: (_) => FrontOfficePrintOrderProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => ClientNotificationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Monoframe Studio',
        theme: AppTheme.lightTheme,
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
