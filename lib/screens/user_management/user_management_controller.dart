import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:jewellery_order_management/repositories/user_management_repository.dart';
import 'package:jewellery_order_management/utils/app_colors.dart';
import 'package:jewellery_order_management/utils/app_text_style.dart';

class UserManagementController extends GetxController {
  final UserManagementRepository _repository = UserManagementRepository();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final users = <Map<String, dynamic>>[].obs;
  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  final selectedRole = 'ADMIN'.obs;

  /// Status filter for the user list.
  /// Values: 'ACTIVE' (default), 'INACTIVE', 'ALL'
  final selectedStatus = 'ACTIVE'.obs;

  String _statusOf(Map<String, dynamic> user) {
    return (user['status'] ?? 'ACTIVE').toString().toUpperCase();
  }

  List<Map<String, dynamic>> get filteredUsers {
    final query = searchQuery.value.trim().toLowerCase();
    final statusFilter = selectedStatus.value;

    return users.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      final username = (user['username'] ?? '').toString().toLowerCase();
      final phone = (user['phone'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? '').toString().toLowerCase();

      final matchesQuery =
          query.isEmpty ||
          name.contains(query) ||
          username.contains(query) ||
          phone.contains(query) ||
          role.contains(query);

      final matchesStatus =
          statusFilter == 'ALL' || _statusOf(user) == statusFilter;

      return matchesQuery && matchesStatus;
    }).toList();
  }

  int get adminCount => users
      .where((user) => (user['role'] ?? '').toString().toUpperCase() == 'ADMIN')
      .length;

  int get managerCount => users
      .where(
        (user) => (user['role'] ?? '').toString().toUpperCase() == 'MANAGER',
      )
      .length;

  int get activeCount =>
      users.where((user) => _statusOf(user) == 'ACTIVE').length;

  int get inactiveCount =>
      users.where((user) => _statusOf(user) != 'ACTIVE').length;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void showError(String message, {String title = 'Error'}) {
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }

  void showSuccess(String message) {
    Get.snackbar('Success', message, snackPosition: SnackPosition.BOTTOM);
  }

  // Supports common API response formats:
  // { data: [...] }, { users: [...] }, or [...]
  List<Map<String, dynamic>> _parseUsers(dynamic responseData) {
    dynamic result = responseData;

    if (result is Map) {
      if (result['users'] is List) {
        result = result['users'];
      } else if (result['data'] is List) {
        result = result['data'];
      } else if (result['data'] is Map) {
        final nested = result['data'] as Map;
        if (nested['users'] is List) {
          result = nested['users'];
        } else if (nested['data'] is List) {
          result = nested['data'];
        } else {
          result = [];
        }
      } else {
        result = [];
      }
    }

    if (result is! List) return [];

    return result
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _errorMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map) {
        final message = data['message'] ?? data['error'] ?? data['errors'];

        if (message != null) return message.toString();
      }

      if (error.response?.statusCode == 401) {
        return 'Session expired. Please login again.';
      }

      if (error.response?.statusCode == 403) {
        return 'You do not have permission to perform this action.';
      }

      if (error.response?.statusCode == 422) {
        return 'Please check the entered details.';
      }

      return error.message ?? 'Unable to connect to the server.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  String _responseMessage(dynamic data, String fallback) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return fallback;
  }

  // ============================================================
  // FETCH USERS
  // ============================================================

  Future<void> fetchUsers() async {
    isLoading.value = true;

    try {
      final response = await _repository.getUsers();
      users.assignAll(_parseUsers(response.data));
    } catch (e) {
      showError(_errorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  void onStatusFilterChanged(String status) {
    selectedStatus.value = status;
  }

  // ============================================================
  // CREATE USER
  // NOTE: Get.back() removed. The dialog closes itself.
  // ============================================================

  Future<bool> createUser({
    required String name,
    required String username,
    String? phone,
    required String password,
    required String role,
  }) async {
    if (name.trim().isEmpty || username.trim().isEmpty || password.isEmpty) {
      showError(
        'Name, username and password are required.',
        title: 'Validation',
      );
      return false;
    }

    isSaving.value = true;

    try {
      final response = await _repository.createUser(
        name: name.trim(),
        username: username.trim(),
        phone: phone,
        password: password,
        role: role,
      );

      showSuccess(
        _responseMessage(response.data, 'User created successfully.'),
      );

      // Not awaited, so the dialog can close immediately
      fetchUsers();
      return true;
    } catch (e) {
      showError(_errorMessage(e), title: 'Create Failed');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ============================================================
  // UPDATE USER
  // NOTE: Get.back() removed. The dialog closes itself.
  // ============================================================

  Future<bool> updateUser({
    required int id,
    required String name,
    required String username,
    String? phone,

    required String role,
  }) async {
    if (name.trim().isEmpty || username.trim().isEmpty) {
      showError('Name and username are required.', title: 'Validation');
      return false;
    }

    isSaving.value = true;

    try {
      final response = await _repository.updateUser(
        id: id,
        name: name.trim(),
        username: username.trim(),
        phone: phone,
        // password: password,
        role: role,
      );

      showSuccess(
        _responseMessage(response.data, 'User updated successfully.'),
      );

      fetchUsers();
      return true;
    } catch (e) {
      showError(_errorMessage(e), title: 'Update Failed');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // SUPER_ADMIN resets an ADMIN/MANAGER password; current password is not required.
  Future<bool> changeUserPassword({
    required int id,
    required String newPassword,
  }) async {
    if (newPassword.trim().isEmpty) {
      showError('Enter a new password.', title: 'Validation');
      return false;
    }

    if (newPassword.length < 8) {
      showError('Password must be at least 8 characters.', title: 'Validation');
      return false;
    }

    isSaving.value = true;
    try {
      final response = await _repository.updateUserPassword(
        id: id,
        newPassword: newPassword,
      );
      showSuccess(
        _responseMessage(response.data, 'Password reset successfully.'),
      );
      return true;
    } catch (e) {
      showError(_errorMessage(e), title: 'Password Reset Failed');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> openChangePasswordDialog({
    required Map<String, dynamic> user,
  }) async {
    final id = int.tryParse(user['id']?.toString() ?? '');
    if (id == null) {
      showError('Invalid user ID.');
      return;
    }

    await Get.dialog(
      _ChangePasswordDialog(
        controller: this,
        userId: id,
        userName: (user['name'] ?? user['username'] ?? 'User').toString(),
      ),
      barrierDismissible: false,
    );
  }

  // ============================================================
  // ACTIVATE / DEACTIVATE USER
  // ============================================================

  Future<void> toggleUserStatus(Map<String, dynamic> user) async {
    final id = int.tryParse(user['id'].toString());

    if (id == null) {
      showError('Invalid user ID.');
      return;
    }

    final currentStatus = (user['status'] ?? 'ACTIVE').toString().toUpperCase();

    final newStatus = currentStatus == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';

    final confirmed = await Get.dialog<bool>(
      Builder(
        builder: (dialogContext) => AlertDialog(
          title: Text(
            newStatus == 'ACTIVE' ? 'Activate User?' : 'Deactivate User?',
          ),
          content: Text(
            'Do you want to ${newStatus.toLowerCase()} '
            '${user['name'] ?? 'this user'}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: AppTextStyle.button.copyWith(color: AppColors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Confirm',
                style: AppTextStyle.button.copyWith(color: AppColors.black),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _repository.updateUserStatus(
        id: id,
        status: newStatus,
      );

      showSuccess(
        _responseMessage(response.data, 'User status changed to $newStatus.'),
      );

      await fetchUsers();
    } catch (e) {
      showError(_errorMessage(e), title: 'Status Update Failed');
    }
  }

  // ============================================================
  // CREATE / EDIT DIALOG
  // ============================================================

  Future<void> openUserForm({Map<String, dynamic>? user}) async {
    await Get.dialog(
      _UserFormDialog(controller: this, user: user),
      barrierDismissible: false,
    );
  }
}

// ==============================================================
// FORM DIALOG (StatefulWidget - owns & disposes its controllers)
// ==============================================================

class _UserFormDialog extends StatefulWidget {
  final UserManagementController controller;
  final Map<String, dynamic>? user;

  const _UserFormDialog({required this.controller, this.user});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;

  late String _role;
  bool _saving = false;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;

    _nameController = TextEditingController(
      text: user?['name']?.toString() ?? '',
    );
    _usernameController = TextEditingController(
      text: user?['username']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: user?['phone']?.toString() ?? '',
    );
    _passwordController = TextEditingController();

    _role = (user?['role'] ?? 'ADMIN').toString().toUpperCase();
    if (_role != 'ADMIN' && _role != 'MANAGER') _role = 'ADMIN';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    setState(() => _saving = true);

    bool success;

    if (_isEdit) {
      final id = int.tryParse(widget.user!['id'].toString());

      if (id == null) {
        setState(() => _saving = false);
        widget.controller.showError('Invalid user ID.');
        return;
      }

      success = await widget.controller.updateUser(
        id: id,
        name: name,
        username: username,
        phone: phone,
        role: _role,
      );
    } else {
      success = await widget.controller.createUser(
        name: name,
        username: username,
        phone: phone,
        password: password,
        role: _role,
      );
    }

    if (!mounted) return;

    if (success) {
      // Closes ONLY this dialog (not the snackbar / other routes)
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEdit ? 'Edit User' : 'Create User',
        style: AppTextStyle.bodyLarge.copyWith(
          color: AppColors.black,
          fontSize: 22,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter full name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username *',
                    prefixIcon: Icon(Icons.account_circle_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter username'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (Optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                    DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _role = value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: AppTextStyle.button.copyWith(color: AppColors.black),
          ),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _isEdit ? 'Update User' : 'Create User',
                  style: AppTextStyle.button.copyWith(color: AppColors.black),
                ),
        ),
      ],
    );
  }
}

// ==============================================================
// CHANGE PASSWORD DIALOG
// ==============================================================
class _ChangePasswordDialog extends StatefulWidget {
  final UserManagementController controller;
  final int userId;
  final String userName;

  const _ChangePasswordDialog({
    required this.controller,
    required this.userId,
    required this.userName,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _saving = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final success = await widget.controller.changeUserPassword(
      id: widget.userId,
      newPassword: _newPasswordController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      // Label color when not focused
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      // Label color when focused (floating label)
      floatingLabelStyle: const TextStyle(color: AppColors.black),
      prefixIcon: Icon(icon),
      prefixIconColor: AppColors.black,
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.black, width: 1.5),
      ),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          visible ? Icons.visibility_off : Icons.visibility,
          color: AppColors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('User: ${widget.userName}'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_showNewPassword,
                cursorColor: AppColors.black,
                decoration: _decoration(
                  label: 'New Password *',
                  icon: Icons.lock_outline,
                  visible: _showNewPassword,
                  onToggle: () =>
                      setState(() => _showNewPassword = !_showNewPassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Enter new password';
                  if (value.length < 8) return 'Use at least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                cursorColor: AppColors.black,
                decoration: _decoration(
                  label: 'Confirm New Password *',
                  icon: Icons.lock_reset,
                  visible: _showConfirmPassword,
                  onToggle: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Confirm new password';
                  if (value != _newPasswordController.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppColors.black),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.black,
                  ),
                )
              : const Text(
                  'Reset Password',
                  style: TextStyle(color: AppColors.black),
                ),
        ),
      ],
    );
  }
}
