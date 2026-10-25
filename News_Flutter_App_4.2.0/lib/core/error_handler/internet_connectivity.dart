import 'package:connectivity_plus/connectivity_plus.dart';

class InternetConnectivity {
  static Future<bool> isNetworkAvailable() async {
    final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
    // Any active interface counts, not just mobile/wifi: the iOS simulator reports the Mac's
    // interface (ethernet on a wired Mac), and a device on a VPN reports vpn.
    return connectivityResult.any((result) => result != ConnectivityResult.none);
  }
}
