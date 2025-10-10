import 'package:flutter/material.dart';
import '../themes/unified_theme_provider.dart';
import '../themes/element_registry.dart';
import '../models/app_skin.dart';
import '../models/layout_type.dart';

class WelcomeOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  final VoidCallback onDontShowAgain;
  final AppSkin appSkin;
  final LayoutType layoutType;

  const WelcomeOverlay({
    super.key,
    required this.onDismiss,
    required this.onDontShowAgain,
    required this.appSkin,
    required this.layoutType,
  });

  @override
  State<WelcomeOverlay> createState() => _WelcomeOverlayState();
}

class _WelcomeOverlayState extends State<WelcomeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _animationController.reverse();
    widget.onDismiss();
  }

  void _handleDontShowAgain() async {
    await _animationController.reverse();
    widget.onDontShowAgain();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = UnifiedThemeProvider(
      skin: widget.appSkin,
      layoutType: widget.layoutType,
    );

    final containerStyle = themeProvider.getElementStyle(UIElement.gameStatusBar);
    final textStyle = themeProvider.getElementStyle(UIElement.textBody);
    final buttonStyle = themeProvider.getElementStyle(UIElement.buttonResultDraw);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black.withOpacity(0.8 * _fadeAnimation.value),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: _getMaxWidth(context),
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: containerStyle.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: containerStyle.borderColor != null
                        ? Border.all(color: containerStyle.borderColor!, width: 2)
                        : null,
                    boxShadow: widget.appSkin != AppSkin.eink
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ]
                        : null,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(textStyle),
                        const SizedBox(height: 20),
                        _buildContent(textStyle),
                        const SizedBox(height: 24),
                        _buildButtons(buttonStyle, textStyle),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _getMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return 700; // Large desktop
    } else if (screenWidth > 800) {
      return 600; // Desktop/tablet
    } else if (screenWidth > 600) {
      return screenWidth * 0.85; // Small tablet
    } else if (screenWidth > 500) {
      return screenWidth * 0.9; // Large phones
    } else {
      return screenWidth * 0.95; // Small phones
    }
  }

  Widget _buildHeader(dynamic textStyle) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: widget.appSkin == AppSkin.eink
                ? Colors.black
                : Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.settings_suggest_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to Go Position Training!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textStyle.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Let\'s get you started with the basics',
                style: TextStyle(
                  fontSize: 16,
                  color: textStyle.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(dynamic textStyle) {
    final items = [
      _WelcomeItem(
        icon: Icons.psychology_outlined,
        title: 'Scoring System',
        description: 'Komi is set to 7.0 points. Both area and territory scoring work equally well for position evaluation.',
      ),
      _WelcomeItem(
        icon: Icons.dataset_outlined,
        title: 'Multiple Datasets',
        description: 'Choose from different datasets in the config screen. Each offers unique training challenges.',
      ),
      _WelcomeItem(
        icon: Icons.balance_outlined,
        title: 'Prisoner Count',
        description: 'When prisoners aren\'t shown on the board, assume both colors have captured an equal number.',
      ),
      _WelcomeItem(
        icon: Icons.tune_outlined,
        title: 'Customization',
        description: 'Visit the config screen (⚙️) to adjust timer settings, prediction modes, and visual preferences.',
      ),
      _WelcomeItem(
        icon: Icons.analytics_outlined,
        title: 'Track Progress',
        description: 'View your performance statistics and accuracy trends on the info screen (ℹ️).',
      ),
    ];

    return Column(
      children: items.map((item) => _buildContentItem(item, textStyle)).toList(),
    );
  }

  Widget _buildContentItem(_WelcomeItem item, dynamic textStyle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.appSkin == AppSkin.eink
                  ? Colors.grey[300]
                  : Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: widget.appSkin == AppSkin.eink
                  ? Colors.black
                  : Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textStyle.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: textStyle.color?.withOpacity(0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(dynamic buttonStyle, dynamic textStyle) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _handleDontShowAgain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.appSkin == AppSkin.eink
                      ? Colors.grey[300]
                      : Theme.of(context).primaryColor.withOpacity(0.1),
                  foregroundColor: widget.appSkin == AppSkin.eink
                      ? Colors.black
                      : Theme.of(context).primaryColor,
                  elevation: widget.appSkin == AppSkin.eink ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: widget.appSkin == AppSkin.eink
                        ? BorderSide(color: Colors.black, width: 1)
                        : BorderSide.none,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Don\'t show again',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.appSkin == AppSkin.eink
                      ? Colors.black
                      : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: widget.appSkin == AppSkin.eink ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Got it!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'You can access this information anytime through the config screen',
          style: TextStyle(
            fontSize: 12,
            color: textStyle.color?.withOpacity(0.6),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _WelcomeItem {
  final IconData icon;
  final String title;
  final String description;

  const _WelcomeItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}