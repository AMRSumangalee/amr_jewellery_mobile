import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:jewellery_order_management/routes/app_routes.dart';
import 'package:jewellery_order_management/utils/app_colors.dart';
import 'package:jewellery_order_management/utils/app_text_style.dart';

import 'dashboard_controller.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _todayText() {
    final now = DateTime.now();
    return '${_days[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ==========================================================
      // APP BAR
      // (Notification icon removed: it had an empty onPressed.
      //  Add it back once the notifications screen is ready.)
      // ==========================================================
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: AppTextStyle.appBarTitle.copyWith(color: AppColors.black),
        ),
      ),

      drawer: _buildDrawer(context),

      // ==========================================================
      // BODY
      // ==========================================================
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.fetchDashboardSummary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 24),

              _buildSectionHeader('Quick Actions', Icons.flash_on_rounded),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'New Order',
                      subtitle: 'Create jewellery order',
                      onTap: () => Get.toNamed(
                        AppRoutes.newOrder,
                        arguments: {'orderType': 'NEW'},
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.build_circle_outlined,
                      title: 'Repair Order',
                      subtitle: 'Create repair order',
                      onTap: () => Get.toNamed(
                        AppRoutes.newOrder,
                        arguments: {'orderType': 'REPAIR'},
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSectionHeader('Order Overview', Icons.insights_rounded),
              const SizedBox(height: 12),
              Obx(() => _buildOverview(context)),

              const SizedBox(height: 26),

              _buildSectionHeader('Order Status', Icons.donut_large_rounded),
              const SizedBox(height: 12),
              Obx(() => _buildStatusCard()),

              const SizedBox(height: 26),

              // _buildSectionHeader('Quick Actions', Icons.flash_on_rounded),
              // const SizedBox(height: 12),

              // Row(
              //   children: [
              //     Expanded(
              //       child: _buildQuickActionCard(
              //         icon: Icons.add_circle_outline_rounded,
              //         title: 'New Order',
              //         subtitle: 'Create jewellery order',
              //         onTap: () => Get.toNamed(AppRoutes.newOrder),
              //       ),
              //     ),
              //     const SizedBox(width: 12),
              //     Expanded(
              //       child: _buildQuickActionCard(
              //         icon: Icons.build_circle_outlined,
              //         title: 'Repair Order',
              //         subtitle: 'Create repair order',
              //         onTap: () => Get.toNamed(AppRoutes.repairOrder),
              //       ),
              //     ),
              //   ],
              // ),

              // const SizedBox(height: 12),

              // _buildQuickAction(
              //   icon: Icons.receipt_long_rounded,
              //   title: 'View Orders',
              //   subtitle: 'Manage all jewellery orders',
              //   onTap: () => Get.toNamed(AppRoutes.orders),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ORDER OVERVIEW (loading / error / grid)
  // ============================================================

  Widget _buildOverview(BuildContext context) {
    if (controller.isDashboardLoading.value && controller.totalOrders == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Keep card height safe when user increases system font size.
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1.0).clamp(1.0, 1.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.dashboardError.value.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unable to load dashboard data.',
                    style: AppTextStyle.body.copyWith(color: AppColors.error),
                  ),
                ),
                IconButton(
                  tooltip: 'Retry',
                  onPressed: controller.fetchDashboardSummary,
                  icon: const Icon(Icons.refresh, color: AppColors.error),
                ),
              ],
            ),
          ),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 76 + (50 * textScale),
          ),
          children: [
            // ALL ORDERS
            _DashboardStatCard(
              title: 'Total Orders',
              value: '${controller.totalOrders}',
              icon: Icons.receipt_long_rounded,
              color: AppColors.accentGreen,
              onTap: () {
                Get.toNamed(AppRoutes.orders, arguments: {'status': ''});
              },
            ),

            // NEW ORDERS
            _DashboardStatCard(
              title: 'New Orders',
              value: '${controller.newOrders}',
              icon: Icons.add_circle_outline_rounded,
              color: AppColors.info,
              onTap: () {
                Get.toNamed(AppRoutes.orders, arguments: {'status': 'NEW'});
              },
            ),

            // IN PROGRESS ORDERS
            _DashboardStatCard(
              title: 'In Progress',
              value: '${controller.inProgressOrders}',
              icon: Icons.pending_actions_rounded,
              color: AppColors.warning,
              onTap: () {
                Get.toNamed(
                  AppRoutes.orders,
                  arguments: {'status': 'IN_PROGRESS'},
                );
              },
            ),

            // COMPLETED ORDERS
            _DashboardStatCard(
              title: 'Completed',
              value: '${controller.completedOrders}',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.success,
              onTap: () {
                Get.toNamed(
                  AppRoutes.orders,
                  arguments: {'status': 'COMPLETED'},
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTextStyle.h2.copyWith(color: AppColors.black),
          ),
        ),
        Icon(icon, size: 20, color: AppColors.grey),
      ],
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color.lerp(AppColors.primary, Colors.white, 0.35)!,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -40,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.black,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greeting()},',
                        style: AppTextStyle.bodySecondary.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.h2.copyWith(color: AppColors.black),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _welcomeChip(
                            Icons.verified_user_rounded,
                            controller.userRole,
                          ),
                          _welcomeChip(
                            Icons.calendar_today_rounded,
                            _todayText(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcomeChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.black),
          const SizedBox(width: 5),
          Text(text, style: AppTextStyle.chip.copyWith(color: AppColors.black)),
        ],
      ),
    );
  }

  // ============================================================
  // ORDER STATUS CARD
  // ============================================================

  Widget _buildStatusCard() {
    final total = controller.totalOrders;

    final rows = <_StatusItem>[
      _StatusItem(
        Icons.edit_note_rounded,
        'Draft',
        controller.draftOrders,
        AppColors.textSecondary,
      ),
      _StatusItem(
        Icons.fiber_new_rounded,
        'New',
        controller.newOrders,
        AppColors.primary,
      ),
      _StatusItem(
        Icons.assignment_rounded,
        'Assigned',
        controller.assignedOrders,
        AppColors.info,
      ),
      _StatusItem(
        Icons.engineering_rounded,
        'In Progress',
        controller.inProgressOrders,
        AppColors.warning,
      ),
      _StatusItem(
        Icons.check_circle_outline_rounded,
        'Completed',
        controller.completedOrders,
        AppColors.success,
      ),
      _StatusItem(
        Icons.verified_rounded,
        'Final Confirmed',
        controller.finalConfirmedOrders,
        AppColors.info,
      ),
      _StatusItem(
        Icons.local_shipping_rounded,
        'Delivered',
        controller.deliveredOrders,
        AppColors.accentGreen,
      ),
      // _StatusItem(
      //   Icons.cleaning_services_rounded,
      //   'Cleanup',
      //   controller.cleanupOrders,
      //   AppColors.warning,
      // ),
      _StatusItem(
        Icons.pause_circle_outline_rounded,
        'On Hold',
        controller.onHoldOrders,
        AppColors.textSecondary,
      ),
      _StatusItem(
        Icons.cancel_outlined,
        'Cancelled',
        controller.cancelledOrders,
        AppColors.error,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _buildStatusRow(item: rows[i], total: total),
            if (i != rows.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow({required _StatusItem item, required int total}) {
    final progress = total <= 0 ? 0.0 : (item.count / total).clamp(0.0, 1.0);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: item.color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subtitle,
                    ),
                  ),
                  Text(
                    '${item.count}',
                    style: AppTextStyle.priceSmall.copyWith(color: item.color),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: item.color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(item.color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // QUICK ACTION CARD (square, used in a Row)
  // ============================================================

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.black, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.title,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.bodySecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTION TILE (full width)
  // ============================================================

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.black, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyle.title),
                    const SizedBox(height: 3),
                    Text(subtitle, style: AppTextStyle.bodySecondary),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Widget _buildDrawer(BuildContext context) {
    final String role = controller.userRole.trim().toUpperCase();

    final bool isSuperAdmin = role == 'SUPER_ADMIN';
    final bool isAdmin = role == 'ADMIN';
    final bool isManager = role == 'MANAGER';

    final bool canManageMaster = isSuperAdmin || isAdmin;
    final bool canHandleOrders = isSuperAdmin || isAdmin || isManager;

    return Drawer(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 24,
              20,
              24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  Color.lerp(AppColors.primary, Colors.white, 0.35)!,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/amr_logo.png',
                    fit: BoxFit.contain,
                    // Prevents a crash/red screen if the asset is missing.
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.diamond_outlined,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  controller.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.h3.copyWith(color: AppColors.black),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    controller.userRole,
                    style: AppTextStyle.chip.copyWith(color: AppColors.black),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ROLE-BASED MENU
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  selected: true,
                  onTap: () => Get.back(),
                ),

                // SUPER ADMIN ONLY
                if (isSuperAdmin) ...[
                  _drawerItem(
                    icon: Icons.account_tree_rounded,
                    title: 'Branches',
                    onTap: () => _navigate(AppRoutes.branches),
                  ),
                  _drawerItem(
                    icon: Icons.people,
                    title: 'Users',
                    onTap: () => _navigate(AppRoutes.users),
                  ),
                ],

                // SUPER ADMIN + ADMIN
                if (canManageMaster) ...[
                  _drawerItem(
                    icon: Icons.category_outlined,
                    title: 'Master Data',
                    onTap: () => _navigate(AppRoutes.masterData),
                  ),
                  _drawerItem(
                    icon: Icons.engineering_outlined,
                    title: 'Makers',
                    onTap: () => _navigate(AppRoutes.makers),
                  ),
                ],

                // SUPER ADMIN + ADMIN + MANAGER
                if (canHandleOrders) ...[
                  _drawerItem(
                    icon: Icons.add_box_outlined,
                    title: 'Create Orders',
                    onTap: () => _navigate(AppRoutes.newOrder),
                  ),
                  _drawerItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Orders List',
                    onTap: () => _navigate(AppRoutes.orders),
                  ),
                ],

                 if (isSuperAdmin) ...[
                  _drawerItem(
                    icon: Icons.report,
                    title: 'Reports',
                    onTap: () => _navigate(AppRoutes.reports),
                  ),

                   if (canHandleOrders) ...[
                  _drawerItem(
                    icon: Icons.report,
                    title: 'Printer Settings',
                    onTap: () => _navigate(AppRoutes.printerSettings),
                  ),
                
                ],

                // NOTE: "Settings" item removed until the screen exists
                // (it was an empty tap target).
                 ]]
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // LOGOUT
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _drawerItem(
                icon: Icons.logout_rounded,
                title: 'Logout',
                color: AppColors.error,
                onTap: () {
                  Get.back();
                  _showLogoutDialog();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(String route) {
    Get.back(); // close drawer
    Get.toNamed(route);
  }

  // ============================================================
  // DRAWER ITEM
  // ============================================================

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    Color? color,
  }) {
    final itemColor = color ?? AppColors.black;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: selected
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.35))
            : null,
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: itemColor, size: 22),
        title: Text(
          title,
          style: AppTextStyle.subtitle.copyWith(
            color: itemColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: selected
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.black,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(
          Icons.logout_rounded,
          color: AppColors.error,
          size: 32,
        ),
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppTextStyle.button.copyWith(color: AppColors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Logout',
              style: AppTextStyle.button.copyWith(color: AppColors.black),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// STATUS ITEM MODEL (replaces untyped Map<String, dynamic>)
// ==================================================================

class _StatusItem {
  final IconData icon;
  final String title;
  final int count;
  final Color color;

  const _StatusItem(this.icon, this.title, this.count, this.color);
}

// ==================================================================
// DASHBOARD STAT CARD
// ==================================================================
class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -18,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: AppTextStyle.price.copyWith(color: color),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.label,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
