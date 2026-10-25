/// Bounds and default for the global reader font size, in logical pixels.
///
/// The value is what news/article body text is rendered at. It is picked by the
/// user (Profile > Text Size, or the "Text Size" button on News Details) and
/// persisted in Hive, so both entry points and every article screen share it.
class AppFontSize {
  const AppFontSize._();

  static const int min = 15;
  static const int max = 40;

  /// Kept at [min] so a fresh install looks exactly like it did before the
  /// setting existed.
  static const int defaultSize = 15;

  /// Number of steps on the slider (min..max split into equal divisions).
  static const int sliderDivisions = 10;
}
