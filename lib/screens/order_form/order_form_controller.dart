import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_compress/video_compress.dart';
import '../../models/order_form_option.dart';
import '../../repositories/order_form_repository.dart';

class OrderFormController extends GetxController {
  OrderFormController(this.repository);
  final OrderFormRepository repository;
  final formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  // ---------------- AUDIO RECORDING ----------------
  final AudioRecorder _recorder = AudioRecorder();
  final isRecording = false.obs;
  final recordSeconds = 0.obs;
  Timer? _recordTimer;

  // ---------------- EDIT MODE ----------------
  bool isEditMode = false;
  int? orderId;
  Map<String, dynamic>? initialOrder;

  List<Map<String, dynamic>> get existingMedia {
    final media = initialOrder?['media'];
    if (media is! List) return [];
    return media
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  bool get hasExistingImage => existingMedia.any(
    (m) => '${m['mediaType'] ?? ''}'.toUpperCase() == 'IMAGE',
  );

  // Start as true so the empty form never flashes before data loads.
  final isLoading = true.obs;
  final loadFailed = false.obs;
  final isSubmitting = false.obs;
  final isCompressing = false.obs;
  final orderType = 'NEW'.obs;
  final branches = <OrderFormOption>[].obs;
  final metals = <OrderFormOption>[].obs;
  final categories = <OrderFormOption>[].obs;
  final repairTypes = <OrderFormOption>[].obs;
  final makers = <OrderFormOption>[].obs;
  final selectedRepairTypeIds = <int>[].obs;
  final selectedImages = <XFile>[].obs;
  final selectedVideo = Rxn<XFile>();
  final selectedAudio = Rxn<PlatformFile>();

  final selectedBranchId = RxnInt();
  final selectedMetalId = RxnInt();
  final selectedCategoryId = RxnInt();
  final selectedMakerId = RxnInt();
  final expectedDate = Rxn<DateTime>();
  final priority = 'NORMAL'.obs;

  final customerName = TextEditingController();
  final customerPhone = TextEditingController();
  final customerArea = TextEditingController();
  final length = TextEditingController();
  final lengthUnit = 'cm'.obs;
  final size = TextEditingController();
  final weight = TextEditingController();
  final purity = TextEditingController();
  final description = TextEditingController();
  final existingJewelleryDescription = TextEditingController();
  final problemDescription = TextEditingController();
  final receivedItemDescription = TextEditingController();
  final estimate = TextEditingController();
  final advance = TextEditingController();

@override
void onInit() {
  super.onInit();

  final args = Get.arguments;
  if (args is Map) {
    // Edit mode
    if (args['order'] is Map) {
      initialOrder = Map<String, dynamic>.from(args['order'] as Map);
      orderId = int.tryParse('${initialOrder!['id']}');
      isEditMode = orderId != null;
    }

    // Create mode: preselect order type from dashboard card
    if (!isEditMode && args['orderType'] != null) {
      final type = '${args['orderType']}'.toUpperCase();
      orderType.value = type == 'REPAIR' ? 'REPAIR' : 'NEW';
    }
  }

  loadOptions();
}

  Future<void> loadOptions() async {
    isLoading.value = true;
    loadFailed.value = false;
    try {
      final results = await Future.wait([
        repository.getBranches(),
        repository.getMetals(),
        repository.getCategories(),
        repository.getRepairTypes(),
        repository.getMakers(),
      ]);
      branches.assignAll(results[0]);
      metals.assignAll(results[1]);
      categories.assignAll(results[2]);
      repairTypes.assignAll(results[3]);
      makers.assignAll(results[4]);

      if (isEditMode) _prefillFromOrder();
    } catch (e) {
      loadFailed.value = true;
      Get.snackbar(
        'Unable to load form data',
        _errorText(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // PREFILL (EDIT MODE)
  // ============================================================

  String _s(dynamic v) => v == null ? '' : '$v';

  // "20000.00" -> "20000"
  String _num(dynamic v) {
    final text = _s(v).trim();
    final d = double.tryParse(text);
    if (d != null && d == d.roundToDouble()) return d.toInt().toString();
    return text;
  }

  int? _idOf(Map<String, dynamic> o, String idKey, String objKey) {
    final direct = int.tryParse(_s(o[idKey]));
    if (direct != null) return direct;
    final obj = o[objKey];
    if (obj is Map) return int.tryParse(_s(obj['id']));
    return null;
  }

  void _prefillFromOrder() {
    final o = initialOrder;
    if (o == null) return;

    orderType.value = _s(o['orderType']).toUpperCase() == 'REPAIR'
        ? 'REPAIR'
        : 'NEW';

    selectedBranchId.value = _idOf(o, 'branchId', 'branch');
    selectedMetalId.value = _idOf(o, 'metalId', 'metal');
    selectedCategoryId.value = _idOf(o, 'categoryId', 'category');
    selectedMakerId.value = _idOf(o, 'makerId', 'maker');

    customerName.text = _s(o['customerName']);
    customerPhone.text = _s(o['customerPhone']);
    customerArea.text = _s(o['customerArea']);

    length.text = _num(o['length']);
    final unit = _s(o['lengthUnit']).toLowerCase();
    lengthUnit.value = (unit == 'cm' || unit == 'inch') ? unit : 'cm';

    size.text = _s(o['size']);
    weight.text = _num(o['weight']);
    purity.text = _s(o['purity']).toUpperCase();
    description.text = _s(o['description']);

    existingJewelleryDescription.text = _s(o['existingJewelleryDescription']);
    problemDescription.text = _s(o['problemDescription']);
    receivedItemDescription.text = _s(o['receivedItemDescription']);

    estimate.text = _num(o['estimate']);
    advance.text = _num(o['advance']);

    final p = _s(o['priority']).toUpperCase();
    priority.value = ['LOW', 'NORMAL', 'URGENT'].contains(p) ? p : 'NORMAL';

    final dt = DateTime.tryParse(_s(o['expectedDeliveryDate']));
    expectedDate.value = dt?.toLocal();

    final rt = o['repairTypes'];
    final ids = <int>[];
    if (rt is List) {
      for (final item in rt) {
        if (item is Map) {
          final id =
              int.tryParse(_s(item['repairTypeId'])) ??
              (item['repairType'] is Map
                  ? int.tryParse(_s((item['repairType'] as Map)['id']))
                  : null);
          if (id != null) ids.add(id);
        }
      }
    }
    selectedRepairTypeIds.assignAll(ids);
  }

  // ============================================================
  // FORM ACTIONS
  // ============================================================

  void setOrderType(String value) {
    if (isEditMode) return; // order type cannot be changed while editing
    if (orderType.value == value) return;
    orderType.value = value;
    // Clear conditional values so hidden fields cannot leak into the other order type.
    if (value == 'NEW') {
      selectedRepairTypeIds.clear();
      existingJewelleryDescription.clear();
      problemDescription.clear();
      receivedItemDescription.clear();
    } else {
      selectedMetalId.value = null;
      selectedCategoryId.value = null;
      length.clear();
      lengthUnit.value = 'cm';
      size.clear();
      weight.clear();
      purity.clear();
      description.clear();
    }
  }

  // ---------------- IMAGES ----------------

  Future<void> pickImages() async {
    try {
      final files = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (files.isNotEmpty) selectedImages.addAll(files);
    } catch (e) {
      Get.snackbar('Images', 'Unable to select images: $e');
    }
  }

  Future<void> captureImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (file != null) selectedImages.add(file);
    } catch (e) {
      Get.snackbar('Camera', 'Unable to open camera: $e');
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  // ---------------- VIDEO ----------------

  // Compresses the video before upload. If compression fails for any
  // reason, the original file is used so the user is never blocked.
  Future<XFile> _compressVideo(XFile file) async {
    isCompressing.value = true;
    try {
      final originalMb = (await File(file.path).length()) / 1024 / 1024;

      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      final out = info?.file;
      if (out == null) return file;

      final compressedMb = (await out.length()) / 1024 / 1024;
      debugPrint(
        'VIDEO COMPRESSED => ${originalMb.toStringAsFixed(1)} MB '
        '-> ${compressedMb.toStringAsFixed(1)} MB',
      );

      // If compression somehow made it bigger, keep the original.
      if (compressedMb >= originalMb) return file;

      return XFile(out.path, name: file.name);
    } catch (e) {
      debugPrint('VIDEO COMPRESS FAILED: $e');
      return file;
    } finally {
      isCompressing.value = false;
    }
  }

  Future<void> pickVideo() async {
    if (isCompressing.value) return;
    try {
      final file = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (file != null) selectedVideo.value = await _compressVideo(file);
    } catch (e) {
      isCompressing.value = false;
      Get.snackbar('Video', 'Unable to select video: $e');
    }
  }

  Future<void> recordVideo() async {
    if (isCompressing.value) return;
    try {
      final file = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 1),
      );
      if (file != null) selectedVideo.value = await _compressVideo(file);
    } catch (e) {
      isCompressing.value = false;
      Get.snackbar('Video', 'Unable to record video: $e');
    }
  }

  void clearVideo() => selectedVideo.value = null;

  // ---------------- AUDIO (FILE) ----------------

  Future<void> pickAudio() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        selectedAudio.value = result.files.first;
      }
    } catch (e) {
      Get.snackbar('Audio', 'Unable to select audio: $e');
    }
  }

