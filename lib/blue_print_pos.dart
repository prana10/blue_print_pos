import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:blue_print_pos/models/models.dart';
import 'package:blue_print_pos/receipt/receipt_section_text.dart';
import 'package:blue_print_pos/scanner/blue_scanner.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as blue_thermal;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';

class BluePrintPos {
  BluePrintPos._() {
    _bluetoothAndroid = blue_thermal.BlueThermalPrinter.instance;
  }

  static BluePrintPos get instance => BluePrintPos._();

  static const MethodChannel _channel = MethodChannel('blue_print_pos');

  /// This field is library to handle in Android Platform
  blue_thermal.BlueThermalPrinter? _bluetoothAndroid;

  /// Bluetooth Device model for iOS
  BluetoothDevice? _bluetoothDeviceIOS;

  /// State to get bluetooth is connected
  bool _isConnected = false;

  /// Getter value [_isConnected]
  bool get isConnected => _isConnected;

  /// Selected device after connecting
  BlueDevice? selectedDevice;

  /// return bluetooth device list, handler Android and iOS in [BlueScanner]
  Future<List<BlueDevice>> scan() async {
    return await BlueScanner.scan();
  }

  /// When connecting, reassign value [selectedDevice] from parameter [device]
  /// and if connection time more than [timeout]
  /// will return [ConnectionStatus.timeout]
  /// When connection success, will return [ConnectionStatus.connected]
  Future<ConnectionStatus> connect(
    BlueDevice device, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    selectedDevice = device;
    try {
      if (Platform.isAndroid) {
        final blue_thermal.BluetoothDevice bluetoothDeviceAndroid = blue_thermal.BluetoothDevice(selectedDevice?.name ?? '', selectedDevice?.address ?? '');
        await _bluetoothAndroid?.connect(bluetoothDeviceAndroid);
      } else if (Platform.isIOS) {
        _bluetoothDeviceIOS = BluetoothDevice.fromId(selectedDevice?.address ?? '');
        final int deviceConnectedIndex = FlutterBluePlus.connectedDevices.indexWhere((BluetoothDevice bluetoothDevice) {
          return bluetoothDevice.remoteId == _bluetoothDeviceIOS?.remoteId;
        });
        if (deviceConnectedIndex < 0) {
          await _bluetoothDeviceIOS?.connect();
        }
      }

      _isConnected = true;
      selectedDevice?.connected = true;
      return Future<ConnectionStatus>.value(ConnectionStatus.connected);
    } on Exception catch (error) {
      print('$runtimeType - Error $error');
      _isConnected = false;
      selectedDevice?.connected = false;
      return Future<ConnectionStatus>.value(ConnectionStatus.timeout);
    }
  }

