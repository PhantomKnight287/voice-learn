// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const PRIMARY_COLOR = Color(0xffFFBF00);
const SECONDARY_TEXT_COLOR = Color(0xff808080);
const SECONDARY_BG_COLOR = Color(0xffebebeb);

const BASE_MARGIN = 4;

const API_URL = kDebugMode ? "http://192.168.1.11:5000/v1" : "https://api.voicelearn.tech/v1";
final LESSON_COMPLETION_AD_ID = Platform.isAndroid
    ? kDebugMode
        ? 'ca-app-pub-3940256099942544/1033173712'
        : 'ca-app-pub-8135231984104285/5542909945'
    : 'ca-app-pub-3940256099942544/4411468910';
