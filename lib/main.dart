import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:jewellery_order_management/routes/app_pages.dart';
import 'package:jewellery_order_management/routes/app_routes.dart';
import 'package:jewellery_order_management/services/api_service.dart';
import 'package:jewellery_order_management/services/storage_service.dart';
import 'package:jewellery_order_management/utils/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService.init();

  ApiService.instance;

  final isLoggedIn = StorageService.isLoggedIn;

  runApp(
    JewelleryOrderManagementApp(
      isLoggedIn: isLoggedIn,
    ),
  );
}

class JewelleryOrderManagementApp extends StatelessWidget {
  final bool isLoggedIn;

  const JewelleryOrderManagementApp({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'AMK Jewellery',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),

        scaffoldBackgroundColor: AppColors.background,

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.black,
          elevation: 0,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            minimumSize: const Size(
              double.infinity,
              50,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
      ),

      initialRoute: isLoggedIn
          ? AppRoutes.dashboard
          : AppRoutes.login,

      getPages: AppPages.pages,
    );
  }
}