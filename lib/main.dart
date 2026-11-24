
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const WifiScannerApp());
}

class WifiScannerApp extends StatelessWidget {
  const WifiScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const WifiHome(),
    );
  }
}

class WifiHome extends StatefulWidget {
  const WifiHome({super.key});

  @override
  State<WifiHome> createState() => _WifiHomeState();
}

class _WifiHomeState extends State<WifiHome> {
  List<WiFiAccessPoint> networks = [];
  bool loading = false;

  Future<void> scanWifi() async {
    setState(() => loading = true);

    try {
      final permission =
          await Permission.locationWhenInUse.request();

      if (!permission.isGranted) {
        throw Exception('Location permission is required');
      }

      final canScan =
          await WiFiScan.instance.canStartScan();

      if (canScan == CanStartScan.yes) {
        await WiFiScan.instance.startScan();
        await Future.delayed(const Duration(seconds: 2));
      }

      final results =
          await WiFiScan.instance.getScannedResults();

      if (!mounted) return;

      setState(() {
        networks = results;
      });
    } catch (e) {
      debugPrint('WiFi Error: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Scanner'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.wifi,
            size: 75,
            color: Colors.lightBlue,
          ),
          const Text(
            'الشبكات القريبة منك',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: loading ? null : scanWifi,
            icon: const Icon(Icons.search),
            label: Text(
              loading ? 'جاري البحث...' : 'ابحث عن الشبكات',
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: networks.isEmpty
                ? const Center(
                    child: Text('اضغط على زر البحث لاكتشاف الشبكات'),
                  )
                : ListView.builder(
                    itemCount: networks.length,
                    itemBuilder: (context, index) {
                      final wifi = networks[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.wifi,
                            color: Colors.lightBlue,
                            size: 35,
                          ),
                          title: Text(
                            wifi.ssid.isEmpty
                                ? 'شبكة مخفية'
                                : wifi.ssid,
                          ),
                          subtitle: Text(
                            'BSSID: ${wifi.bssid}\n'
                            'التردد: ${wifi.frequency} MHz\n'
                            'قوة الإشارة: ${wifi.level} dBm\n'
                            'الحماية: ${wifi.capabilities}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
