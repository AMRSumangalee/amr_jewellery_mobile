
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal_plus/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothPrinterService {
  static const String _savedMacKey = 'jewellery_printer_mac';
  static const String _savedNameKey = 'jewellery_printer_name';

  Future<bool> requestBluetoothPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.bluetoothConnect.request();

        if (!status.isGranted) {
          return false;
        }
      }

      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (e) {
      debugPrint('BLUETOOTH PERMISSION ERROR: $e');
      return false;
    }
  }

  Future<List<BluetoothInfo>> getPairedPrinters() async {
    final allowed = await requestBluetoothPermission();

    if (!allowed) {
      throw Exception(
        'Enable Bluetooth and grant Bluetooth permission.',
      );
    }

    return await PrintBluetoothThermal.pairedBluetooths;
  }

  Future<bool> connectPrinter(BluetoothInfo printer) async {
    final allowed = await requestBluetoothPermission();

    if (!allowed) {
      throw Exception('Bluetooth permission is required.');
    }

    final connected = await PrintBluetoothThermal.connect(
      macPrinterAddress: printer.macAdress,
    );

    if (connected) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_savedMacKey, printer.macAdress);
      await prefs.setString(_savedNameKey, printer.name);
    }

    return connected;
  }

  Future<bool> connectSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final mac = prefs.getString(_savedMacKey);

    if (mac == null || mac.isEmpty) {
      return false;
    }

    if (await PrintBluetoothThermal.connectionStatus) {
      return true;
    }

    final allowed = await requestBluetoothPermission();

    if (!allowed) {
      return false;
    }

    return await PrintBluetoothThermal.connect(
      macPrinterAddress: mac,
    );
  }

  Future<bool> get isConnected async {
    return await PrintBluetoothThermal.connectionStatus;
  }

  Future<String?> get savedPrinterName async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedNameKey);
  }

  Future<bool> printTestReceipt() async {
    if (!await PrintBluetoothThermal.connectionStatus) {
      throw Exception('Connect to the printer first.');
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    final List<int> bytes = [];

    bytes.addAll(generator.reset());

    bytes.addAll(
      generator.text(
        'JEWELLERY ORDER MANAGEMENT',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      ),
    );

    bytes.addAll(
      generator.text(
        'MPT-III PRINTER TEST',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
        ),
      ),
    );

    bytes.addAll(generator.hr());

    bytes.addAll(generator.text('Printer: MPT-III'));
    bytes.addAll(generator.text('Paper: 80 mm'));
    bytes.addAll(generator.text('Bluetooth: Connected'));
    bytes.addAll(generator.text('Test print successful.'));

    bytes.addAll(generator.hr());
    bytes.addAll(
      generator.text(
        'Thank you!',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );

    bytes.addAll(generator.feed(4));

    return await PrintBluetoothThermal.writeBytes(bytes);
  }

  Future<bool> printOrder(Map<String, dynamic> order) async {
    if (!await PrintBluetoothThermal.connectionStatus) {
      final connected = await connectSavedPrinter();

      if (!connected) {
        throw Exception('Connect the saved printer before printing.');
      }
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    final List<int> bytes = [];

    String value(dynamic data) {
      if (data == null || data.toString().trim().isEmpty) {
        return '-';
      }

      return data.toString();
    }

    String relationName(dynamic data) {
      if (data is Map) {
        return value(data['name'] ?? data['title']);
      }

      return '-';
    }

    bytes.addAll(generator.reset());

    bytes.addAll(
      generator.text(
        'JEWELLERY ORDER',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );

    bytes.addAll(generator.hr());

    bytes.addAll(
      generator.text(
        'Order No: ${value(order['orderNumber'] ?? order['id'])}',
        styles: const PosStyles(bold: true),
      ),
    );

    bytes.addAll(
      generator.text('Created: ${value(order['createdAt'])}'),
    );

    bytes.addAll(generator.hr());

    bytes.addAll(
      generator.text(
        'CUSTOMER DETAILS',
        styles: const PosStyles(bold: true),
      ),
    );

    bytes.addAll(
      generator.text('Name: ${value(order['customerName'])}'),
    );

    bytes.addAll(
      generator.text('Phone: ${value(order['customerPhone'])}'),
    );

    bytes.addAll(
      generator.text('Area: ${value(order['customerArea'])}'),
    );

    bytes.addAll(generator.hr());

    bytes.addAll(
      generator.text(
        'ORDER DETAILS',
        styles: const PosStyles(bold: true),
      ),
    );

    bytes.addAll(
      generator.text('Type: ${value(order['orderType'])}'),
    );

    bytes.addAll(
      generator.text('Status: ${value(order['status'])}'),
    );

    bytes.addAll(
      generator.text('Priority: ${value(order['priority'])}'),
    );

    bytes.addAll(
      generator.text('Branch: ${relationName(order['branch'])}'),
    );

    bytes.addAll(
      generator.text('Maker: ${relationName(order['maker'])}'),
    );

    bytes.addAll(
      generator.text('Metal: ${relationName(order['metal'])}'),
    );

    bytes.addAll(
      generator.text('Category: ${relationName(order['category'])}'),
    );

    final amount = order['totalAmount'] ??
        order['totalPrice'] ??
        order['amount'];

    if (amount != null) {
      bytes.addAll(
        generator.text('Amount: Rs. $amount'),
      );
    }

    final description = order['description'] ?? order['notes'];

    if (description != null &&
        description.toString().trim().isNotEmpty) {
      bytes.addAll(generator.hr());
      bytes.addAll(
        generator.text('Notes: ${description.toString()}'),
      );
    }

    bytes.addAll(generator.hr());

    bytes.addAll(
      generator.text(
        'Thank you!',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );

    bytes.addAll(generator.feed(4));

    return await PrintBluetoothThermal.writeBytes(bytes);
  }

  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
  }
}
