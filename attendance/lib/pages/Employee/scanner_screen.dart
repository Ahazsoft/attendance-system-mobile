import 'package:attendance/db/attendance_service.dart';
import 'package:attendance/db/settings.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';
// import 'package:http/http.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wifi_scan/wifi_scan.dart';

class ScannerScreen extends StatefulWidget {
  final int id;
  final Function(dynamic response)? onCheckInSuccess;
  const ScannerScreen({super.key, required this.id, this.onCheckInSuccess});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  // Traditional State Variables
  late WiFiAccessPoint wifi;
  bool isTorchOn = false;
  bool iswifiavailable = false;
  bool? isInsideGeofence; // null = loading, true = inside, false = outside
  double globalDistance = 0;
  bool isSubmitting = false;

  // Office Geofence Constants
  double centerLat = 8.986273300000001000000000000000;
  double centerLng = 38.788376000000000000000000000000;
  // double centerLat = 8.986202255702445;
  // double centerLng = 38.78797835605372;
  double allowedRadius = 150;
  String wifiBssid = "00:4c:e5:f6:61:49";

  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  @override
  void initState() {
    super.initState();
    // Initial geofence check
    _loadSettingsFromServer();
    _runLocationCheck();
    _runWifiCheck();
  }

  Future<void> _loadSettingsFromServer() async {
    try {
      final data = await SettingsService.getSettings();
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
      _showSnackBar("Error loading settings: $e", Colors.red);
    }
  }

  Future<void> _runLocationCheck() async {
    bool result = await checkLocation();
    if (mounted) {
      setState(() {
        isInsideGeofence = result;
      });
    }
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

  Future<void> _runWifiCheck() async {
    bool result = await checkOfficeWifi(wifiBssid);

    if (mounted) {
      setState(() {
        iswifiavailable = result;
      });
    }
  }

  Future<bool> checkOfficeWifi(String targetBssid) async {
    final canScan = await WiFiScan.instance.canStartScan();

    if (canScan != CanStartScan.yes) {
      return false;
    }

    await WiFiScan.instance.startScan();

    final results = await WiFiScan.instance.getScannedResults();

    for (final network in results) {
      if (network.bssid.toLowerCase() == targetBssid.toLowerCase()) {
        setState(() {
          wifi = network;
        });
        return true;
      }
    }

    return false;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  // Called when a barcode is detected
  Future<void> _handleBarcode(BarcodeCapture capture) async {
    // Only process if location are verified
    if (isInsideGeofence != true) {
      debugPrint('Scan blocked: Location/WiFi not verified');
      return;
    }

    // Prevent multiple simultaneous submissions
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

      if (mounted) {
        final isLate = response['isLate'] ?? false;
        final message = 'Checked in';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isLate ? Colors.orange : AppColors.primaryGreen,
            duration: const Duration(seconds: 5),
          ),
        );

        // Navigate back after successful check-in
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (widget.onCheckInSuccess != null) {
            widget.onCheckInSuccess!(response);
          }
        });
        // Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: ${e.toString()}'),
            backgroundColor: AppColors.redLate,
            duration: const Duration(seconds: 4),
          ),
        );
        // Resume scanning so user can retry
        cameraController.start();
      }
    } finally {
      isSubmitting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),

          // Scanner Box
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
                  // Overlay for "Outside Area" to dim the scanner
                  if (isInsideGeofence == false || isInsideGeofence == null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isInsideGeofence == false
                                  ? Icons.location_off
                                  : Icons.wifi_off,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "SCANNER DISABLED\nMove inside the office",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
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

          // Location Verification Badge
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
                      : 'Connect To The Office Network',
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
