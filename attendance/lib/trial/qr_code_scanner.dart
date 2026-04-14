import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool isScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;

      if (code != null) {
        isScanned = true;

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("QR Code Detected"),
              content: Text(code),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      isScanned = false;
                    });
                  },
                  child: const Text("Scan Again"),
                ),
              ],
            );
          },
        );

        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Scanner"),
        actions: [
          /// Flashlight Button
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),

          /// Switch Camera Button
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),

      body: Stack(
        children: [
          /// Camera Scanner
          MobileScanner(controller: controller, onDetect: _onDetect),

          /// Scan Box Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
