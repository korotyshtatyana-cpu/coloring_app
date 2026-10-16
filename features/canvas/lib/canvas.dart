import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'src/screens/canvas_screen.dart';

export 'src/widgets/rewarded_ad_error_dialog.dart';

part 'canvas.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class CanvasRouter {}
