
import 'dart:typed_data';
import 'dart:typed_data' as ui;
import 'dart:ui' as ui;

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal_plus/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderPrintService {
  static const String _macKey = 'saved_printer_mac';
  static const String _nameKey = 'saved_printer_name';

  // Detect Tamil Unicode characters.
  static final RegExp _tamilRegex = RegExp(r'[\u0B80-\u0BFF]');

  static String _v(dynamic value) {
    if (value == null || '$value'.trim().isEmpty) {
      return '-';
    }
    return '$value';
  }

  static String _date(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) return '-';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static String _dateTime(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) return '-';

    final hour = (date.hour % 12 == 0 ? 12 : date.hour % 12)
        .toString()
        .padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${_date(value)} $hour:$minute $period';
  }

  static String _name(dynamic value, List<String> keys) {
    if (value is! Map) return '-';

    for (final key in keys) {
      final result = value[key];

      if (result != null && '$result'.trim().isNotEmpty) {
        return '$result';
      }
    }

    return '-';
  }

  static String _amount(dynamic value) {
    if (value == null || '$value'.trim().isEmpty) {
      return '-';
    }

    final number = double.tryParse('$value');
    if (number == null) return '$value';

    return 'Rs. ${number.toStringAsFixed(2)}';
  }

  static bool _containsTamil(String text) {
    return _tamilRegex.hasMatch(text);
  }

  // Convert Tamil text into a bitmap because many ESC/POS printers
  // do not directly support Tamil Unicode characters.
  static Future<List<int>> _renderTamilText(
    Generator generator,
    String text, {
    bool bold = false,
    PosAlign align = PosAlign.left,
  }) async {
    const double imageWidth = 560;
    const double horizontalPadding = 8;
    const double verticalPadding = 8;

    final painter = material.TextPainter(
      text: material.TextSpan(
        text: text,
        style: material.TextStyle(
          fontFamily: 'NotoSansTamil',
          fontSize: 22,
          fontWeight:
              bold ? material.FontWeight.bold : material.FontWeight.normal,
          color: const material.Color(0xFF000000),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    painter.layout(
      maxWidth: imageWidth - (horizontalPadding * 2),
    );

    final int imageHeight =
        (painter.height + verticalPadding * 2).ceil().clamp(1, 2000);

    final recorder = ui.PictureRecorder();

    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(
        0,
        0,
        imageWidth,
        imageHeight.toDouble(),
      ),
    );

    // White background helps the thermal printer render the text clearly.
    canvas.drawRect(
      ui.Rect.fromLTWH(
        0,
        0,
        imageWidth,
        imageHeight.toDouble(),
      ),
      ui.Paint()..color = const material.Color(0xFFFFFFFF),
    );

    painter.paint(
      canvas,
      const ui.Offset(horizontalPadding, verticalPadding),
    );

    final picture = recorder.endRecording();

    final ui.Image renderedImage = await picture.toImage(
      imageWidth.toInt(),
      imageHeight,
    );

    final ui.ByteData? byteData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    renderedImage.dispose();
    picture.dispose();

    if (byteData == null) {
      throw Exception('Unable to convert Tamil text to image.');
    }

    final Uint8List pngBytes = byteData.buffer.asUint8List();
    final img.Image? decodedImage = img.decodeImage(pngBytes);

    if (decodedImage == null) {
      throw Exception('Unable to decode Tamil receipt image.');
    }

    return generator.imageRaster(
      decodedImage,
      align: align,
    );
  }

  static Future<bool> _ensureConnected() async {
    try {
      var connected = await PrintBluetoothThermal.connectionStatus;

      if (connected) {
        debugPrint('ORDER PRINT: Printer already connected');
        return true;
      }

      if (!await Permission.bluetoothConnect.isGranted) {
        final result = await Permission.bluetoothConnect.request();

        if (!result.isGranted) {
          debugPrint(
            'ORDER PRINT: Bluetooth connect permission denied',
          );
          return false;
        }
      }

      if (!await Permission.bluetoothScan.isGranted) {
        final result = await Permission.bluetoothScan.request();

        if (!result.isGranted) {
          debugPrint(
            'ORDER PRINT: Bluetooth scan permission denied',
          );
          return false;
        }
      }

      final bluetoothEnabled =
          await PrintBluetoothThermal.bluetoothEnabled;

      if (!bluetoothEnabled) {
        debugPrint('ORDER PRINT: Bluetooth is disabled');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final mac = prefs.getString(_macKey);

      if (mac == null || mac.isEmpty) {
        debugPrint('ORDER PRINT: No saved printer MAC address');
        return false;
      }

      final paired = await PrintBluetoothThermal.pairedBluetooths;

      final exists = paired.any(
        (device) => device.macAdress == mac,
      );

      if (!exists) {
        debugPrint(
          'ORDER PRINT: Saved printer is not paired: $mac',
        );
        return false;
      }

      // Reconnect only if disconnected.
      final result = await PrintBluetoothThermal.connect(
        macPrinterAddress: mac,
      );

      connected = await PrintBluetoothThermal.connectionStatus;

      debugPrint('ORDER PRINT: Reconnect result = $result');
      debugPrint('ORDER PRINT: Connection status = $connected');

      return result && connected;
    } catch (e, stackTrace) {
      debugPrint('ORDER PRINTER CONNECTION ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static Future<void> printOrder(
    Map<String, dynamic> order,
  ) async {
    debugPrint('ORDER PRINT: Starting Bluetooth receipt');
    debugPrint('ORDER PRINT: Order data = $order');

    final ready = await _ensureConnected();

    if (!ready) {
      throw Exception(
        'MPT-III is not connected. Open Printer Settings and connect it.',
      );
    }

    final orderNo = _v(order['orderNumber']);
    final profile = await CapabilityProfile.load();

    // MPT-III 3-inch printer: 80mm paper.
    final generator = Generator(PaperSize.mm80, profile);
    final bytes = <int>[];

    void addText(
      String text, {
      bool bold = false,
      int size = 1,
      PosAlign align = PosAlign.left,
    }) {
      bytes.addAll(
        generator.text(
          text,
          styles: PosStyles(
            bold: bold,
            align: align,
            height:
                size == 2 ? PosTextSize.size2 : PosTextSize.size1,
            width: PosTextSize.size1,
          ),
        ),
      );
    }

    void addLine() {
      bytes.addAll(generator.hr(ch: '-'));
    }

    // Tamil text prints as a raster image; English stays as ESC/POS text.
    Future<void> addRow(String label, dynamic value) async {
      final text = '$label: ${_v(value)}';

      if (_containsTamil(text)) {
        bytes.addAll(
          await _renderTamilText(generator, text),
        );
        return;
      }

      const maxChars = 42;

      if (text.length <= maxChars) {
        addText(text);
        return;
      }

      var remaining = text;

      while (remaining.length > maxChars) {
        var splitAt = remaining.lastIndexOf(' ', maxChars);

        if (splitAt <= 0) {
          splitAt = maxChars;
        }

        addText(remaining.substring(0, splitAt));
        remaining = remaining.substring(splitAt).trimLeft();
      }

      if (remaining.isNotEmpty) {
        addText(remaining);
      }
    }

    try {
      // Header
      addText(
        'JEWELLERY ORDER',
        bold: true,
        size: 2,
        align: PosAlign.center,
      );

      addText(
        'ORDER RECEIPT',
        bold: true,
        align: PosAlign.center,
      );

      addLine();

      addText(
        orderNo,
        bold: true,
        size: 2,
        align: PosAlign.center,
      );

      addLine();

      // Order information
      addText('ORDER DETAILS', bold: true);

      // await addRow('Order Type', order['orderType']);
      // await addRow('Status', order['status']);
      // await addRow('Priority', order['priority']);

      await addRow(
        'Branch',
        _name(order['branch'], ['name', 'branchName']),
      );

      // await addRow(
      //   'Maker',
      //   _name(order['maker'], ['name', 'makerName']),
      // );

      await addRow(
        'Expected Delivery',
        _date(order['expectedDeliveryDate']),
      );

      await addRow(
        'Created On',
        _dateTime(order['createdAt']),
      );

      // await addRow(
      //   'Printed On',
      //   _dateTime(DateTime.now().toIso8601String()),
      // );

      addLine();

      // Customer information
      addText('CUSTOMER DETAILS', bold: true);

      await addRow('Name', order['customerName']);
      await addRow('Phone', order['customerPhone']);
      await addRow('Area', order['customerArea']);

      addLine();

      // Jewellery information
      addText('JEWELLERY DETAILS', bold: true);

      await addRow(
        'Metal',
        _name(order['metal'], ['name', 'metalName']),
      );

      await addRow(
        'Category',
        _name(order['category'], ['name', 'categoryName']),
      );

      await addRow('Purity', order['purity']);
      await addRow('Weight', order['weight']);
      await addRow('Length', order['length']);
      await addRow('Length Unit', order['lengthUnit']);
      await addRow('Size', order['size']);
      await addRow('Description', order['description']);

      addLine();

      // Existing jewellery / repair details
      if (_v(order['existingJewelleryDescription']) != '-') {
        addText('EXISTING JEWELLERY', bold: true);

        await addRow(
          'Details',
          order['existingJewelleryDescription'],
        );

        addLine();
      }

      if (_v(order['problemDescription']) != '-') {
        addText('PROBLEM DESCRIPTION', bold: true);

        await addRow(
          'Problem',
          order['problemDescription'],
        );

        addLine();
      }

      if (_v(order['receivedItemDescription']) != '-') {
        addText('RECEIVED ITEM', bold: true);

        await addRow(
          'Details',
          order['receivedItemDescription'],
        );

        addLine();
      }

      // Payment details
      addText('PAYMENT DETAILS', bold: true);

      await addRow('Advance', _amount(order['advance']));
      await addRow('Estimate', _amount(order['estimate']));

      addLine();

      addText(
        'Thank you!',
        bold: true,
        align: PosAlign.center,
      );

      addText(
        'Please keep this receipt for reference.',
        align: PosAlign.center,
      );

      bytes.addAll(generator.feed(4));

      debugPrint(
        'ORDER PRINT: Generated ${bytes.length} bytes for $orderNo',
      );

      if (bytes.isEmpty) {
        throw Exception('Generated receipt is empty.');
      }

      // Send receipt directly to the Bluetooth printer.
      final sent = await PrintBluetoothThermal.writeBytes(bytes);

      debugPrint('ORDER PRINT: writeBytes result = $sent');

      if (!sent) {
        throw Exception(
          'Printer rejected the receipt data. Check printer connection.',
        );
      }

      // Do not disconnect after printing.
      final stillConnected =
          await PrintBluetoothThermal.connectionStatus;

      debugPrint(
        'ORDER PRINT: Status after printing = $stillConnected',
      );

      debugPrint(
        'ORDER PRINT: Receipt data sent for $orderNo',
      );
    } catch (e, stackTrace) {
      debugPrint('ORDER PRINT ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
