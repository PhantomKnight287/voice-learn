import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/models/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:app/utils/print.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

enum ProductType {
  subscription,
  consumable,
}

class TransactionScreen extends StatefulWidget {
  final String sku;
  final ProductType type;
  const TransactionScreen({
    super.key,
    required this.sku,
    required this.type,
  });

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  final _iap = InAppPurchase.instance;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    initialize();
    timer = Timer(
      const Duration(
        seconds: 3,
      ),
      () async {
        if (widget.type == ProductType.consumable) {
          await buyConsumableProduct(
            widget.sku,
          );
        } else {
          await buyNonConsumableProduct(widget.sku);
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _purchaseSubscription?.cancel();
    timer?.cancel();
  }

  Future<void> initialize() async {
    if (!(await _iap.isAvailable())) return;
    _purchaseSubscription = _iap.purchaseStream.listen(
      (list) {
        handlePurchaseUpdates(list);
      },
      onError: print,
    );
    await _iap.restorePurchases();
  }

  handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (int index = 0; index < purchaseDetailsList.length; index++) {
      var purchaseStatus = purchaseDetailsList[index].status;
      switch (purchaseStatus) {
        case PurchaseStatus.pending:
          continue;
        case PurchaseStatus.error:
          toastification.show(
            type: ToastificationType.error,
            style: ToastificationStyle.minimal,
            autoCloseDuration: const Duration(seconds: 5),
            title: const Text("An Error Occurred"),
            alignment: Alignment.topCenter,
            showProgressBar: false,
          );
          Navigator.of(context).pop(false);
          break;
        case PurchaseStatus.canceled:
          toastification.show(
            type: ToastificationType.error,
            style: ToastificationStyle.minimal,
            autoCloseDuration: const Duration(seconds: 5),
            title: const Text("An Error Occurred"),
            description: const Text("Purchase Cancelled"),
            alignment: Alignment.topCenter,
            showProgressBar: false,
          );
          Navigator.of(context).pop(false);
          break;
        case PurchaseStatus.purchased:
          break;
        case PurchaseStatus.restored:
          break;
      }

      if (purchaseDetailsList[index].pendingCompletePurchase) {
        final userBloc = context.read<UserBloc>();
        final userState = userBloc.state;
        final details = purchaseDetailsList[index];
        if (widget.type == ProductType.consumable) {
          if (details.productID.startsWith("emeralds_")) {
            userBloc.add(
              UserLoggedInEvent.setEmeraldsAndLives(
                userState,
                userState.emeralds + int.parse((details.productID.split("_")[1])),
                null,
              ),
            );
          }
        } else {
          userBloc.add(
            UserLoggedInEvent.setTier(
              userState,
              Tiers.premium,
            ),
          );
        }
        setState(() {});
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token");
        await http.post(
          Uri.parse(
            "$API_URL/transactions",
          ),
          headers: {"Authorization": "Bearer $token", "content-type": "application/json"},
          body: jsonEncode(
            {
              "sku": details.productID,
              "token": details.verificationData.serverVerificationData,
              "type": details.productID.startsWith("tier_") ? "subscription" : "one_time_product",
              "platform": Platform.isIOS ? "ios" : "android",
              "purchaseId": details.purchaseID,
            },
          ),
        );

        await _iap.completePurchase(purchaseDetailsList[index]).then((value) async {
          if (purchaseStatus == PurchaseStatus.purchased) {
            toastification.show(
              type: ToastificationType.success,
              style: ToastificationStyle.minimal,
              autoCloseDuration: const Duration(seconds: 5),
              title: const Text("Purchased"),
              description: Text(widget.type == ProductType.consumable ? "You have purchased ${purchaseDetailsList[index].productID.split("_")[1]} emeralds" : "You have upgraded to Premium"),
              alignment: Alignment.topCenter,
              showProgressBar: false,
            );
            Navigator.of(context).pop(true);
          }
        });
      }
    }
  }

  Future<void> buyConsumableProduct(String productId) async {
    try {
      Set<String> productIds = {productId};

      final ProductDetailsResponse productDetails = await _iap.queryProductDetails(productIds);
      if (productDetails == null) {
        // Product not found
        return;
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails.productDetails.first,
      );
      await _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
    } catch (e) {
      // Handle purchase error
      print('Failed to buy plan: $e');
    }
  }

  Future<void> buyNonConsumableProduct(String productId) async {
    try {
      Set<String> productIds = {productId};

      final ProductDetailsResponse productDetails = await _iap.queryProductDetails(productIds);
      if (productDetails == null) {
        // Product not found
        return;
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails.productDetails.first,
      );
      await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    } catch (e) {
      // Handle purchase error
      printError('Failed to buy plan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        forceMaterialTransparency: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(
              radius: 10,
            ),
            const SizedBox(
              height: BASE_MARGIN * 4,
            ),
            Text(
              "Please do not press back button or close the app. You will be redirected automatically to previous screen once your transaction is completed.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
              ),
            )
          ],
        ),
      ),
    );
  }
}
