import 'dart:async';

import 'package:app/bloc/user/user_bloc.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/models/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:toastification/toastification.dart';

enum ProductType {
  subscription,
  consumable,
}

class TransactionScreen extends StatefulWidget {
  final ProductType type;
  final StoreProduct? storeProduct;
  final Package? package;
  const TransactionScreen({
    super.key,
    required this.type,
    this.storeProduct,
    this.package,
  }) : assert(
          type == ProductType.consumable && storeProduct != null || type == ProductType.subscription && package != null,
          'For consumable products, storeProduct must be provided. For subscriptions, package must be provided.',
        );

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer(
      const Duration(
        seconds: 1,
      ),
      () async {
        final userBloc = context.read<UserBloc>();
        final userState = userBloc.state;
        try {
          if (widget.type == ProductType.consumable) {
            await Purchases.purchaseStoreProduct(widget.storeProduct!);
          } else {
            await Purchases.purchasePackage(
              widget.package!,
            );
          }
          if (widget.storeProduct != null) {
            if (widget.storeProduct!.identifier.startsWith("emeralds_")) {
              userBloc.add(
                UserLoggedInEvent.setEmeraldsAndLives(
                  userState,
                  userState.emeralds + int.parse((widget.storeProduct!.identifier.split("_")[1])),
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
          toastification.show(
            type: ToastificationType.success,
            style: ToastificationStyle.minimal,
            autoCloseDuration: const Duration(seconds: 5),
            title: const Text("Purchased"),
            description: widget.storeProduct?.identifier.startsWith("emeralds_") == true
                ? Text("Thanks for buying! We added ${widget.storeProduct!.identifier.split('_')[1]} emeralds to your account.")
                : widget.storeProduct?.identifier == "tier_premium"
                    ? const Text("Thanks for subscribing! You are now a Premium Tier member.")
                    : const Text(""),
            alignment: Alignment.topCenter,
            showProgressBar: false,
          );
          logger.t("Bought: ${widget.storeProduct?.identifier ?? widget.package?.identifier}");
          if (mounted) Navigator.pop(context);
        } on PlatformException catch (e) {
          toastification.show(
            type: ToastificationType.error,
            style: ToastificationStyle.minimal,
            autoCloseDuration: const Duration(seconds: 5),
            title: const Text("An Error Occurred"),
            description: e.message != null ? Text(e.message!) : null,
            alignment: Alignment.topCenter,
            showProgressBar: false,
          );
          logger.e("Failed to purchase item: ${e.message}");
          if (mounted) {
            Navigator.pop(context);
          }
          return;
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