  void clearAudio() => selectedAudio.value = null;

  // ---------------- AUDIO (RECORD) ----------------

  Future<void> startAudioRecording() async {
    if (isRecording.value) return;
    try {
      if (!await _recorder.hasPermission()) {
        Get.snackbar(
          'Microphone',
          'Microphone permission is required to record audio.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/order_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      recordSeconds.value = 0;
      isRecording.value = true;
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => recordSeconds.value++,
      );
    } catch (e) {
      isRecording.value = false;
      Get.snackbar('Audio', 'Unable to start recording: $e');
    }
  }

  // Stop and keep the recording.
  Future<void> stopAudioRecording() async {
    if (!isRecording.value) return;
    _recordTimer?.cancel();
    try {
      final path = await _recorder.stop();
      isRecording.value = false;
      if (path != null && File(path).existsSync()) {
        final file = File(path);
        selectedAudio.value = PlatformFile(
          name: path.split('/').last,
          path: path,
          size: await file.length(),
        );
      }
    } catch (e) {
      isRecording.value = false;
      Get.snackbar('Audio', 'Unable to save recording: $e');
    }
  }

  // Stop and discard the recording.
  Future<void> cancelAudioRecording() async {
    if (!isRecording.value) return;
    _recordTimer?.cancel();
    try {
      final path = await _recorder.stop();
      if (path != null) {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      }
    } catch (_) {}
    isRecording.value = false;
  }

  // ---------------- DATE / REPAIR ----------------

Future<void> selectExpectedDate(BuildContext context) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final current = expectedDate.value ?? today;
  // In edit mode an old date must stay selectable.
  final first = current.isBefore(today) ? current : today;
  final selected = await showDatePicker(
    context: context,
    initialDate: current,
    firstDate: first,
    lastDate: DateTime(now.year + 10),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          // OK / Cancel buttons black
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.black),
          ),
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: Colors.black,      // selected date circle, header
            onPrimary: Colors.white,    // text on selected date
            onSurface: Colors.black,    // normal date text
          ),
        ),
        child: child!,
      );
    },
  );
  if (selected != null) expectedDate.value = selected;
}

  void toggleRepairType(int id, bool selected) {
    if (selected) {
      if (!selectedRepairTypeIds.contains(id)) selectedRepairTypeIds.add(id);
    } else {
      selectedRepairTypeIds.remove(id);
    }
  }

  String? requiredText(String? value, String label) =>
      (value == null || value.trim().isEmpty) ? '$label is required' : null;

  String? phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone Number is required';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  // ============================================================
  // SUBMIT (CREATE / UPDATE)
  // ============================================================

  Future<void> submitOrder() async {
    if (isSubmitting.value) return;
    if (isCompressing.value) {
      return _showValidation(
        'Video is still compressing. Please wait a moment.',
      );
    }
    if (isRecording.value) {
      return _showValidation('Please stop the audio recording first.');
    }
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (selectedBranchId.value == null) {
      return _showValidation('Please select a branch.');
    }
    if (expectedDate.value == null) {
      return _showValidation('Please select expected delivery date.');
    }
    // if (selectedImages.isEmpty && !(isEditMode && hasExistingImage)) {
    //   return _showValidation('Please select at least one image.');
    // }

    if (orderType.value == 'NEW') {
      if (selectedMetalId.value == null || selectedCategoryId.value == null) {
        return _showValidation('Please select metal and category.');
      }
    } else {
      if (selectedRepairTypeIds.isEmpty) {
        return _showValidation('Select at least one repair type.');
      }
      if (existingJewelleryDescription.text.trim().isEmpty ||
          problemDescription.text.trim().isEmpty ||
          receivedItemDescription.text.trim().isEmpty) {
        return _showValidation('Complete all mandatory repair details.');
      }
    }

    isSubmitting.value = true;
    try {
      final data = <String, dynamic>{
        'branchId': '${selectedBranchId.value}',
        'customerName': customerName.text.trim(),
        'customerPhone': customerPhone.text.trim(),
        'customerArea': customerArea.text.trim(),
        'orderType': orderType.value,
        'expectedDeliveryDate': _dateForApi(expectedDate.value!),
        'priority': priority.value,
        if (selectedMakerId.value != null)
          'makerId': '${selectedMakerId.value}',
        if (estimate.text.trim().isNotEmpty) 'estimate': estimate.text.trim(),
        if (advance.text.trim().isNotEmpty) 'advance': advance.text.trim(),
      };

      if (orderType.value == 'NEW') {
        data.addAll({
          'metalId': '${selectedMetalId.value}',
          'categoryId': '${selectedCategoryId.value}',
          if (length.text.trim().isNotEmpty) 'length': length.text.trim(),
          'lengthUnit': lengthUnit.value,
          if (size.text.trim().isNotEmpty) 'size': size.text.trim(),
          if (weight.text.trim().isNotEmpty) 'weight': weight.text.trim(),
          if (purity.text.trim().isNotEmpty) 'purity': purity.text.trim(),
          if (description.text.trim().isNotEmpty)
            'description': description.text.trim(),
        });
      } else {
        data.addAll({
          'repairTypeIds': selectedRepairTypeIds.join(','),
          'existingJewelleryDescription': existingJewelleryDescription.text
              .trim(),
          'problemDescription': problemDescription.text.trim(),
          'receivedItemDescription': receivedItemDescription.text.trim(),
          if (selectedMetalId.value != null)
            'metalId': '${selectedMetalId.value}',
          if (selectedCategoryId.value != null)
            'categoryId': '${selectedCategoryId.value}',
          if (length.text.trim().isNotEmpty) 'length': length.text.trim(),
          'lengthUnit': lengthUnit.value.toUpperCase(),
          if (size.text.trim().isNotEmpty) 'size': size.text.trim(),
          if (weight.text.trim().isNotEmpty) 'weight': weight.text.trim(),
          if (purity.text.trim().isNotEmpty) 'purity': purity.text.trim(),
        });
      }

      final formData = FormData();
      data.forEach(
        (key, value) => formData.fields.add(MapEntry(key, '$value')),
      );
      for (final image in selectedImages) {
        formData.files.add(
          MapEntry(
            'media',
            await MultipartFile.fromFile(image.path, filename: image.name),
          ),
        );
      }
      final video = selectedVideo.value;
      if (video != null) {
        formData.files.add(
          MapEntry(
            'media',
            await MultipartFile.fromFile(video.path, filename: video.name),
          ),
        );
      }
      final audio = selectedAudio.value;
      if (audio != null && audio.path != null) {
        formData.files.add(
          MapEntry(
            'media',
            await MultipartFile.fromFile(audio.path!, filename: audio.name),
          ),
        );
      }

      final response = isEditMode
          ? await repository.updateOrder(orderId!, formData)
          : await repository.createOrder(formData);

      final fallback = isEditMode
          ? 'Order updated successfully.'
          : 'Order created successfully.';
      final responseData = response is Response ? response.data : response;
      final message = responseData is Map
          ? (responseData['message']?.toString() ?? fallback)
          : fallback;

      // Upload finished: remove temporary compressed videos.
      VideoCompress.deleteAllCache();

      Get.snackbar('Success', message, snackPosition: SnackPosition.BOTTOM);

      if (isEditMode) {
        Get.back(result: true); // details screen will refresh
      } else {
        resetForm();
      }
    } catch (e) {
      Get.snackbar(
        isEditMode ? 'Order update failed' : 'Order creation failed',
        _errorText(e),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void resetForm() {
    customerName.clear();
    customerPhone.clear();
    customerArea.clear();
    length.clear();
    lengthUnit.value = 'cm';
    size.clear();
    weight.clear();
    purity.clear();
    description.clear();
    existingJewelleryDescription.clear();
    problemDescription.clear();
    receivedItemDescription.clear();
    estimate.clear();
    advance.clear();
    selectedBranchId.value = null;
    selectedMetalId.value = null;
    selectedCategoryId.value = null;
    selectedMakerId.value = null;
    expectedDate.value = null;
    priority.value = 'NORMAL';
    selectedRepairTypeIds.clear();
    selectedImages.clear();
    selectedVideo.value = null;
    selectedAudio.value = null;
    orderType.value = 'NEW';
    formKey.currentState?.reset();
  }

  String _dateForApi(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _showValidation(String message) => Get.snackbar(
    'Check required fields',
    message,
    snackPosition: SnackPosition.BOTTOM,
  );

  String _errorText(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) return '${data['message']}';
      if (data is Map && data['errors'] != null) return '${data['errors']}';
      return error.message ?? 'Please check server connection and try again.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void onClose() {
    _recordTimer?.cancel();
    _recorder.dispose();
    customerName.dispose();
    customerPhone.dispose();
    customerArea.dispose();
    length.dispose();
    size.dispose();
    weight.dispose();
    purity.dispose();
    description.dispose();
    existingJewelleryDescription.dispose();
    problemDescription.dispose();
    receivedItemDescription.dispose();
    estimate.dispose();
    advance.dispose();
    super.onClose();
  }
}