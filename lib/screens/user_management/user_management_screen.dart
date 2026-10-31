import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jewellery_order_management/utils/app_colors.dart';
import 'user_management_controller.dart';

class UserManagementScreen extends GetView<UserManagementController> {
  const UserManagementScreen({super.key});

  static const Color primaryColor = Color(0xFF8B1C1C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_back, color: AppColors.black),
        ),
        title: const Text(
          'User Management',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        // foregroundColor: Colors.white,
        elevation: 0,
        // actions: [
        //   IconButton(
        //     tooltip: 'Refresh',
        //     onPressed: controller.fetchUsers,
        //     icon: const Icon(Icons.refresh),
        //   ),
        // ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        onPressed: () => controller.openUserForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add User'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSummary(),
            _buildSearch(),
            _buildStatusFilter(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.users.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  );
                }

                final users = controller.filteredUsers;

                if (users.isEmpty) {
                  return _buildEmptyState(
                    isSearching: controller.searchQuery.value.isNotEmpty,
                    status: controller.selectedStatus.value,
                  );
                }

                return RefreshIndicator(
                  color: primaryColor,
                  onRefresh: controller.fetchUsers,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildUserCard(users[index]);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Obx(
      () => Container(
        color: AppColors.primary,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
        child: Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Total Users',
                count: controller.users.length.toString(),
                icon: Icons.people_alt_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                title: 'Admins',
                count: controller.adminCount.toString(),
                icon: Icons.admin_panel_settings_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                title: 'Managers',
                count: controller.managerCount.toString(),
                icon: Icons.manage_accounts_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String count,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.black, size: 21),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search name, username, phone or role',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(
            () => controller.searchQuery.value.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      controller.searchController.clear();
                      controller.onSearchChanged('');
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryColor),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS FILTER (Active / Inactive / All)
  // ============================================================

  Widget _buildStatusFilter() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            _statusChoice(
              label: 'Active (${controller.activeCount})',
              value: 'ACTIVE',
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(width: 8),
            _statusChoice(
              label: 'Inactive (${controller.inactiveCount})',
              value: 'INACTIVE',
              icon: Icons.block,
            ),
            const SizedBox(width: 8),
            _statusChoice(
              label: 'All',
              value: 'ALL',
              icon: Icons.people_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChoice({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final selected = controller.selectedStatus.value == value;

    return ChoiceChip(
      showCheckmark: false,
      selected: selected,
      onSelected: (_) => controller.onStatusFilterChanged(value),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
      avatar: Icon(icon, size: 16, color: AppColors.black),
      label: Text(
        label,
        style: TextStyle(
          color: AppColors.black,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = (user['name'] ?? 'Unknown User').toString();
    final username = (user['username'] ?? '-').toString();
    final phone = (user['phone'] ?? '').toString();
    final role = (user['role'] ?? 'UNKNOWN').toString().toUpperCase();
    final status = (user['status'] ?? 'ACTIVE').toString().toUpperCase();

    final isActive = status == 'ACTIVE';
    final isAdmin = role == 'ADMIN';

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFECECEC)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: primaryColor.withValues(alpha: 0.10),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                phone,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'User actions',
                  onSelected: (value) {
                    if (value == 'edit') {
                      controller.openUserForm(user: user);
                    } else if (value == 'status') {
                      controller.toggleUserStatus(user);
                    } else if (value == 'change_password') {
                      controller.openChangePasswordDialog(user: user);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 19),
                          SizedBox(width: 10),
                          Text('Edit User'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'change_password',
                      child: Row(
                        children: [
                          Icon(Icons.lock_reset, size: 19),
                          SizedBox(width: 10),
                          Text('Change Password'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'status',
                      child: Row(
                        children: [
                          Icon(
                            isActive
                                ? Icons.person_off_outlined
                                : Icons.person_outline,
                            size: 19,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isActive ? 'Deactivate' : 'Activate',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _labelChip(
                  isAdmin ? 'ADMIN' : role,
                  isAdmin ? const Color(0xFFE8EAFD) : const Color(0xFFFFF0D8),
                  isAdmin ? const Color(0xFF3949AB) : const Color(0xFF9A6500),
                ),
                const SizedBox(width: 8),
                _labelChip(
                  isActive ? 'ACTIVE' : status,
                  isActive ? const Color(0xFFE2F6E9) : const Color(0xFFFFE8E8),
                  isActive ? const Color(0xFF18834A) : const Color(0xFFC62828),
                ),
                const Spacer(),
                Text(
                  'ID: ${user['id'] ?? '-'}',
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _labelChip(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isSearching,
    required String status,
  }) {
    final String title;
    final String message;

    if (isSearching) {
      title = 'No matching users';
      message = 'Try another name, username, phone or role.';
    } else if (status == 'ACTIVE') {
      title = 'No active users';
      message = 'Tap Add User to create an Admin or Manager.';
    } else if (status == 'INACTIVE') {
      title = 'No inactive users';
      message = 'All users are currently active.';
    } else {
      title = 'No users found';
      message = 'Tap Add User to create an Admin or Manager.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            if (!isSearching && status != 'INACTIVE') ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => controller.openUserForm(),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add User'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}