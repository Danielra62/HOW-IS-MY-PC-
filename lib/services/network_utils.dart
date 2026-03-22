import 'package:network_info_plus/network_info_plus.dart';
import 'dart:io';

class NetworkUtils {
  static Future<String?> getLocalIP() async {
    final info = NetworkInfo();
    String? ip = await info.getWifiIP();
    
    // Si el plugin falla (común en Windows), intentamos via NetworkInterface
    if (ip == null) {
      try {
        for (var interface in await NetworkInterface.list()) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              return addr.address;
            }
          }
        }
      } catch (e) {
        return null;
      }
    }
    return ip;
  }
}
