import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/models/user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import 'package:app/classes/sku.dart';
import 'package:app/constants/main.dart';
import 'package:app/utils/print.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:heroicons/heroicons.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shimmer/shimmer.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late final FREE_FEATURES = [
    Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const HeroIcon(
          HeroIcons.speakerWave,
          style: HeroIconStyle.outline,
          color: Colors.black,
        ),
        const SizedBox(
          width: BASE_MARGIN * 2,
        ),
        Text(
          "6 voices",
          style: TextStyle(
            color: Colors.black,
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
            color: Colors.black,
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
          HeroIcons.bookOpen,
          style: HeroIconStyle.outline,
          color: Colors.black,
        ),
        const SizedBox(
          width: BASE_MARGIN * 2,
        ),
        Text(
          "Unlimited Questions",
          style: TextStyle(
            color: Colors.black,
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
          HeroIcons.chatBubbleOvalLeft,
          style: HeroIconStyle.outline,
          color: Colors.black,
        ),
        const SizedBox(
          width: BASE_MARGIN * 2,
        ),
        Text(
          "Unlimited Chats",
          style: TextStyle(
            color: Colors.black,
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
          HeroIcons.microphone,
          style: HeroIconStyle.outline,
          color: Colors.black,
        ),
        const SizedBox(
          width: BASE_MARGIN * 2,
        ),
        Text(
          "Unlimited Voice Messages*",
          style: TextStyle(
            color: Colors.black,
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
            color: Colors.black,
            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
          ),
        ),
      ],
    ),
  ];
  late final PREMIUM_FEATURES = [
    Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const HeroIcon(
          HeroIcons.check,
          style: HeroIconStyle.outline,
          color: Colors.black,
        ),
        const SizedBox(
          width: BASE_MARGIN * 2,
        ),
        Text(
          "All free plan features and...",
          style: TextStyle(
            color: Colors.black,
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
          HeroIcons.speakerWave,
          style: HeroIconStyle.outline,
          color: Colors.black,
        ),
        const SizedBox(
          width: BASE_MARGIN * 2,
        ),
        Text(
          "Unlock 40+ voices",
          style: TextStyle(
            color: Colors.black,
            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
          ),
        ),
      ],
    ),
    Row(
      children: [
        Image.asset(
          "assets/images/emerald.png",
          width: 25,
          height: 25,
        ),
        const SizedBox(
          width: BASE_MARGIN * 2,
        ),
        Text(
          "Get 100 emeralds daily",
          style: TextStyle(
            color: Colors.black,
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
          "Full lives every 4 hours",
          style: TextStyle(
            color: Colors.black,
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
          color: Colors.black,
        ),
        const SizedBox(
          width: BASE_MARGIN * 2,
        ),
        Text(
          "Priority in queue",
          style: TextStyle(
            color: Colors.black,
            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
          ),
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(
        seconds: 5,
      ),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<UserBloc>().state;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Membership",
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.titleMedium!.fontSize!,
            fontWeight: FontWeight.w600,
            fontFamily: "CalSans",
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        forceMaterialTransparency: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(
                    BASE_MARGIN * 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                    border: Border.all(
                      color: const Color(0xffebebeb),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Free",
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          fontFamily: "CalSans",
                        ),
                      ),
                      Text(
                        "\$0 / mo",
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 0.8,
                          color: Colors.black,
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
                          return FREE_FEATURES[index];
                        },
                        separatorBuilder: (context, index) {
                          return const SizedBox(
                            height: BASE_MARGIN * 2,
                          );
                        },
                        itemCount: FREE_FEATURES.length,
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 2,
                      ),
                      const Text(
                        "*Each voice message costs 1 emerald.",
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 4,
                      ),
                      ElevatedButton(
                        onPressed: () {},
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
                          backgroundColor: WidgetStateProperty.all(
                            SECONDARY_BG_COLOR,
                          ),
                        ),
                        child: Text(
                          state.tier == Tiers.free ? "This is what you have" : "Already included in Premium",
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            fontWeight: FontWeight.w600,
                            fontFamily: "CalSans",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: BASE_MARGIN * 4,
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
                      color: const Color(0xffebebeb),
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
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          fontFamily: "CalSans",
                        ),
                      ),
                      QueryBuilder(
                        'premium_price',
                        () async {
                          final instance = InAppPurchase.instance;
                          if (!await instance.isAvailable()) throw "Billing not available on your device";
                          final info = await instance.queryProductDetails(
                            {InAppSubscriptionsPurchaseSku.premium},
                          );
                          if (info.notFoundIDs.isNotEmpty) throw "Failed to load pricing";
                          return info.productDetails[0];
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
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }

                          if (query.hasError) return const SizedBox();
                          final data = query.data;
                          if (data == null) return const SizedBox();
                          return Text(
                            "${data.price} / month",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 0.8,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
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
                          return const SizedBox(
                            height: BASE_MARGIN * 2,
                          );
                        },
                        itemCount: PREMIUM_FEATURES.length,
                      ),
                      const SizedBox(
                        height: BASE_MARGIN * 4,
                      ),
                      ElevatedButton(
                        onPressed: () {},
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
                        child: Text(
                          state.tier == Tiers.premium ? "This is what you have" : "Upgrade Now!",
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            fontWeight: FontWeight.w600,
                            fontFamily: "CalSans",
                          ),
                        ),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            "Monthly Price",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              "Free",
                              style: TextStyle(
                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.2,
                                color: Colors.black,
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
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          width: BASE_MARGIN * 3,
                        ),
                        Column(
                          children: [
                            Text(
                              "Premium",
                              style: TextStyle(
                                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.2,
                                color: Colors.black,
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
                                final instance = InAppPurchase.instance;
                                if (!await instance.isAvailable()) throw "Billing not available on your device";
                                final info = await instance.queryProductDetails(
                                  {InAppSubscriptionsPurchaseSku.premium},
                                );
                                if (info.notFoundIDs.isNotEmpty) throw "Failed to load pricing";
                                return info.productDetails[0];
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
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }

                                if (query.hasError) return const SizedBox();
                                final data = query.data;
                                if (data == null) return const SizedBox();
                                return Text(
                                  data.price,
                                  style: TextStyle(
                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 0.8,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                    const Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "Unlimited Chats",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 25,
                          ),
                          child: HeroIcon(
                            HeroIcons.check,
                          ),
                        ),
                        const SizedBox(
                          width: BASE_MARGIN * 3,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 18,
                          ),
                          child: HeroIcon(
                            HeroIcons.check,
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "Unlimited Voice Messages",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 25,
                          ),
                          child: HeroIcon(
                            HeroIcons.check,
                          ),
                        ),
                        const SizedBox(
                          width: BASE_MARGIN * 3,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 18,
                          ),
                          child: HeroIcon(
                            HeroIcons.check,
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "Unlimited Lessons",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 25,
                          ),
                          child: HeroIcon(
                            HeroIcons.check,
                          ),
                        ),
                        const SizedBox(
                          width: BASE_MARGIN * 3,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 18,
                          ),
                          child: HeroIcon(
                            HeroIcons.check,
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "Unlimited Questions",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 25,
                          ),
                          child: HeroIcon(
                            HeroIcons.check,
                          ),
                        ),
                        const SizedBox(
                          width: BASE_MARGIN * 3,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 18,
                          ),
                          child: HeroIcon(
                            HeroIcons.check,
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "Unlimited Modules",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 25,
                          ),
                          child: HeroIcon(
                            HeroIcons.check,
                          ),
                        ),
                        const SizedBox(
                          width: BASE_MARGIN * 3,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 18,
                          ),
                          child: HeroIcon(
                            HeroIcons.check,
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "All Voices",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 25,
                          ),
                          child: HeroIcon(
                            HeroIcons.xMark,
                          ),
                        ),
                        const SizedBox(
                          width: BASE_MARGIN * 3,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 18,
                          ),
                          child: HeroIcon(
                            HeroIcons.check,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "Priority in Queue",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 25,
                          ),
                          child: HeroIcon(
                            HeroIcons.xMark,
                          ),
                        ),
                        const SizedBox(
                          width: BASE_MARGIN * 3,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 18,
                          ),
                          child: HeroIcon(
                            HeroIcons.check,
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "Lives every 4 hours",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 25,
                          ),
                          child: Text(
                            "1",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: BASE_MARGIN * 3,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 18,
                          ),
                          child: Text(
                            "Full",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 1.1,
                            ),
                          ),
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
      ),
    );
  }
}