/// Comprehensive registry of all UI elements that can be styled in the app.
/// This serves as the central catalog for all themeable components.
enum UIElement {
  // Board elements
  boardBackground,
  boardGridLines,
  boardStarPoints,
  stoneBlack,
  stoneWhite,
  stoneBlackBorder,
  stoneWhiteBorder,
  lastMoveMarker,
  moveNumber,
  focusOverlay,

  // Button elements
  buttonResultWhite,
  buttonResultBlack,
  buttonResultDraw,
  buttonNext,
  buttonPause,
  buttonNavigation,

  // Container elements
  gameStatusBar,
  timerBarContainer,
  timerBarProgress,
  progressIndicator,
  cardContainer,
  appBarContainer,
  feedbackOverlay,
  boardOverlay,

  // Text elements
  textHeading,
  textBody,
  textCaption,
  textButtonLabel,
  textStatusIndicator,
  textGameInfo,

  // Interactive feedback
  correctIndicator,
  incorrectIndicator,

  // Layout spacing (for dimension configuration)
  spacingSmall,
  spacingMedium,
  spacingLarge,
  spacingExtraLarge,

  // Borders and elevation
  borderThin,
  borderMedium,
  borderThick,
  elevationLow,
  elevationMedium,
  elevationHigh,
}

/// Categories for organizing UI elements
enum ElementCategory {
  board,
  button,
  container,
  text,
  interactive,
  layout,
  decoration,
}

/// Extension to get category for each UI element
extension UIElementCategory on UIElement {
  ElementCategory get category {
    switch (this) {
      case UIElement.boardBackground:
      case UIElement.boardGridLines:
      case UIElement.boardStarPoints:
      case UIElement.stoneBlack:
      case UIElement.stoneWhite:
      case UIElement.stoneBlackBorder:
      case UIElement.stoneWhiteBorder:
      case UIElement.lastMoveMarker:
      case UIElement.moveNumber:
      case UIElement.focusOverlay:
        return ElementCategory.board;

      case UIElement.buttonResultWhite:
      case UIElement.buttonResultBlack:
      case UIElement.buttonResultDraw:
      case UIElement.buttonNext:
      case UIElement.buttonPause:
      case UIElement.buttonNavigation:
        return ElementCategory.button;

      case UIElement.gameStatusBar:
      case UIElement.timerBarContainer:
      case UIElement.timerBarProgress:
      case UIElement.progressIndicator:
      case UIElement.cardContainer:
      case UIElement.appBarContainer:
      case UIElement.feedbackOverlay:
      case UIElement.boardOverlay:
        return ElementCategory.container;

      case UIElement.textHeading:
      case UIElement.textBody:
      case UIElement.textCaption:
      case UIElement.textButtonLabel:
      case UIElement.textStatusIndicator:
      case UIElement.textGameInfo:
        return ElementCategory.text;

      case UIElement.correctIndicator:
      case UIElement.incorrectIndicator:
        return ElementCategory.interactive;

      case UIElement.spacingSmall:
      case UIElement.spacingMedium:
      case UIElement.spacingLarge:
      case UIElement.spacingExtraLarge:
        return ElementCategory.layout;

      case UIElement.borderThin:
      case UIElement.borderMedium:
      case UIElement.borderThick:
      case UIElement.elevationLow:
      case UIElement.elevationMedium:
      case UIElement.elevationHigh:
        return ElementCategory.decoration;
    }
  }
}