import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/bloc/application/application_bloc.dart';
import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/handler/switcher.dart';
import 'package:app/logs/main.dart';
import 'package:app/utils/string.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:fl_query_connectivity_plus_adapter/fl_query_connectivity_plus_adapter.dart';
import 'package:fl_query/fl_query.dart';
import 'package:upgrader/upgrader.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_update/in_app_update.dart' as update;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

final logger = Logger(
  filter: ProductionFilter(),
  printer: PrettyPrinter(),
  output: FileLoggerOutput(),
  level: Level.all,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  }
  await Purchases.setLogLevel(LogLevel.verbose);
  OneSignal.initialize(ONESIGNAL_APP_ID);
  await OneSignal.Location.setShared(false);
  initializeTimeZones();
  PurchasesConfiguration configuration;
  if (Platform.isAndroid) {
    configuration = PurchasesConfiguration(
      REVENUECAT_GOOGLE_KEY,
    );
  } else {
    configuration = PurchasesConfiguration(
      REVENUECAT_IOS_KEY,
    );
  }
  await Purchases.configure(configuration);

  await QueryClient.initialize(
    cachePrefix: 'voice_learn',
    connectivity: FlQueryConnectivityPlusAdapter(),
  );
  if (kDebugMode) {
    runApp(
      QueryClientProvider(
        child: const VoiceLearnApp(),
      ),
    );
  } else {
    await SentryFlutter.init(
      (options) {
        options.dsn = 'https://19a3b39cf3893b0234988f1e59625785@o4507713912897536.ingest.de.sentry.io/4507713920368720';
        // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
        // We recommend adjusting this value in production.
        options.tracesSampleRate = 1.0;
        // The sampling rate for profiling is relative to tracesSampleRate
        // Setting to 1.0 will profile 100% of sampled transactions:
        options.profilesSampleRate = 1.0;
      },
      appRunner: () => runApp(
        QueryClientProvider(
          child: const VoiceLearnApp(),
        ),
      ),
    );
  }
}

class VoiceLearnApp extends StatefulWidget {
  const VoiceLearnApp({super.key});

  @override
  State<VoiceLearnApp> createState() => _VoiceLearnAppState();
}

class _VoiceLearnAppState extends State<VoiceLearnApp> {
  final inAppPurchase = InAppPurchase.instance;
  update.AppUpdateInfo? info;

  Future<void> _checkForUpdates() async {
    if (Platform.isAndroid) {
      update.InAppUpdate.checkForUpdate().then(
        (value) {
          if (value.updateAvailability == update.UpdateAvailability.updateAvailable) {
            update.InAppUpdate.performImmediateUpdate().catchError(() {});
          }
        },
      ).catchError((e) {});
    }
  }

  void _listenForOneSignalUpdates() async {
    OneSignal.User.pushSubscription.addObserver((state) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token");
        if (OneSignal.User.pushSubscription.id != null && OneSignal.User.pushSubscription.id!.isNotEmpty) {
          await http
              .post(
                Uri.parse(
                  "$API_URL/notifications",
                ),
                headers: {
                  "Authorization": "Bearer $token",
                  "Content-Type": 'application/json',
                },
                body: jsonEncode(
                  {
                    "id": OneSignal.User.pushSubscription.id!,
                  },
                ),
              )
              .catchError(
                (_) {},
              );
        } else {
          await http.delete(
            Uri.parse(
              "$API_URL/notifications",
            ),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": 'application/json',
            },
          ).catchError(
            (_) {},
          );
        }
      } catch (e) {}
    });
  }

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
    _listenForOneSignalUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => UserBloc()),
          BlocProvider(create: (context) => ApplicationBloc()),
        ],
        child: AdaptiveTheme(
            debugShowFloatingThemeButton: false,
            light: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
              ),
              useMaterial3: true,
              fontFamily: "Geist",
              brightness: Brightness.light,
              primaryColor: PRIMARY_COLOR,
              appBarTheme: const AppBarTheme(
                elevation: 0,
                scrolledUnderElevation: 0,
                titleTextStyle: TextStyle(
                  fontFamily: "CalSans",
                  fontSize: 24,
                  color: Colors.black,
                ),
                toolbarHeight: 50,
              ),
              textTheme: const TextTheme(
                labelMedium: TextStyle(
                  fontSize: 20,
                ),
                titleLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                titleSmall: TextStyle(
                  fontSize: 16,
                  color: SECONDARY_TEXT_COLOR,
                ),
                titleMedium: TextStyle(
                  fontSize: 24,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PRIMARY_COLOR,
                ),
              ),
            ),
            dark: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              fontFamily: "Geist",
              brightness: Brightness.dark,
              primaryColor: PRIMARY_COLOR,
              appBarTheme: const AppBarTheme(
                elevation: 0,
                scrolledUnderElevation: 0,
                titleTextStyle: TextStyle(
                  fontFamily: "CalSans",
                  fontSize: 24,
                  color: Colors.white,
                ),
                toolbarHeight: 50,
              ),
              textTheme: const TextTheme(
                labelMedium: TextStyle(
                  fontSize: 20,
                ),
                titleLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                titleSmall: TextStyle(
                  fontSize: 16,
                  color: SECONDARY_TEXT_COLOR,
                ),
                titleMedium: TextStyle(
                  fontSize: 24,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PRIMARY_COLOR,
                ),
              ),
            ),
            initial: AdaptiveThemeMode.light,
            builder: (theme, darkTheme) {
              return MaterialApp(
                title: 'Voice Learn',
                navigatorObservers: [
                  routeObserver,
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'),
                  Locale('en', 'IN'),
                ],
                theme: theme,
                darkTheme: theme,
                themeMode: ThemeMode.light,
                home: Platform.isAndroid
                    ? const ViewHandler()
                    : UpgradeAlert(
                        dialogStyle: UpgradeDialogStyle.cupertino,
                        showIgnore: false,
                        showLater: true,
                        showReleaseNotes: true,
                        child: const ViewHandler(),
                      ),
                debugShowCheckedModeBanner: false,
              );
            }),
      ),
    );
  }
}
