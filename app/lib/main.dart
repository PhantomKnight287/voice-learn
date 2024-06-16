import 'dart:async';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/handler/switcher.dart';
import 'package:fl_query_devtools/fl_query_devtools.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:toastification/toastification.dart';
import 'package:fl_query_connectivity_plus_adapter/fl_query_connectivity_plus_adapter.dart';
import 'package:fl_query/fl_query.dart';

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
      child: VoiceLearnApp(),
    ),
  );
}

class VoiceLearnApp extends StatelessWidget {
  const VoiceLearnApp({super.key});

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
          home: const ViewHandler(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
