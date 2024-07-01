import 'dart:async';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/classes/sku.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/purchaseable_product.dart';
import 'package:app/screens/shop/transaction.dart';
import 'package:app/utils/print.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _iap = InAppPurchase.instance;
  List<PurchasableProduct> products = [];

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
    setState(() {
      products = res.productDetails.map((e) => PurchasableProduct(e)).toList();
    });
  }

  restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (error) {
      //you can handle error if restore purchase fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<UserBloc>().state;
    return Scaffold(
      appBar: AppBar(
        bottom: BOTTOM,
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
                Image.asset(
                  "assets/images/emerald.png",
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
                              Navigator.of(context).push(CupertinoPageRoute(
                                builder: (context) {
                                  return TransactionScreen(
                                    sku: element.id,
                                    type: ProductType.consumable,
                                  );
                                },
                              )).then(
                                (value) {
                                  setState(() {});
                                },
                              );
                            },
                          ),
                        )
                        .toList(),
                  );
                },
              ),
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
