import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class QRCodeGenerator extends StatefulWidget {
  const QRCodeGenerator({super.key});

  @override
  State<QRCodeGenerator> createState() => _QRCodeGeneratorState();
}

class _QRCodeGeneratorState extends State<QRCodeGenerator> {
  final TextEditingController _textController = TextEditingController();

  final GlobalKey qrKey = GlobalKey();

  String qrData = "";

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

      await Share.shareXFiles([XFile(path)], text: "Here is my QR code");
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    double myWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text("QR Code Generator")),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// INPUT
              Container(
                margin: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 15,
                ),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: "Enter text or URL",
                    border: InputBorder.none,
                  ),
                ),
              ),

              /// CREATE BUTTON
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    qrData = _textController.text;
                  });
                },
                child: const Text("Generate QR"),
              ),

              const SizedBox(height: 30),

              /// QR OUTPUT
              if (qrData.isNotEmpty)
                RepaintBoundary(
                  key: qrKey,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: myWidth * 0.6,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              /// SHARE BUTTON
              if (qrData.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: shareQR,
                  icon: const Icon(Icons.share),
                  label: const Text("Share QR"),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
