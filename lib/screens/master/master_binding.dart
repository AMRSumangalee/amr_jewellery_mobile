import 'package:get/get.dart';
import 'master_controller.dart';

class MasterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MasterController>(() => MasterController());
  }
}
