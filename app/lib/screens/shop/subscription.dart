import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/models/user.dart';
import 'package:app/screens/shop/transaction.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final FREE_FEATURES = [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HeroIcon(
            HeroIcons.speakerWave,
            style: HeroIconStyle.outline,
            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
          ),
          const SizedBox(
            width: BASE_MARGIN * 2,
          ),
          Text(
            "6 voices",
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
    final PREMIUM_FEATURES = [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HeroIcon(
            HeroIcons.check,
            style: HeroIconStyle.outline,
            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
          ),
          const SizedBox(
            width: BASE_MARGIN * 2,
          ),
          Text(
            "All free plan features and...",
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
            HeroIcons.speakerWave,
            style: HeroIconStyle.outline,
            color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
          ),
          const SizedBox(
            width: BASE_MARGIN * 2,
          ),
          Text(
            "Unlock 40+ voices",
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

    final state = context.read<UserBloc>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Membership",
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        forceMaterialTransparency: false,
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
                      color: getSecondaryColor(context),
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
                          color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          fontFamily: "CalSans",
                        ),
                      ),
                      Text(
                        "\$0 / mo",
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
                            color: Colors.black,
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
                            "${data.price} / month",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 0.8,
                              color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
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
                        onPressed: () {
                          if (state.tier == Tiers.premium) return;
                          Navigator.of(context).push(
                            NoSwipePageRoute(
                              builder: (context) {
                                return TransactionScreen(
                                  sku: InAppSubscriptionsPurchaseSku.premium,
                                  type: ProductType.subscription,
                                );
                              },
                            ),
                          ).then(
                            (value) {
                              setState(() {});
                            },
                          );
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
                                    data.price,
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
                                  "10",
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
                                'ADs',
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
                                'Voice Note Duration',
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
      ),
    );
  }
}
