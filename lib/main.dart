import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'homePage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const TimerApp());
  });
}
