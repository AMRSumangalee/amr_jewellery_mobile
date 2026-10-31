
import 'package:get/get.dart';
import 'package:jewellery_order_management/screens/user_management/user_management_controller.dart';


class UserManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserManagementController>(
      () => UserManagementController(),
    );
  }
}
