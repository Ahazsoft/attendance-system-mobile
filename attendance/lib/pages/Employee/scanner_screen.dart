import 'package:attendance/service/attendance_service.dart';
import 'package:attendance/service/settings.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wifi_scan/wifi_scan.dart';

class ScannerScreen extends StatefulWidget {
  final String id;
  final Function(dynamic response)? onCheckInSuccess;
  const ScannerScreen({super.key, required this.id, this.onCheckInSuccess});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late WiFiAccessPoint wifi;
  bool isTorchOn = false;
  bool iswifiavailable = false;
  bool? isInsideGeofence;
  double globalDistance = 0;
  bool isSubmitting = false;

  double centerLat = 8.986273300000001;
  double centerLng = 38.788376000000000;
  double allowedRadius = 150;
  String wifiBssid = "00:4c:e5:f6:61:49";

  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  @override
  void initState() {
    super.initState();
    _loadSettingsFromServer();
    _runLocationCheck();
    _runWifiCheck();
  }

  // ---- Settings loading (with mounted guard) ----
  Future<void> _loadSettingsFromServer() async {
    try {
      final data = await SettingsService.getSettings();
      print("Scanner Page data  = $data");
      if (!mounted) return; // Guard after await
      setState(() {
        allowedRadius = (data['radius'] as num).toDouble();
        centerLat =
            double.tryParse(data['gpsLatitude'].toString()) ??
            8.986202255702445;
        centerLng =
            double.tryParse(data['gpsLongitude'].toString()) ??
            38.78797835605372;
        wifiBssid = data['bssid'] ?? "";
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Error loading settings: $e", Colors.red);
    }
  }

  // ---- Location check (both methods guarded) ----
  Future<void> _runLocationCheck() async {
    bool result = await checkLocation();
    if (!mounted) return;
    setState(() {
      isInsideGeofence = result;
    });
  }

  Future<bool> checkLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    if (!mounted) return false; // Guard after GPS fetch

    double distance = Geolocator.distanceBetween(
      centerLat,
      centerLng,
      position.latitude,
      position.longitude,
    );

    setState(() {
      globalDistance = distance;
    });

    return distance <= allowedRadius;
  }

  // ---- WiFi check (both methods guarded) ----
  Future<void> _runWifiCheck() async {
    bool result = await checkOfficeWifi(wifiBssid);
    if (!mounted) return;
    setState(() {
      iswifiavailable = result;
    });
  }

  Future<bool> checkOfficeWifi(String targetBssid) async {
    final canScan = await WiFiScan.instance.canStartScan();
    if (canScan != CanStartScan.yes) return false;

    await WiFiScan.instance.startScan();
    final results = await WiFiScan.instance.getScannedResults();

    for (final network in results) {
      if (network.bssid.toLowerCase() == targetBssid.toLowerCase()) {
        if (!mounted) return false; // Guard before setState
        setState(() {
          wifi = network;
        });
        return true;
      }
    }
    return false;
  }

  // ---- Snackbar helper ----
  void _showSnackBar(String message, Color color) {
    if (!mounted) return; // Safety guard
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // ---- Barcode handling unchanged (already uses mounted) ----
  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (isInsideGeofence != true) return;
    if (isSubmitting) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final secret = barcodes.first.rawValue;
    if (secret == null || secret.isEmpty) return;

    isSubmitting = true;
    await cameraController.stop();

    try {
      final response = await AttendanceService.checkIn(
        employeeId: widget.id,
        secret: secret,
        isBssid: iswifiavailable,
      );

      if (!mounted) return; // Additional guard
      final isLate = response['isLate'] ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checked in'),
          backgroundColor: isLate ? Colors.orange : AppColors.primaryGreen,
          duration: const Duration(seconds: 5),
        ),
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (widget.onCheckInSuccess != null) {
          widget.onCheckInSuccess!(response);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check-in failed: ${e.toString()}'),
          backgroundColor: AppColors.redLate,
          duration: const Duration(seconds: 4),
        ),
      );
      cameraController.start();
    } finally {
      if (mounted) isSubmitting = false; // Reset only if still alive
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  // ---------- UI (unchanged, kept for completeness) ----------
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.black12,
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: MobileScanner(
                      controller: cameraController,
                      onDetect: _handleBarcode,
                    ),
                  ),
                  _buildCorners(),
                  if (isInsideGeofence == false || isInsideGeofence == null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_off,
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "SCANNER DISABLED\nMove inside the office",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLocationBadge(),
          const SizedBox(height: 24),
          _buildWifiBadge(),
          const SizedBox(height: 24),
          Center(
            child: Text(
              "Approximately ${globalDistance.toStringAsFixed(0)}m away from office",
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scan QR Code', style: AppTextStyles.heading1),
            Text(
              'Position the code within the frame',
              style: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.greyText,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            _loadSettingsFromServer();
            _runLocationCheck();
            _runWifiCheck();
          },
          style: IconButton.styleFrom(backgroundColor: AppColors.cardWhite),
        ),
      ],
    );
  }

  Widget _buildLocationBadge() {
    if (isInsideGeofence == null) {
      return _loading('Scanning location', Icons.location_off);
    }

    final bool verified = isInsideGeofence!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: verified ? AppColors.lightGreen : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: verified
              ? AppColors.primaryGreen.withOpacity(0.3)
              : AppColors.redLate.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: verified
                  ? AppColors.primaryGreen.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              verified ? Icons.location_on : Icons.location_off,
              color: verified ? AppColors.primaryGreen : AppColors.redLate,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verified ? 'Location Verified' : 'Location Not Verified',
                  style: AppTextStyles.bodyBold,
                ),
                Text(
                  verified
                      ? 'Within Office Geofence (${allowedRadius.toInt()}m)'
                      : 'Please move closer to the office',
                  style: AppTextStyles.label,
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: verified ? AppColors.primaryGreen : AppColors.redLate,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiBadge() {
    if (isInsideGeofence == null) {
      return _loading('Scanning For Wifi', Icons.wifi_off);
    }

    final bool verified = iswifiavailable;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: verified ? AppColors.lightGreen : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: verified
              ? AppColors.primaryGreen.withOpacity(0.3)
              : AppColors.redLate.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: verified
                  ? AppColors.primaryGreen.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              verified ? Icons.wifi_outlined : Icons.wifi_off,
              color: verified ? AppColors.primaryGreen : AppColors.redLate,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verified ? 'Office WiFi Found' : 'Office WiFi Not Found',
                  style: AppTextStyles.bodyBold,
                ),
                Text(
                  verified
                      ? 'SSID: ${wifi.ssid}'
                      : 'The Office Network is not Found Nearby',
                  style: AppTextStyles.label,
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: verified ? AppColors.primaryGreen : AppColors.redLate,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorners() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_corner(true, true), _corner(true, false)],
          ),
          IconButton(
            onPressed: () {
              cameraController.toggleTorch();
              setState(() {
                isTorchOn = !isTorchOn;
              });
            },
            icon: Icon(
              isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white54,
              size: 48,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_corner(false, true), _corner(false, false)],
          ),
        ],
      ),
    );
  }

  Widget _corner(bool isTop, bool isLeft) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: AppColors.primaryGreen, width: 3)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: AppColors.primaryGreen, width: 3)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: AppColors.primaryGreen, width: 3)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: AppColors.primaryGreen, width: 3)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(16) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(16) : Radius.zero,
          bottomLeft: !isTop && isLeft
              ? const Radius.circular(16)
              : Radius.zero,
          bottomRight: !isTop && !isLeft
              ? const Radius.circular(16)
              : Radius.zero,
        ),
      ),
    );
  }

  Widget _loading(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.redLate.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.redLate),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loading ...', style: AppTextStyles.bodyBold),
                Text(label, style: AppTextStyles.label),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.redLate,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  //
}
