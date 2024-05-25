import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/handler/switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoiceLearnApp());
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
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            fontFamily: "Geist",
            brightness: Brightness.light,
            primaryColor: PRIMARY_COLOR,
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
