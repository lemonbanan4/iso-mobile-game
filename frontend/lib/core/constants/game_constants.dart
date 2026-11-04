/// Core architectural constants for the Isometric 4X Strategy Game.
class GameConstants {
  GameConstants._();

  // Isometric Grid System (2:1 classic isometric ratio)
  static const double tileWidth = 128.0;
  static const double tileHeight = 64.0;
  static const double halfTileWidth = tileWidth / 2.0;
  static const double halfTileHeight = tileHeight / 2.0;

  // Default Map Dimensions (in tiles)
  static const int defaultMapWidth = 32;
  static const int defaultMapHeight = 32;

  // Camera Settings
  static const double minZoom = 0.4;
  static const double maxZoom = 2.5;
  static const double defaultZoom = 1.0;
  static const double zoomSensitivity = 0.002;
  static const double panDamping = 0.92; // Inertial friction

  // UI Theme Constants
  static const double glassBlurRadius = 14.0;
  static const double glassBorderRadius = 18.0;
  static const double clayBorderRadius = 20.0;
}
