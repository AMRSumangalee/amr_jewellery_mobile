
import 'package:flutter/material.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal_plus/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() =>
      _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen>
    with WidgetsBindingObserver {
  static const String _macKey = 'saved_printer_mac';
  static const String _nameKey = 'saved_printer_name';

  List<BluetoothInfo> _printers = [];

  String? _selectedMac;
  String? _selectedName;

  bool _loading = false;
  bool _connected = false;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePrinter();
  }

  @override
  void dispose() {
    // Do not disconnect here.
    // Leaving this screen must not intentionally close the printer connection.
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh the displayed status when the app becomes active again.
    if (state == AppLifecycleState.resumed) {
      _checkConnectionStatus();
    }
  }

  void _showMessage(String title, String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _initializePrinter() async {
    final prefs = await SharedPreferences.getInstance();

    _selectedMac = prefs.getString(_macKey);
    _selectedName = prefs.getString(_nameKey);

    if (mounted) setState(() {});

    await _refreshPrinters(showMessage: false);
    await _checkConnectionStatus();
  }

  Future<bool> _requestPrinterPermissions() async {
    if (!await Permission.bluetoothConnect.isGranted) {
      final result = await Permission.bluetoothConnect.request();

      if (!result.isGranted) {
        _showMessage(
          'Permission Required',
          'Allow Nearby Devices permission in Android Settings.',
        );
        return false;
      }
    }

    if (!await Permission.bluetoothScan.isGranted) {
      final result = await Permission.bluetoothScan.request();

      if (!result.isGranted) {
        _showMessage(
          'Permission Required',
          'Allow Bluetooth Scan permission.',
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _saveSelectedPrinter(
    String mac,
    String name,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_macKey, mac);
    await prefs.setString(_nameKey, name);
  }

  Future<void> _checkConnectionStatus() async {
    try {
      final status =
          await PrintBluetoothThermal.connectionStatus;

      if (!mounted) return;

      setState(() {
        _connected = status;
      });

      debugPrint('PRINTER STATUS CHECK: $status');
    } catch (e) {
      debugPrint('PRINTER STATUS CHECK ERROR: $e');

      if (mounted) {
        setState(() => _connected = false);
      }
    }
  }

  Future<void> _refreshPrinters({
    bool showMessage = true,
  }) async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      final granted = await _requestPrinterPermissions();
      if (!granted) return;

      final bluetoothEnabled =
          await PrintBluetoothThermal.bluetoothEnabled;

      if (!bluetoothEnabled) {
        _showMessage(
          'Bluetooth Disabled',
          'Turn on Bluetooth and try again.',
        );
        return;
      }

      final devices =
          await PrintBluetoothThermal.pairedBluetooths;

      if (!mounted) return;

      String? nextMac = _selectedMac;
      String? nextName = _selectedName;

      // Keep the saved printer if it is still paired.
      final savedPrinter = devices.where(
        (device) => device.macAdress == _selectedMac,
      );

      if (savedPrinter.isNotEmpty) {
        nextMac = savedPrinter.first.macAdress;
        nextName = savedPrinter.first.name;
      } else {
        // Prefer MPT-III if no saved printer is available.
        final mpt = devices.where(
          (device) =>
              device.name.toUpperCase().contains('MPT-III'),
        );

        if (mpt.isNotEmpty) {
          nextMac = mpt.first.macAdress;
          nextName = mpt.first.name;
          await _saveSelectedPrinter(nextMac, nextName);
        } else {
          nextMac = null;
          nextName = null;
        }
      }

      setState(() {
        _printers = devices;
        _selectedMac = nextMac;
        _selectedName = nextName;
      });

      if (showMessage) {
        _showMessage(
          'Paired Devices',
          '${devices.length} device(s) found.',
        );
      }

      debugPrint('PAIRED DEVICES: ${devices.length}');

      for (final device in devices) {
        debugPrint(
          'PRINTER: ${device.name} | ${device.macAdress}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('REFRESH PRINTER ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage('Refresh Error', e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _selectPrinter(String? mac) async {
    if (mac == null) return;

    final matches = _printers.where(
      (device) => device.macAdress == mac,
    );

    if (matches.isEmpty) return;

    final device = matches.first;

    setState(() {
      _selectedMac = device.macAdress;
      _selectedName = device.name;
    });

    await _saveSelectedPrinter(
      device.macAdress,
      device.name,
    );

    await _checkConnectionStatus();
  }

  Future<bool> _ensureConnected() async {
    final mac = _selectedMac;

    if (mac == null || mac.isEmpty) {
      _showMessage(
        'Select Printer',
        'Choose a paired printer first.',
      );
      return false;
    }

    final granted = await _requestPrinterPermissions();
    if (!granted) return false;

    final bluetoothEnabled =
        await PrintBluetoothThermal.bluetoothEnabled;

    if (!bluetoothEnabled) {
      _showMessage(
        'Bluetooth Disabled',
        'Turn on Bluetooth first.',
      );
      return false;
    }

    // Do not disconnect an already active connection.
    final currentStatus =
        await PrintBluetoothThermal.connectionStatus;

    if (currentStatus) {
      if (mounted) setState(() => _connected = true);
      return true;
    }

    final devices =
        await PrintBluetoothThermal.pairedBluetooths;

    final paired = devices.where(
      (device) => device.macAdress == mac,
    );

    if (paired.isEmpty) {
      _showMessage(
        'Printer Not Found',
        'Pair the selected printer in Android Bluetooth settings.',
      );
      return false;
    }

    debugPrint('PRINTER CONNECT: $mac');

    final result = await PrintBluetoothThermal.connect(
      macPrinterAddress: mac,
    );

    final connected =
        await PrintBluetoothThermal.connectionStatus;

    debugPrint('PRINTER CONNECT RESULT: $result');
    debugPrint('PRINTER CONNECTED STATUS: $connected');

    if (mounted) {
      setState(() {
        _connected = result && connected;
      });
    }

    if (!result || !connected) {
      _showMessage(
        'Connection Failed',
        'Check printer power and Bluetooth permissions.',
      );
      return false;
    }

    return true;
  }

  Future<void> _connectPrinter() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      final connected = await _ensureConnected();

      if (connected) {
        _showMessage(
          'Connected',
          '${_selectedName ?? 'Printer'} is ready.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('PRINTER CONNECTION ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage('Connection Error', e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _printTestReceipt() async {
    if (_printing || _loading) return;

    setState(() => _printing = true);

    try {
      // Connect only when needed; do not disconnect first.
      final ready = await _ensureConnected();
      if (!ready) return;

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);

      final bytes = <int>[];

      bytes.addAll(
        generator.text(
          'JEWELLERY ORDER MANAGEMENT',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
          ),
        ),
      );

      bytes.addAll(
        generator.text(
          'PRINTER TEST RECEIPT',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        ),
      );

      bytes.addAll(generator.hr());
      bytes.addAll(generator.text('Printer: $_selectedName'));
      bytes.addAll(generator.text('MAC: $_selectedMac'));
      bytes.addAll(generator.text('Connection: Bluetooth'));
      bytes.addAll(generator.hr());

      bytes.addAll(
        generator.text(
          'Test print successful!',
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
          ),
        ),
      );

      bytes.addAll(generator.feed(3));
      bytes.addAll(generator.cut());

      final sent =
          await PrintBluetoothThermal.writeBytes(bytes);

      // Verify the connection after sending the receipt.
      final statusAfterPrint =
          await PrintBluetoothThermal.connectionStatus;

      debugPrint('TEST PRINT SENT: $sent');
      debugPrint('STATUS AFTER PRINT: $statusAfterPrint');

      if (mounted) {
        setState(() {
          _connected = statusAfterPrint;
        });
      }

      if (sent) {
        _showMessage(
          'Print Sent',
          statusAfterPrint
              ? 'Receipt sent. Printer connection is active.'
              : 'Receipt sent, but the printer connection closed.',
        );
      } else {
        _showMessage(
          'Print Failed',
          'Printer did not accept the print data.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('TEST PRINT ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage('Test Print Error', e.toString());

      await _checkConnectionStatus();
    } finally {
      if (mounted) {
        setState(() => _printing = false);
      }
    }
  }

  Future<void> _disconnectPrinter() async {
    try {
      await PrintBluetoothThermal.disconnect;

      if (!mounted) return;

      setState(() => _connected = false);

      _showMessage(
        'Disconnected',
        'Printer disconnected manually.',
      );
    } catch (e) {
      debugPrint('PRINTER DISCONNECT ERROR: $e');
      _showMessage('Disconnect Error', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedExists = _printers.any(
      (device) => device.macAdress == _selectedMac,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Settings'),
        actions: [
          IconButton(
            onPressed: _loading || _printing
                ? null
                : () => _refreshPrinters(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh paired devices',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.print, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bluetooth Thermal Printer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(
                        _connected
                            ? Icons.check_circle
                            : Icons.error_outline,
                        color: _connected
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _connected ? 'Connected' : 'Not connected',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _connected
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _loading || _printing
                            ? null
                            : _checkConnectionStatus,
                        icon: const Icon(Icons.sync),
                        tooltip: 'Check connection',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedExists ? _selectedMac : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select paired printer',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bluetooth),
                    ),
                    items: _printers.map((device) {
                      return DropdownMenuItem<String>(
                        value: device.macAdress,
                        child: Text(
                          '${device.name} (${device.macAdress})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _loading ||
                            _printing ||
                            _connected
                        ? null
                        : _selectPrinter,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_printers.length} paired device(s)',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading || _printing
                          ? null
                          : () => _refreshPrinters(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Paired Devices'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ||
                              _printing ||
                              _connected
                          ? null
                          : _connectPrinter,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.bluetooth_connected),
                      label: Text(
                        _loading
                            ? 'Please wait...'
                            : _connected
                                ? 'Printer Connected'
                                : 'Connect Printer',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _printing || _loading
                          ? null
                          : _printTestReceipt,
                      icon: _printing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.receipt_long),
                      label: Text(
                        _printing
                            ? 'Printing...'
                            : 'Print Test Receipt',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: !_connected || _printing || _loading
                          ? null
                          : _disconnectPrinter,
                      icon: const Icon(Icons.bluetooth_disabled),
                      label: const Text('Disconnect'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Troubleshooting',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Turn on the MPT-III printer.\n'
                    '2. Pair it in Android Bluetooth settings.\n'
                    '3. Allow Nearby Devices permission.\n'
                    '4. Close other apps using the printer.\n'
                    '5. Connect and print a test receipt.\n'
                    '6. Use Disconnect only when you want to end the connection.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
