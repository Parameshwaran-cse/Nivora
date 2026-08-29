import 'package:connectivity_plus/connectivity_plus.dart';
void main() async {
  final res = await Connectivity().checkConnectivity();
  if (res.contains(ConnectivityResult.none)) {}
}
