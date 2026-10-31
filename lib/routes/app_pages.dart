import 'package:get/get.dart';

import 'package:jewellery_order_management/routes/app_routes.dart';

import 'package:jewellery_order_management/screens/auth/login/login_binding.dart';
import 'package:jewellery_order_management/screens/auth/login/login_screen.dart';
import 'package:jewellery_order_management/screens/branch/branch_binding.dart';
import 'package:jewellery_order_management/screens/branch/branch_screen.dart';
import 'package:jewellery_order_management/screens/dashboard/dashboard_binding.dart';
import 'package:jewellery_order_management/screens/dashboard/dashboard_screen.dart';
import 'package:jewellery_order_management/screens/maker/maker_binding.dart';
import 'package:jewellery_order_management/screens/maker/maker_screen.dart';
import 'package:jewellery_order_management/screens/master/master_binding.dart';
import 'package:jewellery_order_management/screens/master/master_screen.dart';
import 'package:jewellery_order_management/screens/order_details/order_details_binding.dart';
import 'package:jewellery_order_management/screens/order_details/order_details_screen.dart';
import 'package:jewellery_order_management/screens/order_form/order_form_binding.dart';
import 'package:jewellery_order_management/screens/order_form/order_form_screen.dart';
import 'package:jewellery_order_management/screens/order_list/order_list_binding.dart';
import 'package:jewellery_order_management/screens/order_list/order_list_screen.dart';
import 'package:jewellery_order_management/screens/printer/printer_settings_screen.dart';
import 'package:jewellery_order_management/screens/user_management/user_management_binding.dart';
import 'package:jewellery_order_management/screens/user_management/user_management_screen.dart';
import 'package:jewellery_order_management/screens/reports/reports_binding.dart';
import 'package:jewellery_order_management/screens/reports/reports_screen.dart';
class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    // ============================================================
    // AUTH
    // ============================================================
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),

    // ============================================================
    // DASHBOARD
    // ============================================================
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
    ),
GetPage(
  name: AppRoutes.printerSettings,
  page: () => const PrinterSettingsScreen(),
),
    // Dashboard next step-la add pannuvom.

    // ============================================================
    // BRANCH
    // ============================================================
    GetPage(
      name: AppRoutes.branches,
      page: () => const BranchScreen(),
      binding: BranchBinding(),
    ),

    GetPage(
      name: AppRoutes.masterData,
      page: () => const MasterScreen(),
      binding: MasterBinding(),
    ),

    // ============================================================
    // MAKER
    // ============================================================
    GetPage(
      name: AppRoutes.makers,
      page: () => const MakerScreen(),
      binding: MakerBinding(),
    ),

    // ============================================================
    // ORDERS
    // ============================================================
    GetPage(
      name: AppRoutes.newOrder,
      page: () => const OrderFormScreen(),
      binding: OrderFormBinding(),
    ),

    GetPage(
      name: AppRoutes.orders,
      page: () => const OrderListScreen(),
      binding: OrderListBinding(),
    ),
    GetPage(
      name: AppRoutes.orderDetails,
      page: () => const OrderDetailsScreen(),
      binding: OrderDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.users,
      page: () => const UserManagementScreen(),
      binding: UserManagementBinding(),
    ),
    GetPage(
  name: AppRoutes.reports,
  page: () => const ReportsScreen(),
  binding: ReportsBinding(),
),
  ];
}
