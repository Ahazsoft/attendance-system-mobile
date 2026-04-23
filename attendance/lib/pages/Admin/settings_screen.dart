import 'dart:convert';

import 'package:attendance/db/settings.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';

class OfficeSettingsScreen extends StatefulWidget {
  const OfficeSettingsScreen({super.key});

  @override
  State<OfficeSettingsScreen> createState() => _OfficeSettingsScreenState();
}

class _OfficeSettingsScreenState extends State<OfficeSettingsScreen> {
  bool _isFetching = true;
  bool _isSaving = false;
  double _radius = 150.0;
  TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final TextEditingController timeController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();

  final TextEditingController longitudeController = TextEditingController();

  final TextEditingController bssidController = TextEditingController();
  final TextEditingController secretController = TextEditingController();

  String lat = "0";
  String long = "0";

  @override
  void initState() {
    super.initState();
    _loadSettingsFromServer();
    // latitudeController.text = "24.45";
    // longitudeController.text = "24.54";

    // bssidController.text = "AA:BB:CC:DD:EE:FF";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // The context is fully available here, so this will safely set your default time
    if (timeController.text.isEmpty) {
      timeController.text = selectedTime.format(context);
    }
  }

  @override
  void dispose() {
    timeController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    bssidController.dispose();
    super.dispose();
  }

  // 1. Fetch Logic
  Future<void> _loadSettingsFromServer() async {
    try {
      final data = await SettingsService.getSettings();
      setState(() {
        _radius = (data['radius'] as num).toDouble();
        latitudeController.text = data['gpsLatitude'].toString();
        longitudeController.text = data['gpsLongitude'].toString();
        bssidController.text = data['bssid'] ?? "";
        secretController.text = data['SecretCode'] ?? "";

        print(
          "Fetched settings: latitude:, ${latitudeController.text},"
          " longitude: ${longitudeController.text}",
        );
        // Parse "HH:mm:ss" from backend to TimeOfDay
        String timeStr = data['lateThreshold']; // e.g. "09:30:00"
        final parts = timeStr.split(':');
        selectedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
        timeController.text = timeStr;

        _isFetching = false;
      });
    } catch (e) {
      setState(() => _isFetching = false);
      _showSnackBar("Error loading settings: $e", Colors.red);
    }
  }

  // 2. Save Logic
  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      // Format time to HH:mm:ss for backend
      final String formattedTime =
          "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00";

      // Save to DB
      await SettingsService.updateSettings(
        radius: _radius,
        lat: latitudeController.text,
        lng: longitudeController.text,
        bssid: bssidController.text,
        lateThreshold: formattedTime,
        secret: secretController.text,
      );

      _showSnackBar("Settings saved successfully!", Colors.green);

      // Show QR Modal after successful DB save
      final qrData = jsonEncode({
        "radius": _radius.toInt(),
        "time": formattedTime,
        "lat": latitudeController.text,
        "lng": longitudeController.text,
        "wifi": bssidController.text,
        "secret": secretController.text,
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => QRModal(data: qrData),
      );
    } catch (e) {
      _showSnackBar("Failed to save: $e", Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _initializeLocation() async {
    try {
      // 1. Wait for the position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print(
        "latitude: ${position.latitude} && longitude: ${position.longitude}",
      );

      // 2. Update the controllers inside setState so the UI refreshes
      setState(() {
        lat = position.latitude.toString();
        long = position.longitude.toString();
        latitudeController.text = position.latitude.toString();
        longitudeController.text = position.longitude.toString();
      });
    } catch (e) {
      // Handle errors (like user denying permission)
    }
  }

  Future<void> pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
        timeController.text = time.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configuration', style: AppTextStyles.label),
          const Text('Office Settings', style: AppTextStyles.heading1),
          const SizedBox(height: 24),

          // Geofence Map Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              border: Border.all(color: AppColors.primaryText.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: _radius / 2,
                      backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                      child: const Icon(
                        Icons.circle,
                        color: AppColors.primaryGreen,
                        size: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Geofence Radius',
                      style: AppTextStyles.bodyRegular,
                    ),
                    Text(
                      '${_radius.toInt()}m',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _radius,
                  min: 50,
                  max: 250,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (val) => setState(() => _radius = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Text("Lat: $lat \nLon: $long"),
          _buildGPS(),

          const SizedBox(height: 20),
          _buildBSSID(),

          const SizedBox(height: 20),
          _buildLateTreshord(),

          const SizedBox(height: 32),
          _buildSecret(),
          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                _handleSave();
                // final qrData = {
                //   "radius": _radius,
                //   "time": timeController.text,
                //   "lat": latitudeController.text,
                //   "lng": longitudeController.text,
                //   "wifi": bssidController.text,
                // }.toString();

                // showDialog(
                //   context: context,
                //   builder: (_) => QRModal(data: qrData),
                // );
              },
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: const Text(
                'Save Settings',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGPS() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: Border.all(color: AppColors.primaryText.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    PhosphorIconsBold.globeSimple,
                    size: 18,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Text("GPS Coordinates", style: AppTextStyles.bodyBold),
                ],
              ),
              Tooltip(
                message: "Set your current location as the office location",
                child: IconButton(
                  onPressed: _initializeLocation,
                  icon: const Icon(
                    PhosphorIconsBold.crosshairSimple,
                    size: 18,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // latitude
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Latitude", style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: latitudeController,
                      // initialValue: value,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.black.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // longitude
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Longitude", style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: longitudeController,
                      // initialValue: value,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.black.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBSSID() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: Border.all(color: AppColors.primaryText.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIconsBold.wifiHigh,
                size: 18,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text("Office Wi-Fi", style: AppTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("BSSID Address", style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextFormField(
                controller: bssidController,
                // initialValue: value,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.black.withOpacity(0.05),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecret() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: Border.all(color: AppColors.primaryText.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIconsBold.wifiHigh,
                size: 18,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text("SecretMessage", style: AppTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Secret Address", style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextFormField(
                controller: secretController,
                // initialValue: value,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.black.withOpacity(0.05),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLateTreshord() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: Border.all(color: AppColors.primaryText.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIconsBold.clock,
                size: 18,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text("Late Treshord", style: AppTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Arrivals after this time are marked late",
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: timeController,
                readOnly: true,
                onTap: pickTime,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintText: "Select time",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.black.withOpacity(0.05),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //to keep it away
}

class QRModal extends StatefulWidget {
  final String data;

  const QRModal({super.key, required this.data});

  @override
  State<QRModal> createState() => _QRModalState();
}

class _QRModalState extends State<QRModal> {
  final GlobalKey qrKey = GlobalKey();

  Future<void> shareQR() async {
    try {
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3);

      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/qr_code.png";

      File imgFile = File(path);
      await imgFile.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(path)], text: "Office Attendance QR");
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Attendance QR Code",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            RepaintBoundary(
              key: qrKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: widget.data,
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: shareQR,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text(
                      "Share",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AppColors.primaryText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
