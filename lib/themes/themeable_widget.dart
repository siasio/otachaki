import 'package:flutter/widgets.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';
import 'unified_theme_provider.dart';

abstract class ThemeableWidget {
  AppSkin get appSkin;
  LayoutType get layoutType;

  UnifiedThemeProvider get themeProvider =>
      UnifiedThemeProvider(skin: appSkin, layoutType: layoutType);
}

mixin ThemeableMixin {
  AppSkin get appSkin;
  LayoutType get layoutType;

  UnifiedThemeProvider get themeProvider =>
      UnifiedThemeProvider(skin: appSkin, layoutType: layoutType);
}

abstract class ThemeableStatelessWidget extends StatelessWidget
    implements ThemeableWidget {
  const ThemeableStatelessWidget({super.key});
}

abstract class ThemeableStatefulWidget extends StatefulWidget
    implements ThemeableWidget {
  const ThemeableStatefulWidget({super.key});
}