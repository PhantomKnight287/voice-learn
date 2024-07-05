import 'dart:convert';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/input.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/user.dart';
import 'package:app/screens/onboarding/main.dart';
import 'package:app/screens/settings/change_password.dart';
import 'package:app/utils/error.dart';
import 'package:app/utils/print.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gravatar/flutter_gravatar.dart';
import 'package:flutter_gravatar/utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? avatar;
  bool _loading = false;
  bool _notificationsAllowed = false;

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
          "email": _emailController.text,
          "name": _nameController.text,
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
    if (context.mounted) {
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

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _nameController.dispose();
  }

  Future<dynamic> _getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final req = await http.get(Uri.parse("$API_URL/profile/@me"), headers: {"Authorization": "Bearer $token"});
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      throw ApiResponseHelper.getErrorMessage(body);
    }
    _nameController.text = body['name'];
    _emailController.text = body['email'];
    _notificationsAllowed = (body['notificationToken'] != null && body['notificationToken'].isNotEmpty) && await Permission.notification.isGranted;
    return body;
  }

  @override
  void initState() {
    super.initState();
    OneSignal.User.pushSubscription.addObserver((state) async {
      printWarning("ok");
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Account",
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
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
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.black,
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
                                ),
                              );
                          // Perform log out action here
                          Navigator.of(context).pop(); // Close the dialog
                          final prefs = await SharedPreferences.getInstance();
                          prefs.remove("token");
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const OnboardingScreen(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                          // Add your log out logic here
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
            icon: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
          ),
        ],
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

                final userAvatar = Gravatar(
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
                          foregroundImage: NetworkImage(
                            userAvatar,
                          ),
                        ),
                      ),
                      ChangeAvatarButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Opening Gravatar...",
                              ),
                            ),
                          );
                          Future.delayed(
                            const Duration(
                              seconds: 2,
                            ),
                            () async {
                              const url = 'https://gravatar.com/';
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(
                                  Uri.parse(url),
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                throw 'Could not launch $url';
                              }
                            },
                          );
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
                            keyboardType: TextInputType.emailAddress,
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
                                color: const Color(0xffe7e0e8),
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
                              color: SECONDARY_BG_COLOR,
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
                                "Notify me 2 hours before my streak resets.",
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
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text(
                                          "Notifications Permission Denied. Please allow the permission.",
                                        ),
                                      ));
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
                                      } catch (e) {}
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
                                    } catch (e) {}
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
          color: Colors.black,
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
