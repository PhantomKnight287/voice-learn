import 'dart:async';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/user.dart';
import 'package:app/screens/shop/transaction.dart';
import 'package:app/utils/print.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:heroicons/heroicons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shimmer/shimmer.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<Package> packages = [];

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    super.dispose();
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
    } on PlatformException catch (e) {
      // optional error handling
    }
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
    final PREMIUM_FEATURES = [
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
        bottom: BOTTOM(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        forceMaterialTransparency: false,
        title: const Text(
          "Shop",
        ),
        centerTitle: true,
        actions: [
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(
            10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Emeralds",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                  fontFamily: "CalSans",
                ),
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
                  return SizedBox(
                    height: 410,
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: BASE_MARGIN * 2,
                      crossAxisSpacing: BASE_MARGIN * 2,
                      childAspectRatio: 1,
                      physics: const NeverScrollableScrollPhysics(),
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
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
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
                                          element.storeProduct.title,
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
                    ),
                  );
                },
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
              // Container(
              //   padding: const EdgeInsets.all(8.0),
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(
              //       10,
              //     ),
              //     border: Border.all(
              //       color: getSecondaryColor(context),
              //       width: 2,
              //     ),
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.stretch,
              //     children: [
              //       Text(
              //         "Free",
              //         style: TextStyle(
              //           fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
              //           color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
              //           fontWeight: FontWeight.w700,
              //           letterSpacing: 0.5,
              //           fontFamily: "CalSans",
              //         ),
              //       ),
              //       Text(
              //         "\$0 / mo",
              //         style: TextStyle(
              //           fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 0.8,
              //           color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white,
              //           fontWeight: FontWeight.w600,
              //         ),
              //       ),
              //       const SizedBox(
              //         height: BASE_MARGIN * 4,
              //       ),
              //       ListView.separated(
              //         shrinkWrap: true,
              //         physics: const NeverScrollableScrollPhysics(),
              //         itemBuilder: (context, index) {
              //           return FREE_FEATURES[index];
              //         },
              //         separatorBuilder: (context, index) {
              //           return const SizedBox(
              //             height: BASE_MARGIN * 2,
              //           );
              //         },
              //         itemCount: FREE_FEATURES.length,
              //       ),
              //       const SizedBox(
              //         height: BASE_MARGIN * 2,
              //       ),
              //       const Text(
              //         "*Each voice message costs 1 emerald.",
              //         style: TextStyle(
              //           color: Colors.grey,
              //         ),
              //       ),
              //       const SizedBox(
              //         height: BASE_MARGIN * 4,
              //       ),
              //       ElevatedButton(
              //         onPressed: () {},
              //         style: ButtonStyle(
              //           alignment: Alignment.center,
              //           foregroundColor: WidgetStateProperty.all(AdaptiveTheme.of(context).mode == AdaptiveThemeMode.light ? Colors.black : Colors.white),
              //           padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry>(
              //             (Set<WidgetState> states) {
              //               return const EdgeInsets.all(15);
              //             },
              //           ),
              //           shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              //             RoundedRectangleBorder(
              //               borderRadius: BorderRadius.circular(10),
              //             ),
              //           ),
              //           backgroundColor: WidgetStateProperty.all(
              //             SECONDARY_BG_COLOR,
              //           ),
              //         ),
              //         child: Text(
              //           state.tier == Tiers.free ? "This is what you have" : "Already included in Premium",
              //           style: TextStyle(
              //             fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
              //             fontWeight: FontWeight.w600,
              //             fontFamily: "CalSans",
              //             color: Colors.black,
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              //
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
    );
  }
}
