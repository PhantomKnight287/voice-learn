// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

const PRIMARY_COLOR = Color(0xffFFBF00);
const SECONDARY_TEXT_COLOR = Color(0xff808080);
const SECONDARY_BG_COLOR = Color(0xffebebeb);

Color getSecondaryColor(BuildContext context) {
  final theme = AdaptiveTheme.of(context).mode;
  if (theme == AdaptiveThemeMode.light) return SECONDARY_BG_COLOR;
  return const Color(0xff212124);
}

const BASE_MARGIN = 4;

const API_URL = kDebugMode ? "https://c641f6de3e0a-10502837830859101550.ngrok-free.app/v1" : "https://api.voicelearn.tech/v1";

const PUSHER_CLUSTER = "ap2";

PreferredSizeWidget BOTTOM(BuildContext context) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(4.0),
    child: Container(
      color: getSecondaryColor(context),
      height: 2.0,
    ),
  );
}

const BASE_GRAVATAR_URL = "https://gravatar.com/avatar";

const ONESIGNAL_APP_ID = "4a33b3b9-6eba-46da-9a0e-2078cfec3ecd";

const MONTHS = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];

const REVENUECAT_GOOGLE_KEY = "goog_TutKSPqsInuZGRaDNJtjZBixrBC";

const REVENUECAT_IOS_KEY = "appl_DAxocruPSMHkfurrYHWejdSUWYO";
