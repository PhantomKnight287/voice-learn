import 'dart:async';
import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/purchaseable_product.dart';
import 'package:app/screens/shop/transaction.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

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

                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: BASE_MARGIN * 2,
                    children: data
                        .map((element) => ListTile(
                              title: Text(element.storeProduct.title),
                              subtitle: Text(element.storeProduct.description),
                              trailing: Text(element.storeProduct.priceString),
                              onTap: () async {
                                Navigator.of(context).push(NoSwipePageRoute(
                                  builder: (context) {
                                    return TransactionScreen(
                                      type: ProductType.consumable,
                                      storeProduct: element.storeProduct,
                                    );
                                  },
                                )).then(
                                  (value) {
                                    setState(() {});
                                  },
                                );
                              },
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(
                height: BASE_MARGIN * 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
