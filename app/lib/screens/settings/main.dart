import 'dart:convert';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/input.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/user.dart';
import 'package:app/screens/onboarding/main.dart';
import 'package:app/screens/settings/change_password.dart';
import 'package:app/utils/error.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gravatar/flutter_gravatar.dart';
import 'package:flutter_gravatar/utils.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http_parser/http_parser.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart';
import 'package:mime/mime.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  File? _selectedFile;

  String? avatar;
  bool _loading = false;
  bool _notificationsAllowed = false;
  bool _devModeEnabled = false;
  String _appVersion = "";
  Set<String> voices = {};
  final tts = FlutterTts();
  bool _imageUpload = false;

  Future<void> _updateProfile() async {
    setState(() {
      _loading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final req = await http.patch(Uri.parse("$API_URL/profile"),
        headers: {
          "Authorization": "Bearer $token",
          "content-type": "application/json",
        },
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "name": _nameController.text.trim(),
        }));
    final body = jsonDecode(req.body);
    setState(() {
      _loading = false;
    });
    if (req.statusCode != 200) {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text(
          ApiResponseHelper.getErrorMessage(body),
        ),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
    }
    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.minimal,
      autoCloseDuration: const Duration(seconds: 5),
      description: const Text(
        "Profile Updated",
      ),
      alignment: Alignment.topCenter,
      showProgressBar: false,
    );
    if (mounted) {
      final bloc = context.read<UserBloc>();
      final state = bloc.state;
      bloc.add(
        UserLoggedInEvent.setEmailAndName(
          state,
          body['email'],
          body['name'],
        ),
      );
    }
  }

  Future<void> _setVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _nameController.dispose();
  }

  Future<dynamic> _getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final req = await http.get(
      Uri.parse("$API_URL/profile/@me"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      throw ApiResponseHelper.getErrorMessage(body);
    }
    _nameController.text = body['name'];
    _emailController.text = body['email'];

    _notificationsAllowed = (body['notificationToken'] != null && body['notificationToken'].isNotEmpty) && await Permission.notification.isGranted;
    _devModeEnabled = prefs.getBool("dev_enabled") ?? false;
    return body;
  }

  @override
  void initState() {
    super.initState();
    _setVersion();
    _fetchTTSVoices();
  }

  Future<void> _fetchTTSVoices() async {
    final voices = await tts.getVoices;
    final Set<String> uniqueVoiceNames = (voices as List).map<String>((voice) => voice['name'] as String).toSet();

    setState(() {
      this.voices = uniqueVoiceNames;
    });
    if (Platform.isIOS) {
      await tts.setSharedInstance(true);
      await tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.ambient,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    }
    await tts.awaitSpeakCompletion(true);
  }

  Future<void> _deleteMyAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    logger.t("Deleting Profile");
    final req = await http.delete(
      Uri.parse("$API_URL/profile/@me"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      final message = ApiResponseHelper.getErrorMessage(body);
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text(message),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      logger.e("Failed to delete account: $message");
      return;
    } else {
      toastification.show(
        type: ToastificationType.info,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("Account added for deletion."),
        description: const Text("We will notify you via email when your account is deleted."),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      await Future.delayed(
        const Duration(
          seconds: 2,
        ),
      );
      if (!mounted) return;
      context.read<UserBloc>().add(
            UserLoggedOutEvent(
              id: '',
              name: '',
              createdAt: '',
              paths: -1,
              updatedAt: '',
              token: '',
              emeralds: -1,
              lives: -1,
              xp: -1,
              streaks: -1,
              isStreakActive: false,
              tier: Tiers.free,
              voiceMessages: -1,
            ),
          );
      if (context.mounted) {
        Navigator.of(context).pop();
        final prefs = await SharedPreferences.getInstance();
        prefs.clear();
        if (mounted) {
          await AdaptiveTheme.of(context).persist();
        }
        logger.t("Logged out");
        if (mounted) {
          QueryClient.of(context).getQueriesWithPrefix('voice_learn').clear();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const OnboardingScreen(),
            ),
            (Route<dynamic> route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Account",
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(
              BASE_MARGIN * 4,
            ),
            child: QueryBuilder<dynamic, dynamic>(
              'account',
              _getUserProfile,
              refreshConfig: RefreshConfig.withDefaults(
                context,
                refreshOnMount: true,
                refreshOnQueryFnChange: true,
              ),
              builder: (context, query) {
                if (query.isLoading) {
                  return _buildLoader();
                }
                if (query.hasError) {
                  return Center(
                    child: Text(query.error.toString()),
                  );
                }
                final data = query.data;
                if (data == null) return _buildLoader();

                final userAvatar = data['avatar'] ??
                    Gravatar(
                      _emailController.text.isNotEmpty && _emailController.text.isValidEmail() ? _emailController.text : context.read<UserBloc>().state.email!,
                    ).imageUrl();
                return Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          foregroundImage: CachedNetworkImageProvider(
                            userAvatar,
                          ),
                        ),
                      ),
                      ChangeAvatarButton(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            compressionQuality: 0,
                          );
                          if (result != null) {
                            setState(() {
                              _selectedFile = File(result.files.single.path!);
                            });
                            _showImagePreview(query);
                          } else {
                            // User canceled the picker
                          }
                        },
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 5,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Name",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 2,
                          ),
                          InputField(
                            hintText: "John Doe",
                            keyboardType: TextInputType.text,
                            controller: _nameController,
                            validator: (p0) {
                              if (p0 == null || p0.isEmpty) return 'Name is required';
                              return null;
                            },
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 4,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 3,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Email",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 2,
                          ),
                          InputField(
                            hintText: "johndoe@gmail.com",
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                            validator: (p0) {
                              if (p0 == null || p0.isEmpty) return 'Email is required';
                              return null;
                            },
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 4,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 3,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Password",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 2,
                          ),
                          GestureDetector(
                            onTap: () async {
                              Navigator.of(context).push(
                                NoSwipePageRoute(
                                  builder: (context) {
                                    return const ChangePasswordScreen();
                                  },
                                ),
                              );
                            },
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? const Color(0xffe7e0e8) : const Color(0xff36343a),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "••••••••",
                                  style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 4,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 3,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate() == false) return;
                          await _updateProfile();
                        },
                        style: ButtonStyle(
                          alignment: Alignment.center,
                          foregroundColor: WidgetStateProperty.all(Colors.black),
                          padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry>(
                            (Set<WidgetState> states) {
                              return const EdgeInsets.all(15);
                            },
                          ),
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        child: _loading
                            ? Container(
                                width: 24,
                                height: 24,
                                padding: const EdgeInsets.all(2.0),
                                child: const CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                "Save",
                                style: TextStyle(
                                  fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 6,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Notifications",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 2,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: getSecondaryColor(context),
                              borderRadius: BorderRadius.circular(
                                10,
                              ),
                            ),
                            child: ListTile(
                              title: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: BASE_MARGIN * 1,
                                ),
                                child: Text(
                                  "Streak Notifications",
                                  style: TextStyle(
                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              subtitle: const Text(
                                "Notify me few hours before my streak resets.",
                                style: TextStyle(
                                  color: SECONDARY_TEXT_COLOR,
                                ),
                                softWrap: true,
                              ),
                              trailing: Switch.adaptive(
                                value: _notificationsAllowed,
                                onChanged: (value) async {
                                  final prefs = await SharedPreferences.getInstance();
                                  final token = prefs.getString("token");
                                  if (value == true) {
                                    final res = await OneSignal.Notifications.requestPermission(
                                      false,
                                    );
                                    if (res == false) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                          content: Text(
                                            "Notifications Permission Denied. Please allow the permission.",
                                          ),
                                        ));
                                      }
                                      Future.delayed(
                                        const Duration(seconds: 1),
                                        () async {
                                          await openAppSettings();
                                        },
                                      );
                                      return;
                                    }

                                    await OneSignal.User.pushSubscription.optIn();
                                    if (OneSignal.User.pushSubscription.id != null) {
                                      setState(() {
                                        _notificationsAllowed = true;
                                      });
                                      try {
                                        await http.post(
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
                                        );
                                      } catch (e, trace) {
                                        await Sentry.captureException(
                                          e,
                                          stackTrace: trace,
                                        );
                                      }
                                    }
                                  } else {
                                    await OneSignal.User.pushSubscription.optOut();
                                    setState(() {
                                      _notificationsAllowed = false;
                                    });
                                    try {
                                      await http.delete(
                                        Uri.parse(
                                          "$API_URL/notifications",
                                        ),
                                        headers: {
                                          "Authorization": "Bearer $token",
                                          "Content-Type": 'application/json',
                                        },
                                      );
                                    } catch (e, trace) {
                                      await Sentry.captureException(
                                        e,
                                        stackTrace: trace,
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 4,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 2,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Appearance",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 2,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: getSecondaryColor(context),
                              borderRadius: BorderRadius.circular(
                                10,
                              ),
                            ),
                            child: ListTile(
                                title: Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: BASE_MARGIN * 1,
                                  ),
                                  child: Text(
                                    "Theme",
                                    style: TextStyle(
                                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                trailing: DropdownButton(
                                  value: AdaptiveTheme.of(context).mode.toString().replaceFirst("AdaptiveThemeMode.", "").toLowerCase(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: "light",
                                      child: Text("Light"),
                                    ),
                                    DropdownMenuItem(
                                      value: "dark",
                                      child: Text("Dark"),
                                    ),
                                  ],
                                  onChanged: (value) async {
                                    if (value == "light") {
                                      AdaptiveTheme.of(context).setLight();
                                    } else {
                                      AdaptiveTheme.of(context).setDark();
                                    }
                                    final prefs = await SharedPreferences.getInstance();
                                    prefs.setString("theme", value ?? "dark");
                                  },
                                )),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 4,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 2,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Developer Mode",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 2,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: getSecondaryColor(context),
                              borderRadius: BorderRadius.circular(
                                10,
                              ),
                            ),
                            child: ListTile(
                              title: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: BASE_MARGIN * 1,
                                ),
                                child: Text(
                                  "Enable Developer Mode",
                                  style: TextStyle(
                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              subtitle: const Text(
                                "Enable Developer Only Options(can cause weird behaviour).",
                                style: TextStyle(
                                  color: SECONDARY_TEXT_COLOR,
                                ),
                                softWrap: true,
                              ),
                              trailing: Switch.adaptive(
                                value: _devModeEnabled,
                                onChanged: (value) async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setBool("dev_enabled", value);
                                  setState(() {
                                    _devModeEnabled = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 4,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 2,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Danger Zone",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 2,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: getSecondaryColor(context),
                              borderRadius: BorderRadius.circular(
                                10,
                              ),
                            ),
                            child: ListTile(
                              title: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: BASE_MARGIN * 1,
                                ),
                                child: Text(
                                  "LogOut",
                                  style: TextStyle(
                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10,
                                        ),
                                      ),
                                      title: const Text("Log Out"),
                                      content: const Text("Are you sure you want to log out?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Close the dialog
                                          },
                                          child: Text(
                                            "Cancel",
                                            style: TextStyle(
                                              color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            context.read<UserBloc>().add(
                                                  UserLoggedOutEvent(
                                                    id: '',
                                                    name: '',
                                                    createdAt: '',
                                                    paths: -1,
                                                    updatedAt: '',
                                                    token: '',
                                                    emeralds: -1,
                                                    lives: -1,
                                                    xp: -1,
                                                    streaks: -1,
                                                    isStreakActive: false,
                                                    tier: Tiers.free,
                                                    voiceMessages: -1,
                                                  ),
                                                );
                                            if (context.mounted) {
                                              Navigator.of(context).pop();
                                              final prefs = await SharedPreferences.getInstance();
                                              prefs.clear();
                                              if (context.mounted) {
                                                await AdaptiveTheme.of(context).persist();
                                              }
                                              logger.t("Logged out");
                                              if (context.mounted) {
                                                QueryClient.of(context).getQueriesWithPrefix('voice_learn').clear();
                                                Navigator.of(context).pushAndRemoveUntil(
                                                  MaterialPageRoute(
                                                    builder: (context) => const OnboardingScreen(),
                                                  ),
                                                  (Route<dynamic> route) => false,
                                                );
                                              }
                                            }
                                          },
                                          child: const Text(
                                            "Log Out",
                                            style: TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              trailing: const Icon(
                                Icons.logout,
                                color: Colors.red,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 2,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: getSecondaryColor(context),
                              borderRadius: BorderRadius.circular(
                                10,
                              ),
                            ),
                            child: ListTile(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10,
                                        ),
                                      ),
                                      title: const Text("Delete Account?"),
                                      content: const Text("Are you sure you want to delete your account? This action is irreversible."),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Close the dialog
                                          },
                                          child: Text(
                                            "Cancel",
                                            style: TextStyle(
                                              color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _deleteMyAccount,
                                          child: const Text(
                                            "Confirm",
                                            style: TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              title: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: BASE_MARGIN * 1,
                                ),
                                child: Text(
                                  "Delete My Account",
                                  style: TextStyle(
                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              subtitle: const Text("This will delete all of your data. This can take few hours."),
                              trailing: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: BASE_MARGIN * 4,
                          ),
                        ],
                      ),
                      Text(
                        "App Version: $_appVersion",
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePreview(Query<dynamic, dynamic> query) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
            content: _selectedFile != null
                ? Image.file(
                    _selectedFile!,
                  )
                : Container(),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedFile = null;
                  });
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString("token");
                  setState(() {
                    _imageUpload = true;
                  });
                  final url = Uri.parse("$API_URL/uploads/public");
                  logger.t("Uploading image: ${url.toString()}");
                  var request = http.MultipartRequest("POST", url);
                  request.files.add(
                    await http.MultipartFile.fromPath(
                      'file',
                      _selectedFile!.path,
                      contentType: MediaType.parse(lookupMimeType(_selectedFile!.path) ?? "image/png"),
                    ),
                  );
                  request.headers['Authorization'] = "Bearer $token";
                  final res = await http.Response.fromStream(await request.send());
                  final body = jsonDecode(res.body);
                  if (res.statusCode != 201) {
                    final message = ApiResponseHelper.getErrorMessage(body);
                    logger.e(message);
                    toastification.show(
                      type: ToastificationType.error,
                      style: ToastificationStyle.minimal,
                      autoCloseDuration: const Duration(seconds: 5),
                      title: const Text("An Error Occurred"),
                      description: Text(message),
                      alignment: Alignment.topCenter,
                      showProgressBar: false,
                    );
                    setState(() {
                      _imageUpload = false;
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    return;
                  }

                  final uploadProfileUrl = Uri.parse("$API_URL/profile");
                  logger.t("Updating Profile: ${uploadProfileUrl.toString()}");
                  final updateProfileReq = await http.patch(
                    uploadProfileUrl,
                    headers: {
                      "Authorization": "Bearer $token",
                      "Content-type": "application/json",
                    },
                    body: jsonEncode(
                      {
                        "avatar": body['url'],
                      },
                    ),
                  );
                  final updateProfileBody = jsonDecode(updateProfileReq.body);
                  if (updateProfileReq.statusCode != 200) {
                    final message = ApiResponseHelper.getErrorMessage(updateProfileBody);
                    logger.e(message);
                    toastification.show(
                      type: ToastificationType.error,
                      style: ToastificationStyle.minimal,
                      autoCloseDuration: const Duration(seconds: 5),
                      title: const Text("An Error Occurred"),
                      description: Text(message),
                      alignment: Alignment.topCenter,
                      showProgressBar: false,
                    );
                    setState(() {
                      _imageUpload = false;
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    return;
                  }

                  toastification.show(
                    type: ToastificationType.success,
                    style: ToastificationStyle.minimal,
                    autoCloseDuration: const Duration(seconds: 5),
                    title: const Text("Profile Updated"),
                    alignment: Alignment.topCenter,
                    showProgressBar: false,
                  );
                  setState(() {
                    _imageUpload = false;
                  });
                  await query.refresh();
                  if (context.mounted) {
                    await QueryClient.of(context).refreshQuery('profile_stats');
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  return;
                },
                child: _imageUpload
                    ? const CircularProgressIndicator.adaptive()
                    : const Text(
                        'Upload',
                        style: TextStyle(
                          color: PRIMARY_COLOR,
                        ),
                      ),
              ),
            ],
          );
        });
      },
    );
  }

  Column _buildLoader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
          ),
        ),
        ChangeAvatarButton(
          onPressed: () {},
        ),
        const SizedBox(height: 20),
        const ShimmerLoader(label: "Email"),
        const ShimmerLoader(label: "Name"),
        const ShimmerLoader(label: "Password"),
        const SizedBox(height: 20),
        const ShimmerButtonLoader(width: 200, height: 50),
        const SizedBox(height: 10),
        const ShimmerButtonLoader(width: 200, height: 50),
      ],
    );
  }
}

class ChangeAvatarButton extends StatelessWidget {
  final Function()? onPressed;
  const ChangeAvatarButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed ?? () {},
      child: const Text(
        "Change Avatar",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ShimmerLoader extends StatelessWidget {
  final String label;

  const ShimmerLoader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class ShimmerButtonLoader extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerButtonLoader({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            10,
          ),
        ),
      ),
    );
  }
}
