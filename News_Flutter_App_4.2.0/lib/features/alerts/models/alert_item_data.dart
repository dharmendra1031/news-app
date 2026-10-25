/// One row of `get_market_alerts`. Priced rows (stock/forex/Crypto/commodity)
/// carry a price and trend; IPO rows carry only [ipoPrice] and have no trend.
class AlertItemData {
  final int id;
  final String alertType;
  final String name;
  final String symbol;
  final String exchange;
  final String? ipoPrice;
  final String? currentPrice;
  final String? currency;
  final double? percentChange;
  final String? direction;
  final DateTime? lastUpdatedAt;
  final int status;

  const AlertItemData({
    required this.id,
    required this.alertType,
    required this.name,
    required this.symbol,
    required this.exchange,
    this.ipoPrice,
    this.currentPrice,
    this.currency,
    this.percentChange,
    this.direction,
    this.lastUpdatedAt,
    this.status = 1,
  });

  bool get hasTrend => percentChange != null;

  bool get isUp {
    switch (direction?.toLowerCase()) {
      case 'up':
        return true;
      case 'down':
        return false;
      default:
        return (percentChange ?? 0) >= 0;
    }
  }

  /// True when the change rounds to 0.00%, whatever [direction] says. Flat rows
  /// carry no sign and no arrow, so they render neutral instead of up/down.
  bool get isFlat => hasTrend && _roundedChange == 0;

  double get _roundedChange => double.parse(percentChange!.toStringAsFixed(2));

  String get changeText {
    if (!hasTrend) return '';
    final double rounded = _roundedChange;
    final String value = rounded.abs().toStringAsFixed(2);
    if (rounded == 0) return '$value%';
    return rounded > 0 ? '+$value%' : '-$value%';
  }

  String get priceText {
    final String price = _formatPrice(currentPrice);
    if (price.isEmpty) return '';
    final String unit = currency?.trim() ?? '';
    return unit.isEmpty ? price : '$price $unit';
  }

  String get ipoPriceText => ipoPrice?.trim() ?? '';

  static const double _bigPriceThreshold = 100;
  static const int _bigPriceDecimals = 2;

  static String _formatPrice(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return '';
    final double? number = double.tryParse(text);
    if (number == null) return text;
    return _trimTrailingZeros(number.abs() >= _bigPriceThreshold
        ? number.toStringAsFixed(_bigPriceDecimals)
        : text);
  }

  static String _trimTrailingZeros(String text) {
    if (!text.contains('.')) return text;
    final String trimmed = text.replaceFirst(RegExp(r'0+$'), '');
    return trimmed.endsWith('.')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  factory AlertItemData.fromJson(Map<String, dynamic> json) {
    return AlertItemData(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      alertType: json['alert_type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      exchange: json['exchange']?.toString() ?? '',
      ipoPrice: json['ipo_price']?.toString(),
      currentPrice: json['current_price']?.toString(),
      currency: json['currency']?.toString(),
      percentChange: json['percent_change'] == null
          ? null
          : double.tryParse(json['percent_change'].toString()),
      direction: json['direction']?.toString(),
      lastUpdatedAt: DateTime.tryParse(json['last_updated_at']?.toString() ?? ''),
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status'].toString()) ?? 1,
    );
  }
}
