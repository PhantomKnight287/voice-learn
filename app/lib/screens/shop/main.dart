import 'dart:async';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    super.dispose();
    _purchaseSubscription?.cancel();
  }

  Future<void> initialize() async {
    if (!(await InAppPurchase.instance.isAvailable())) return;
    _purchaseSubscription = InAppPurchase.instance.purchaseStream.listen(
      (list) {
        handlePurchaseUpdates(list);
      },
      onError: print,
    );
  }

  handlePurchaseUpdates(purchaseDetailsList) async {
    for (int index = 0; index < purchaseDetailsList.length; index++) {
      var purchaseStatus = purchaseDetailsList[index].status;
      switch (purchaseDetailsList[index].status) {
        case PurchaseStatus.pending:
          print(' purchase is in pending ');
          continue;
        case PurchaseStatus.error:
          print(' purchase error ');
          break;
        case PurchaseStatus.canceled:
          print(' purchase cancel ');
          break;
        case PurchaseStatus.purchased:
          print(' purchased ');
          break;
        case PurchaseStatus.restored:
          print(' purchase restore ');
          break;
      }

      if (purchaseDetailsList[index].pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchaseDetailsList[index]).then((value) {
          if (purchaseStatus == PurchaseStatus.purchased) {
            print("bought");
          }
        });
      }
    }
  }

  Future<void> buyConsumableProduct(String productId) async {
    try {
      Set<String> productIds = {"emeralds_100"};

      final ProductDetailsResponse productDetails = await InAppPurchase.instance.queryProductDetails(productIds);
      if (productDetails == null) {
        // Product not found
        return;
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails.productDetails.first,
      );
      await InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
    } catch (e) {
      // Handle purchase error
      print('Failed to buy plan: $e');
    }
  }

  restorePurchases() async {
    try {
      await InAppPurchase.instance.restorePurchases();
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
        forceMaterialTransparency: true,
        title: Text(
          "Shop",
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
            fontWeight: FontWeight.w600,
          ),
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
          padding: EdgeInsets.all(
            10,
          ),
          child: Column(
            children: [
              Text(
                "Emeralds",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await buyConsumableProduct("emeralds_100");
                },
                child: Text(
                  "buy smth",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
