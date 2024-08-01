import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/classes/sku.dart';
import 'package:app/components/no_swipe_page_route.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/purchaseable_product.dart';
import 'package:app/models/user.dart';
import 'package:app/screens/shop/transaction.dart';
import 'package:app/utils/error.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:heroicons/heroicons.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:toastification/toastification.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _iap = InAppPurchase.instance;
  List<PurchasableProduct> products = [];
  bool _refillShieldsLoading = false;
  bool _buyOneShieldLoading = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Future<void> _buyOneStreakShield() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final url = Uri.parse("$API_URL/streaks/shields/one");
    logger.t("Fetching ${url.toString()}");
    final req = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 201) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to buy 1 shield: $message");
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text(message),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
    }
    logger.t("Bought 1 Shield");
    final userBloc = context.read<UserBloc>();
    userBloc.add(
      UserLoggedInEvent.setEmeraldsAndLives(
        userBloc.state,
        body['emeralds'],
        userBloc.state.lives,
      ),
    );
    setState(() {});
  }

  Future<void> _refillStreakShields() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final url = Uri.parse("$API_URL/streaks/shields/refill");
    logger.t("Fetching ${url.toString()}");
    final req = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 201) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to refill shields: $message");
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text(message),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
    }
    logger.t("Refilled Shields");
    final userBloc = context.read<UserBloc>();
    userBloc.add(
      UserLoggedInEvent.setEmeraldsAndLives(
        userBloc.state,
        body['emeralds'],
        userBloc.state.lives,
      ),
    );
    setState(() {});
  }

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
    if (!(await _iap.isAvailable())) return;

    final res = await _iap.queryProductDetails({
      ...InAppProductsPurchaseSku.emeralds.toSet(),
      ...InAppSubscriptionsPurchaseSku.tiers,
    });
    for (var element in res.notFoundIDs) {
      debugPrint('Purchase $element not found');
    }
    print(await _iap.countryCode());
    setState(() {
      products = res.productDetails.map((e) => PurchasableProduct(e)).toList();
    });
  }

  Future<int> _fetchStreakShields() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final url = Uri.parse("$API_URL/streaks/shields");
    logger.t("Fetching ${url.toString()}");
    final req = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to fetch shields: $message");
      throw message;
    }
    logger.t("Fetched Shields");
    return body['shields'] as int;
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
                SvgPicture.asset(
                  "assets/images/emerald.svg",
                  width: 25,
                  height: 25,
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
                'products',
                () async {
                  final res = await _iap.queryProductDetails({
                    ...InAppProductsPurchaseSku.emeralds.toSet(),
                  });
                  return res;
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
                  final products = data.productDetails;
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: BASE_MARGIN * 2,
                    children: products
                        .map(
                          (element) => _PurchaseWidget(
                            product: PurchasableProduct(
                              element,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(NoSwipePageRoute(
                                builder: (context) {
                                  return TransactionScreen(
                                    sku: element.id,
                                    type: ProductType.consumable,
                                  );
                                },
                              )).then(
                                (value) {
                                  setState(() {});
                                  initialize();
                                },
                              );
                            },
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(
                height: BASE_MARGIN * 4,
              ),
              Text(
                "Streak",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                  fontFamily: "CalSans",
                ),
              ),
              const SizedBox(
                height: BASE_MARGIN * 2,
              ),
              QueryBuilder(
                'shields',
                _fetchStreakShields,
                builder: (context, query) {
                  if (query.hasError) {
                    return Center(
                      child: Text(query.error.toString()),
                    );
                  }
                  final data = query.data;
                  return GestureDetector(
                    onTap: () {
                      if (data == null) return;
                      showModalBottomSheet(
                        context: context,
                        enableDrag: true,
                        showDragHandle: true,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, _setState) {
                              final bloc = context.read<UserBloc>();
                              final state = bloc.state;
                              return Padding(
                                padding: const EdgeInsets.all(BASE_MARGIN * 2),
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: BASE_MARGIN * 2,
                                    ),
                                    const SizedBox(
                                      height: BASE_MARGIN * 4,
                                    ),
                                    Text(
                                      data >= 5 ? "You have full shields" : "You have ${data} ${data == 1 ? "shield" : "shields"}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: BASE_MARGIN * 4,
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (data >= 5) return;
                                        _setState(() {
                                          _refillShieldsLoading = true;
                                        });
                                        await _refillStreakShields();
                                        await query.refresh();
                                        _setState(() {
                                          _refillShieldsLoading = false;
                                        });
                                        if (context.mounted) Navigator.pop(context);
                                      },
                                      style: ButtonStyle(
                                        backgroundColor: data < 5
                                            ? WidgetStateProperty.all(
                                                getSecondaryColor(context),
                                              )
                                            : WidgetStateProperty.all(
                                                Colors.grey.shade500,
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
                                      child: _refillShieldsLoading
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
                                                HeroIcon(
                                                  HeroIcons.shieldExclamation,
                                                  size: 30,
                                                  color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                ),
                                                const SizedBox(
                                                  width: BASE_MARGIN * 2,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    "Refill shields",
                                                    style: TextStyle(
                                                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                      fontWeight: FontWeight.w600,
                                                      color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                data > 5
                                                    ? ColorFiltered(
                                                        colorFilter: const ColorFilter.mode(
                                                          Colors.grey,
                                                          BlendMode.saturation,
                                                        ),
                                                        child: SvgPicture.asset(
                                                          "assets/images/emerald.svg",
                                                          width: 25,
                                                          height: 25,
                                                        ),
                                                      )
                                                    : SvgPicture.asset(
                                                        "assets/images/emerald.svg",
                                                        width: 25,
                                                        height: 25,
                                                      ),
                                                const SizedBox(
                                                  width: BASE_MARGIN * 2,
                                                ),
                                                Text(
                                                  data >= 5 ? "50" : ((5 - data!) * 10).toString(),
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
                                        if (data >= 5) return;
                                        _setState(() {
                                          _buyOneShieldLoading = true;
                                        });
                                        await _buyOneStreakShield();
                                        await query.refresh();
                                        _setState(() {
                                          _buyOneShieldLoading = false;
                                        });
                                        if (context.mounted) Navigator.pop(context);
                                      },
                                      style: ButtonStyle(
                                        backgroundColor: data < 5
                                            ? WidgetStateProperty.all(
                                                getSecondaryColor(context),
                                              )
                                            : WidgetStateProperty.all(
                                                Colors.grey.shade500,
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
                                      child: _buyOneShieldLoading
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
                                                HeroIcon(
                                                  HeroIcons.shieldExclamation,
                                                  size: 30,
                                                  color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                ),
                                                const SizedBox(
                                                  width: BASE_MARGIN * 2,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    "Refill 1 shield",
                                                    style: TextStyle(
                                                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                      fontWeight: FontWeight.w600,
                                                      color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                data > 5
                                                    ? ColorFiltered(
                                                        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                                                        child: SvgPicture.asset(
                                                          "assets/images/emerald.svg",
                                                          width: 25,
                                                          height: 25,
                                                        ),
                                                      )
                                                    : SvgPicture.asset(
                                                        "assets/images/emerald.svg",
                                                        width: 25,
                                                        height: 25,
                                                      ),
                                                const SizedBox(
                                                  width: BASE_MARGIN * 2,
                                                ),
                                                Text(
                                                  "10",
                                                  style: TextStyle(
                                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize!,
                                                    fontWeight: FontWeight.w600,
                                                    color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: getSecondaryColor(context),
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
                          const HeroIcon(
                            HeroIcons.shieldExclamation,
                            size: 30,
                          ),
                          const SizedBox(
                            width: BASE_MARGIN * 4,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Streak Shields protect your streak by covering a missed day, so you can keep your progress intact. Use them wisely to stay on track!",
                                ),
                                const SizedBox(
                                  height: BASE_MARGIN * 2,
                                ),
                                if (query.isLoading)
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade400,
                                    child: Container(
                                      height: 20,
                                      width: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                if (data != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: data == 0 ? Colors.red.shade100 : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "$data/5 equipped",
                                      style: TextStyle(
                                        color: data == 0 ? Colors.red[800] : Colors.green[800],
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                refreshConfig: RefreshConfig.withDefaults(
                  context,
                  staleDuration: Duration(
                    seconds: 0,
                  ),
                  refreshOnQueryFnChange: true,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseWidget extends StatelessWidget {
  final PurchasableProduct product;
  final VoidCallback onPressed;

  const _PurchaseWidget({
    required this.product,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    var title = product.title;
    if (product.status == ProductStatus.purchased) {
      title += ' (purchased)';
    }
    return InkWell(
      onTap: onPressed,
      child: ListTile(
        title: Text(
          title,
        ),
        subtitle: Text(product.description),
        trailing: Text(
          _trailing(),
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.titleSmall!.fontSize! * 0.8,
          ),
        ),
      ),
    );
  }

  String _trailing() {
    return switch (product.status) {
      ProductStatus.purchasable => product.rawPrice > 1000 ? "${product.price}/mo" : product.price,
      ProductStatus.purchased => 'purchased',
      ProductStatus.pending => 'buying...'
    };
  }
}
