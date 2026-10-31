import 'package:jewellery_order_management/models/branch_model.dart';
import 'package:jewellery_order_management/services/api_constants.dart';
import 'package:jewellery_order_management/services/api_service.dart';

class BranchRepository {
  final ApiService _apiService = ApiService.instance;

  // ============================================================
  // GET BRANCHES
  // ============================================================

  Future<List<BranchModel>> getBranches() async {
    final response = await _apiService.get(ApiConstants.branches);

    final responseData = Map<String, dynamic>.from(response.data);
    final data = responseData['data'];

    if (data is! List) {
      return [];
    }

    return data
        .map((item) => BranchModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // ============================================================
  // CREATE BRANCH
  // ============================================================

  Future<BranchModel> createBranch({
    required String name,
    required String code,
    String? address,
    String? phone,
    required bool status,
  }) async {
    final response = await _apiService.post(
      ApiConstants.branches,
      data: {
        'name': name,
        'code': code,
        'address': address,
        'phone': phone,
        'status': status,
      },
    );

    final responseData = Map<String, dynamic>.from(response.data);

    return BranchModel.fromJson(
      Map<String, dynamic>.from(responseData['data']),
    );
  }

  // ============================================================
  // UPDATE BRANCH
  // ============================================================

  Future<BranchModel> updateBranch({
    required int id,
    required String name,
    required String code,
    String? address,
    String? phone,
    required bool status,
  }) async {
    final response = await _apiService.put(
      ApiConstants.branchDetails(id),
      data: {
        'name': name,
        'code': code,
        'address': address,
        'phone': phone,
        'status': status,
      },
    );

    final responseData = Map<String, dynamic>.from(response.data);

    return BranchModel.fromJson(
      Map<String, dynamic>.from(responseData['data']),
    );
  }

  // ============================================================
  // UPDATE BRANCH STATUS
  // Uses dedicated PATCH /branches/:id/status endpoint
  // ============================================================

  Future<BranchModel> updateBranchStatus({
    required BranchModel branch,
    required bool status,
  }) async {
    final response = await _apiService.patch(
      ApiConstants.branchStatus(branch.id),
      data: {'status': status},
    );

    final responseData = Map<String, dynamic>.from(response.data);

    return BranchModel.fromJson(
      Map<String, dynamic>.from(responseData['data']),
    );
  }
}