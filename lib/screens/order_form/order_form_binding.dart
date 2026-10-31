import 'package:get/get.dart';
import 'order_form_controller.dart';
import '../../repositories/order_form_repository.dart';

class OrderFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderFormRepository>(() => OrderFormRepository());
    Get.lazyPut<OrderFormController>(() => OrderFormController(Get.find<OrderFormRepository>()));
  }
}
