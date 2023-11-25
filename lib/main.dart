import 'dart:async';

import 'package:flutter/material.dart';
import 'package:letsgo/pages/my_map_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyMapPage(),
    );
  }
}

