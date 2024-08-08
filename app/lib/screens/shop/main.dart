// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/input.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/user.dart';
import 'package:app/screens/shop/transaction.dart';
import 'package:app/utils/error.dart';
import 'package:app/utils/print.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:heroicons/heroicons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:http/http.dart' as http;

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<Package> packages = [];
  List<Widget> FREE_FEATURES = [];
  List<Widget> PREMIUM_FEATURES = [];
  bool _buyOneVoiceCreditLoading = false;
  bool _buyCustomVoiceCreditsLoading = false;
  bool _buyTenVoiceCreditsLoading = false;
  final TextEditingController _countController = TextEditingController();

  Future<bool> _buyVoiceCredits(
    int count,
  ) async {
    final userBloc = context.read<UserBloc>();
    final userState = userBloc.state;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final url = Uri.parse(
      "$API_URL/voice-credits/buy",
    );
    logger.t("Buying $count voice credits: ${url.toString()}");

    final req = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "count": count,
      }),
    );
    final body = jsonDecode(req.body);

    if (req.statusCode != 201) {
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
      logger.e("Failed to login: $message");
      return false;
    } else {
      toastification.show(
        type: ToastificationType.success,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(
          seconds: 5,
        ),
        title: Text(
          "Bought $count voice credits",
        ),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      userBloc.add(
        UserLoggedInEvent.setEmeraldsAndLives(
          userState,
          body['emeralds'],
          null,
          voiceMessages: body['voiceMessages'],
        ),
      );
      setState(() {});
      return true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FREE_FEATURES = [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HeroIcon(
            HeroIcons.microphone,
            style: HeroIconStyle.outline,
            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
          ),
          const SizedBox(
            width: BASE_MARGIN * 2,
          ),
          Text(
            "10 Voice Messages",
            style: TextStyle(
              color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
            ),
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const HeroIcon(
            HeroIcons.academicCap,
            style: HeroIconStyle.outline,
          ),
          const SizedBox(
            width: BASE_MARGIN * 2,
          ),
          Text(
            "Unlimited Lessons",
            style: TextStyle(
              color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
            ),
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HeroIcon(
            HeroIcons.bookOpen,
            style: HeroIconStyle.outline,
            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
          ),
          const SizedBox(
            width: BASE_MARGIN * 2,
          ),
          Text(
            "Unlimited Questions",
            style: TextStyle(
              color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
            ),
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HeroIcon(
            HeroIcons.microphone,
            style: HeroIconStyle.outline,
            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
          ),
          const SizedBox(
            width: BASE_MARGIN * 2,
          ),
          Text(
            "Unlimited Voice Messages*",
            style: TextStyle(
              color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
            ),
          ),
        ],
      ),
      Row(
        children: [
          SvgPicture.asset(
            "assets/svgs/heart.svg",
            width: 25,
            height: 25,
          ),
          const SizedBox(
            width: BASE_MARGIN * 2,
          ),
          Text(
            "1 life every 4 hours",
            style: TextStyle(
              color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
            ),
          ),
        ],
      ),
    ];
    PREMIUM_FEATURES = [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HeroIcon(
            HeroIcons.microphone,
            style: HeroIconStyle.outline,
            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
          ),
          const SizedBox(
            width: BASE_MARGIN * 2,
          ),
          Text(
            "Unlimited Voice Messages",
            style: TextStyle(
              color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
            ),
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HeroIcon(
            HeroIcons.chatBubbleOvalLeft,
            style: HeroIconStyle.outline,
            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
          ),
          const SizedBox(
            width: BASE_MARGIN * 2,
          ),
          Text(
            "Unlimited Chats",
            style: TextStyle(
              color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
            ),
          ),
        ],
      ),
      Row(
        children: [
          SvgPicture.asset(
            "assets/images/emerald.svg",
            width: 25,
            height: 25,
          ),
          const SizedBox(
            width: BASE_MARGIN * 2,
          ),
          Text(
            "Get 100 emeralds daily",
            style: TextStyle(
              color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
            ),
          ),
        ],
      ),
      Row(
        children: [
          SvgPicture.asset(
            "assets/svgs/heart.svg",
            width: 25,
            height: 25,
          ),
          const SizedBox(
            width: BASE_MARGIN * 2,
          ),
          const Icon(
            Icons.all_inclusive_outlined,
          ),
          const SizedBox(
            width: BASE_MARGIN * 2,
          ),
          Text(
            "lives",
            style: TextStyle(
              color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
            ),
          ),
        ],
      ),
      Row(
        children: [
          SvgPicture.asset(
            "assets/svgs/queue.svg",
            width: 25,
            height: 25,
            // ignore: deprecated_member_use
            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
          ),
          const SizedBox(
            width: BASE_MARGIN * 2,
          ),
          Text(
            "Priority in queue",
            style: TextStyle(
              color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
            ),
          ),
        ],
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    super.dispose();
    _countController.dispose();
  }

  Future<void> initialize() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        final emeraldsOffering = offerings.getOffering("Emeralds");
        if (emeraldsOffering != null && emeraldsOffering.availablePackages.isNotEmpty) {
          setState(() {
            packages = emeraldsOffering.availablePackages;
          });
        }
      }
    } on PlatformException catch (e, stackTrace) {
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<UserBloc>().state;
    return Scaffold(
      appBar: AppBar(
        bottom: BOTTOM(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        forceMaterialTransparency: false,
        title: const Text(
          "Shop",
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(
            10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Emeralds",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                      fontFamily: "CalSans",
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: "emerald",
                          child: SvgPicture.asset(
                            "assets/images/emerald.svg",
                            width: 25,
                            height: 25,
                          ),
                        ),
                        const SizedBox(
                          width: BASE_MARGIN * 2,
                        ),
                        Text(
                          state.emeralds.toString(),
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: BASE_MARGIN * 2,
              ),
              QueryBuilder(
                'emeralds',
                () async {
                  Offerings offerings = await Purchases.getOfferings();
                  final emeraldsOffering = offerings.getOffering("Emeralds");
                  if (emeraldsOffering != null && emeraldsOffering.availablePackages.isNotEmpty) return emeraldsOffering.availablePackages;
                  return null;
                },
                builder: (context, query) {
                  if (query.isLoading) {
                    return const Center(
                      child: CupertinoActivityIndicator(
                        radius: 20,
                      ),
                    );
                  }
                  if (query.hasError) {
                    return Center(
                      child: Text(
                        query.error.toString(),
                      ),
                    );
                  }
                  final data = query.data;
                  if (data == null) return const SizedBox();
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    childAspectRatio: 1,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: BASE_MARGIN * 2,
                    crossAxisSpacing: BASE_MARGIN * 2,
                    children: data
                        .map((element) => GestureDetector(
                              onTap: () async {
                                Navigator.of(context).push(NoSwipePageRoute(
                                  builder: (context) {
                                    return TransactionScreen(
                                      type: ProductType.consumable,
                                      storeProduct: element.storeProduct,
                                    );
                                  },
                                )).then((value) {
                                  setState(() {});
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(0),
                                child: Container(
                                  padding: const EdgeInsets.all(
                                    10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: getSecondaryColor(context),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      10,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (element.storeProduct.identifier.endsWith("100")) SvgPicture.asset("assets/svgs/bronze.svg"),
                                      if (element.storeProduct.identifier.endsWith("200")) SvgPicture.asset("assets/svgs/silver.svg"),
                                      if (element.storeProduct.identifier.endsWith("500")) SvgPicture.asset("assets/svgs/gold.svg"),
                                      if (element.storeProduct.identifier.endsWith("1000")) SvgPicture.asset("assets/svgs/platinum.svg"),
                                      const SizedBox(
                                        height: BASE_MARGIN * 2,
                                      ),
                                      Text(
                                        element.storeProduct.title.replaceAll("(Voice Learn)", ""),
                                        style: TextStyle(
                                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                          color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: "CalSans",
                                        ),
                                      ),
                                      const SizedBox(
                                        height: BASE_MARGIN * 2,
                                      ),
                                      Text(
                                        element.storeProduct.priceString,
                                        style: TextStyle(
                                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 0.8,
                                          color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(
                height: BASE_MARGIN * 4,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Voice Credits",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                      fontFamily: "CalSans",
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/svgs/voice_credit.svg",
                          width: 30,
                          height: 30,
                        ),
                        const SizedBox(
                          width: BASE_MARGIN * 2,
                        ),
                        Text(
                          state.voiceMessages.toString(),
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: BASE_MARGIN * 3,
              ),
              GestureDetector(
                onTap: () {
                  WoltModalSheet.show(
                    context: context,
                    pageListBuilder: (context) {
                      return [
                        WoltModalSheetPage(
                          topBarTitle: Text(
                            'Buy Voice Credits',
                            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                  color: Colors.black,
                                ),
                          ),
                          isTopBarLayerAlwaysVisible: true,
                          trailingNavBarWidget: IconButton(
                            padding: const EdgeInsets.all(BASE_MARGIN * 2),
                            icon: const Icon(Icons.close),
                            onPressed: Navigator.of(context).pop,
                          ),
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              return Container(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 10,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            "assets/svgs/voice_credit.svg",
                                            width: 30,
                                            height: 30,
                                          ),
                                          const SizedBox(
                                            width: BASE_MARGIN * 2,
                                          ),
                                          Text(
                                            state.voiceMessages.toString(),
                                            style: TextStyle(
                                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: BASE_MARGIN * 4,
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        setState(() {
                                          _buyOneVoiceCreditLoading = true;
                                        });
                                        await _buyVoiceCredits(
                                          1,
                                        );
                                        setState(() {
                                          _buyOneVoiceCreditLoading = false;
                                        });
                                        if (context.mounted) Navigator.pop(context);
                                      },
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty.all(
                                          getSecondaryColor(context),
                                        ),
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
                                      child: _buyOneVoiceCreditLoading
                                          ? Container(
                                              width: 24,
                                              height: 24,
                                              padding: const EdgeInsets.all(2.0),
                                              child: const CupertinoActivityIndicator(
                                                animating: true,
                                                radius: 20,
                                              ),
                                            )
                                          : Row(
                                              children: [
                                                SvgPicture.asset(
                                                  "assets/svgs/voice_credit.svg",
                                                  width: 30,
                                                  height: 30,
                                                ),
                                                const SizedBox(
                                                  width: BASE_MARGIN * 2,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    "Buy 1 credit",
                                                    style: TextStyle(
                                                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                      fontWeight: FontWeight.w600,
                                                      color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                SvgPicture.asset(
                                                  "assets/images/emerald.svg",
                                                  width: 25,
                                                  height: 25,
                                                ),
                                                const SizedBox(
                                                  width: BASE_MARGIN * 2,
                                                ),
                                                Text(
                                                  "2",
                                                  style: TextStyle(
                                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                    fontWeight: FontWeight.w600,
                                                    color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                    const SizedBox(
                                      height: BASE_MARGIN * 4,
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        setState(() {
                                          _buyTenVoiceCreditsLoading = false;
                                        });
                                        await _buyVoiceCredits(
                                          10,
                                        );
                                        setState(() {
                                          _buyTenVoiceCreditsLoading = true;
                                        });
                                        if (context.mounted) Navigator.pop(context);
                                      },
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty.all(
                                          getSecondaryColor(context),
                                        ),
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
                                      child: _buyTenVoiceCreditsLoading
                                          ? Container(
                                              width: 24,
                                              height: 24,
                                              padding: const EdgeInsets.all(2.0),
                                              child: const CupertinoActivityIndicator(
                                                animating: true,
                                                radius: 20,
                                              ),
                                            )
                                          : Row(
                                              children: [
                                                SvgPicture.asset(
                                                  "assets/svgs/voice_credit.svg",
                                                  width: 30,
                                                  height: 30,
                                                ),
                                                const SizedBox(
                                                  width: BASE_MARGIN * 2,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    "Buy 10 credits",
                                                    style: TextStyle(
                                                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                      fontWeight: FontWeight.w600,
                                                      color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                SvgPicture.asset(
                                                  "assets/images/emerald.svg",
                                                  width: 25,
                                                  height: 25,
                                                ),
                                                const SizedBox(
                                                  width: BASE_MARGIN * 2,
                                                ),
                                                Text(
                                                  (2 * 10).toString(),
                                                  style: TextStyle(
                                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                    fontWeight: FontWeight.w600,
                                                    color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                    const SizedBox(
                                      height: BASE_MARGIN * 4,
                                    ),
                                    ElevatedButton(
                                      onPressed: WoltModalSheet.of(context).showNext,
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty.all(
                                          getSecondaryColor(context),
                                        ),
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
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            "assets/svgs/voice_credit.svg",
                                            width: 30,
                                            height: 30,
                                          ),
                                          const SizedBox(
                                            width: BASE_MARGIN * 2,
                                          ),
                                          Expanded(
                                            child: Text(
                                              "Buy Custom",
                                              style: TextStyle(
                                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                fontWeight: FontWeight.w600,
                                                color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        WoltModalSheetPage(
                          topBarTitle: Text(
                            'Buy Voice Credits',
                            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                  color: Colors.black,
                                ),
                          ),
                          isTopBarLayerAlwaysVisible: true,
                          trailingNavBarWidget: IconButton(
                            padding: const EdgeInsets.all(BASE_MARGIN * 2),
                            icon: const Icon(Icons.close),
                            onPressed: Navigator.of(context).pop,
                          ),
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              return Container(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    InputField(
                                      hintText: "Enter no of credits",
                                      keyboardType: TextInputType.number,
                                      autoFocus: true,
                                      enabled: !_buyCustomVoiceCreditsLoading,
                                      controller: _countController,
                                    ),
                                    SizedBox(
                                      height: BASE_MARGIN.toDouble(),
                                    ),
                                    Text("Max: ${(state.emeralds / 2).floor()}"),
                                    const SizedBox(
                                      height: BASE_MARGIN * 4,
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final count = int.tryParse(_countController.text);
                                        if (count == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                            content: Text(
                                              "Invalid Number",
                                            ),
                                          ));
                                          return;
                                        }
                                        if (count > (state.emeralds / 2).floor()) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                            content: Text(
                                              "Not enough emeralds to buy $count voice credits.",
                                            ),
                                          ));
                                          return;
                                        }
                                        setState(() {
                                          _buyCustomVoiceCreditsLoading = true;
                                        });
                                        await _buyVoiceCredits(
                                          count,
                                        );
                                        setState(() {
                                          _buyCustomVoiceCreditsLoading = false;
                                        });
                                        if (context.mounted) Navigator.pop(context);
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
                                      child: _buyCustomVoiceCreditsLoading
                                          ? Container(
                                              width: 24,
                                              height: 24,
                                              padding: const EdgeInsets.all(2.0),
                                              child: CupertinoActivityIndicator(
                                                color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                radius: 20,
                                              ),
                                            )
                                          : Text(
                                              "Confirm",
                                              style: TextStyle(
                                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ];
                    },
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: getSecondaryColor(
                      context,
                    ),
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                  padding: const EdgeInsets.all(
                    BASE_MARGIN * 4,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        "assets/svgs/voice_credit.svg",
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(
                        width: BASE_MARGIN * 4,
                      ),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Engage in interactive voice chats with the AI. Use them to practice conversations, improve your language skills, and make the most of your learning experience!",
                            ),
                            SizedBox(
                              height: BASE_MARGIN * 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: BASE_MARGIN * 4,
              ),
              Text(
                "Subscriptions",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                  fontFamily: "CalSans",
                ),
              ),
              const SizedBox(
                height: BASE_MARGIN * 3,
              ),
              Container(
                padding: const EdgeInsets.all(
                  BASE_MARGIN * 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                  border: Border.all(
                    color: getSecondaryColor(context),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Premium",
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                        color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        fontFamily: "CalSans",
                      ),
                    ),
                    QueryBuilder(
                      'premium_price',
                      () async {
                        Offerings offerings = await Purchases.getOfferings();
                        if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) return offerings.current!.availablePackages.first;
                        return null;
                      },
                      builder: (context, query) {
                        if (query.hasError) {
                          printError(
                            query.error.toString(),
                          );
                        }
                        if (query.hasError) return const SizedBox();
                        final data = query.data;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            (query.isLoading || data == null)
                                ? Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade400,
                                    child: Container(
                                      height: 10,
                                      width: 70,
                                      decoration: BoxDecoration(
                                        color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  )
                                : Text(
                                    "${data.storeProduct.priceString} / month",
                                    style: TextStyle(
                                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 0.8,
                                      color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                            const SizedBox(
                              height: BASE_MARGIN * 4,
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                return PREMIUM_FEATURES[index];
                              },
                              separatorBuilder: (context, index) {
                                return SizedBox(
                                  height: BASE_MARGIN * (index == PREMIUM_FEATURES.length - 1 ? 0 : 2),
                                );
                              },
                              itemCount: PREMIUM_FEATURES.length,
                            ),
                            const SizedBox(
                              height: BASE_MARGIN * 3,
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                if (state.tier == Tiers.premium) return;
                                if (query.isLoading == false && data != null) {
                                  Navigator.of(context).push(
                                    NoSwipePageRoute(
                                      builder: (context) {
                                        return TransactionScreen(
                                          package: data,
                                          type: ProductType.subscription,
                                        );
                                      },
                                    ),
                                  ).then(
                                    (value) {
                                      setState(() {});
                                    },
                                  );
                                }
                              },
                              style: ButtonStyle(
                                alignment: Alignment.center,
                                backgroundColor: WidgetStateProperty.all(
                                  state.tier == Tiers.free ? PRIMARY_COLOR : SECONDARY_BG_COLOR,
                                ),
                                foregroundColor: WidgetStateProperty.all(AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white),
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
                              child: Text(
                                state.tier == Tiers.premium ? "This is what you have" : "Upgrade Now!",
                                style: TextStyle(
                                  fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: "CalSans",
                                  color: Colors.black,
                                ),
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: BASE_MARGIN * 6,
              ),
              Text(
                "Choose a right plan",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "CalSans",
                  fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                ),
              ),
              const SizedBox(
                height: BASE_MARGIN * 4,
              ),
              Column(
                children: [
                  DataTable(
                    // ignore: deprecated_member_use
                    dataRowHeight: 60,
                    dividerThickness: 1.5,
                    columns: [
                      DataColumn(
                        label: Text(
                          'Monthly Price',
                          style: TextStyle(
                            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      DataColumn(
                        numeric: true,
                        label: Column(
                          children: [
                            Text(
                              "Free",
                              style: TextStyle(
                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.2,
                                color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontFamily: "CalSans",
                              ),
                            ),
                            const SizedBox(
                              height: BASE_MARGIN * 2,
                            ),
                            Text(
                              "\$0",
                              style: TextStyle(
                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 0.8,
                                color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          children: [
                            Text(
                              "Premium",
                              style: TextStyle(
                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.2,
                                color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontFamily: "CalSans",
                              ),
                            ),
                            const SizedBox(
                              height: BASE_MARGIN * 2,
                            ),
                            QueryBuilder(
                              'premium_price',
                              () async {
                                Offerings offerings = await Purchases.getOfferings();
                                if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) return offerings.current!.availablePackages.first;
                                return null;
                              },
                              builder: (context, query) {
                                if (query.hasError) {
                                  printError(
                                    query.error.toString(),
                                  );
                                }
                                if (query.isLoading) {
                                  return Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade400,
                                    child: Container(
                                      height: 10,
                                      width: 70,
                                      decoration: BoxDecoration(
                                        color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }

                                if (query.hasError) return const SizedBox();
                                final data = query.data;
                                if (data == null) return const SizedBox();
                                return Text(
                                  data.storeProduct.priceString,
                                  style: TextStyle(
                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 0.8,
                                    color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    rows: [
                      const DataRow(
                        cells: [
                          DataCell(
                            Text(
                              'Unlimited Modules',
                            ),
                          ),
                          DataCell(
                            Center(
                              child: HeroIcon(
                                HeroIcons.check,
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: HeroIcon(
                                HeroIcons.check,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const DataRow(
                        cells: [
                          DataCell(
                            Text(
                              'Unlimited Lessons',
                            ),
                          ),
                          DataCell(
                            Center(
                              child: HeroIcon(
                                HeroIcons.check,
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: HeroIcon(
                                HeroIcons.check,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const DataRow(
                        cells: [
                          DataCell(Text('Unlimited Questions')),
                          DataCell(
                            Center(
                              child: HeroIcon(
                                HeroIcons.check,
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: HeroIcon(
                                HeroIcons.check,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const DataRow(
                        cells: [
                          DataCell(
                            Text(
                              'Chats',
                            ),
                          ),
                          DataCell(
                            Center(
                              child: Text(
                                "5",
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: Icon(
                                Icons.all_inclusive,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const DataRow(
                        cells: [
                          DataCell(
                            Text('All Voices'),
                          ),
                          DataCell(
                            Center(
                              child: HeroIcon(
                                HeroIcons.xMark,
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: HeroIcon(
                                HeroIcons.check,
                              ),
                            ),
                          ),
                        ],
                      ),
                      DataRow(
                        cells: [
                          DataCell(
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  enableDrag: true,
                                  showDragHandle: true,
                                  builder: (context) {
                                    return Padding(
                                      padding: const EdgeInsets.all(BASE_MARGIN * 2),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Context in AI",
                                            style: TextStyle(
                                              fontFamily: "CalSans",
                                              fontSize: Theme.of(context).textTheme.titleMedium!.fontSize!,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: BASE_MARGIN * 3,
                                          ),
                                          Text(
                                            '"Context" in AI refers to the background information or situation that helps an AI system understand and respond accurately. Just like how we use surrounding clues in a conversation to make sense of it, AI uses context to make better decisions and give more relevant answers.',
                                            style: TextStyle(
                                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: const Text(
                                'Messages Context',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const DataCell(
                            Center(
                              child: Text(
                                "20",
                              ),
                            ),
                          ),
                          const DataCell(
                            Center(
                              child: Text(
                                "100",
                              ),
                            ),
                          ),
                        ],
                      ),
                      const DataRow(
                        cells: [
                          DataCell(
                            Text(
                              'Advanced AI',
                            ),
                          ),
                          DataCell(
                            Center(
                              child: HeroIcon(
                                HeroIcons.xMark,
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: HeroIcon(
                                HeroIcons.check,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const DataRow(
                        cells: [
                          DataCell(
                            Text(
                              'Voice Message Duration',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataCell(
                            Center(
                              child: Text(
                                "00:10",
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                                child: Text(
                              "00:30",
                            )),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 4,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
