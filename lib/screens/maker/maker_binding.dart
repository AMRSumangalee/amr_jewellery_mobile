import 'package:get/get.dart';
import 'maker_controller.dart';

class MakerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MakerController>(() => MakerController());
  }
}