  /// To stop communication between bluetooth device and application
  Future<ConnectionStatus> disconnect({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (Platform.isAndroid) {
      if (await _bluetoothAndroid?.isConnected ?? false) {
        await _bluetoothAndroid?.disconnect();
      }
      _isConnected = false;
    } else if (Platform.isIOS) {
      await _bluetoothDeviceIOS?.disconnect();
      _isConnected = false;
    }

    return ConnectionStatus.disconnect;
  }

  /// This method only for print text
  /// value and styling inside model [ReceiptSectionText].
  /// [feedCount] to create more space after printing process done
  /// [useCut] to cut printing process
  Future<void> printReceiptText(
    ReceiptSectionText receiptSectionText, {
    int feedCount = 0,
    bool useCut = false,
    bool useRaster = false,
    double duration = 0,
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final Uint8List bytes = await contentToImage(
      content: receiptSectionText.content,
      duration: duration,
    );
    final List<int> byteBuffer = await _getBytes(
      bytes,
      paperSize: paperSize,
      feedCount: feedCount,
      useCut: useCut,
      useRaster: useRaster,
    );
    await _printProcess(byteBuffer);
  }

  /// This method only for print image with parameter [bytes] in List<int>
  /// define [width] to custom width of image, default value is 120
  /// [feedCount] to create more space after printing process done
  /// [useCut] to cut printing process
  Future<void> printReceiptImage(
    List<int> bytes, {
    int width = 120,
    int feedCount = 0,
    bool useCut = false,
    bool useRaster = false,
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final List<int> byteBuffer = await _getBytes(
      bytes,
      customWidth: width,
      feedCount: feedCount,
      useCut: useCut,
      useRaster: useRaster,
      paperSize: paperSize,
    );
    await _printProcess(byteBuffer);
  }

  /// This method only for print QR, only pass value on parameter [data]
  /// define [size] to size of QR, default value is 120
  /// [feedCount] to create more space after printing process done
  /// [useCut] to cut printing process
  Future<void> printQR(
    String data, {
    int size = 120,
    int feedCount = 0,
    bool useCut = false,
  }) async {
    final List<int> byteBuffer = await _getQRImage(data, size.toDouble());
    await printReceiptImage(
      byteBuffer,
      width: size,
      feedCount: feedCount,
      useCut: useCut,
    );
  }

  /// Reusable method for print text, image or QR based value [byteBuffer]
  /// Handler Android or iOS will use method writeBytes from ByteBuffer
  /// But in iOS more complex handler using service and characteristic
  Future<void> _printProcess(List<int> byteBuffer) async {
    try {
      if (selectedDevice == null) {
        print('$runtimeType - Device not selected');
        return;
      }
      if (!_isConnected && selectedDevice != null) {
        await connect(selectedDevice!);
      }

      if (Platform.isAndroid) {
        _bluetoothAndroid?.writeBytes(Uint8List.fromList(byteBuffer));
      } else if (Platform.isIOS) {
        final List<BluetoothService> bluetoothServices = await _bluetoothDeviceIOS?.discoverServices() ?? <BluetoothService>[];
        final BluetoothService bluetoothService = bluetoothServices.firstWhere((BluetoothService service) => service.isPrimary);
        final BluetoothCharacteristic characteristic = bluetoothService.characteristics.firstWhere((BluetoothCharacteristic c) => c.properties.write);

        // Split data into chunks of 182 bytes
        const int chunkSize = 182;
        final int len = byteBuffer.length;
        for (int i = 0; i < len; i += chunkSize) {
          // Get the current chunk
          final List<int> chunk = byteBuffer.sublist(
            i,
            i + chunkSize > len ? len : i + chunkSize,
          );

          // Write chunk to the characteristic
          await characteristic.write(chunk, withoutResponse: true);
        }
      }
    } on Exception catch (error) {
      print('$runtimeType - Error $error');
    }
  }

  /// This method to convert byte from [data] into as image canvas.
  /// It will automatically set width and height based [paperSize].
  /// [customWidth] to print image with specific width
  /// [feedCount] to generate byte buffer as feed in receipt.
  /// [useCut] to cut of receipt layout as byte buffer.
  Future<List<int>> _getBytes(
    List<int> data, {
    PaperSize paperSize = PaperSize.mm58,
    int customWidth = 0,
    int feedCount = 0,
    bool useCut = false,
    bool useRaster = false,
  }) async {
    List<int> bytes = <int>[];
    final CapabilityProfile profile = await CapabilityProfile.load();
    final Generator generator = Generator(paperSize, profile);
    final img.Image _resize = img.copyResize(
      img.decodeImage(Uint8List.fromList(data))!,
      width: customWidth > 0 ? customWidth : paperSize.width,
    );
    if (useRaster) {
      bytes += generator.imageRaster(_resize);
    } else {
      bytes += generator.image(_resize);
    }
    if (feedCount > 0) {
      bytes += generator.feed(feedCount);
    }
    if (useCut) {
      bytes += generator.cut();
    }
    return bytes;
  }

  /// Handler to generate QR image from [text] and set the [size].
  /// Using painter and convert to [Image] object and return as [Uint8List]
  Future<Uint8List> _getQRImage(String text, double size) async {
    try {
      final Image image = await QrPainter(
        data: text,
        version: QrVersions.auto,
        gapless: false,
        dataModuleStyle: const QrDataModuleStyle(
          color: Color(0xFF000000),
        ),
      ).toImage(size);
      final ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      assert(byteData != null);
      return byteData!.buffer.asUint8List();
    } on Exception catch (exception) {
      print('$runtimeType - $exception');
      rethrow;
    }
  }

  static Future<Uint8List> contentToImage({
    required String content,
    double duration = 0,
  }) async {
    final Map<String, dynamic> arguments = <String, dynamic>{
      'content': content,
      'duration': Platform.isIOS ? 2000 : duration,
    };
    Uint8List results = Uint8List.fromList(<int>[]);
    try {
      results = await _channel.invokeMethod('contentToImage', arguments) ?? Uint8List.fromList(<int>[]);
    } on Exception catch (e) {
      log('[method:contentToImage]: $e');
      throw Exception('Error: $e');
    }
    return results;
  }
}
