// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

const PRIMARY_COLOR = Color(0xffFFBF00);
const SECONDARY_TEXT_COLOR = Color(0xff808080);
const SECONDARY_BG_COLOR = Color(0xffebebeb);

const BASE_MARGIN = 4;

const API_URL = kDebugMode ? "https://c641f6de3e0a-10502837830859101550.ngrok-free.app/v1" : "https://api.voicelearn.tech/v1";
final LESSON_COMPLETION_AD_ID = Platform.isAndroid
    ? kDebugMode
        ? 'ca-app-pub-3940256099942544/1033173712'
        : 'ca-app-pub-8135231984104285/5542909945'
    : 'ca-app-pub-3940256099942544/4411468910';

const PUSHER_API_KEY = "08bb02d9dc1575512369";

final LESSON_STATS_AD_ID = Platform.isAndroid
    ? kDebugMode
        ? "ca-app-pub-3940256099942544/9214589741"
        : "ca-app-pub-8135231984104285/3425228085"
    : "";

const PUSHER_CLUSTER = "ap2";

final BOTTOM = PreferredSize(
  preferredSize: const Size.fromHeight(4.0),
  child: Container(
    color: const Color(0xffebebeb),
    height: 2.0,
  ),
);

const BASE_GRAVATAR_URL = "https://gravatar.com/avatar";
