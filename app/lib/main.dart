import 'dart:async';
import 'dart:io';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/handler/switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:toastification/toastification.dart';
import 'package:fl_query_connectivity_plus_adapter/fl_query_connectivity_plus_adapter.dart';
import 'package:fl_query/fl_query.dart';
import 'package:upgrader/upgrader.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_update/in_app_update.dart' as update;

final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());
  await QueryClient.initialize(
    cachePrefix: 'voice_learn',
    connectivity: FlQueryConnectivityPlusAdapter(),
  );
  runApp(
    QueryClientProvider(
      child: const VoiceLearnApp(),
    ),
  );
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
            update.InAppUpdate.performImmediateUpdate().catchError((e) {});
          }
        },
      ).catchError((e) {});
    }
  }

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => UserBloc()),
        ],
        child: MaterialApp(
          title: 'Voice Learn',
          navigatorObservers: [routeObserver],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            fontFamily: "Geist",
            brightness: Brightness.light,
            primaryColor: PRIMARY_COLOR,
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            textTheme: const TextTheme(
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
        ),
      ),
    );
  }
}
