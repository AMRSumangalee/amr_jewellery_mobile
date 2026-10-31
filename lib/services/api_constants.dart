class ApiConstants {
  ApiConstants._();
  // ============================================================
  // BASE URL
  // ============================================================
  // static const String baseUrl = "https://amr4roads.in/api";
  // static const String baseUrl = "http://10.227.105.75:5000/api";
  static const String baseUrl = "https://icing-uncoiled-copper.ngrok-free.dev/api";
  // ============================================================
  // AUTH
  // ============================================================

  static const String login = "/auth/login";

  static const String me = "/auth/me";

  static String updateUserPassword(int id) => "/users/$id/password";

  // ============================================================
  // BRANCH
  // ============================================================

  static const String branches = "/branches";

  static String branchDetails(int id) => "/branches/$id";

  static String branchStatus(int id) => "/branches/$id/status";

  // ============================================================
  // MASTER DATA
  // ============================================================

  static const String metals = "/metals";

  static const String categories = "/categories";

  static const String repairTypes = "/repair-types";

  // ============================================================
  // MAKERS
  // ============================================================

  static const String makers = "/makers";

  static String makerDetails(int id) => "/makers/$id";

  // ============================================================
  // ORDERS
  // ============================================================

  static const String orders = "/orders";

  static String orderDetails(int id) => "/orders/$id";

  static String orderUpdate(int id) => "/orders/$id";

  static String orderDelete(int id) => "/orders/$id";

  static String shareOrderWhatsApp(int id) => '/orders/$id/share-whatsapp';
  static String shareOrderWhatsAppImage(int id) =>
      '$baseUrl/orders/$id/share-whatsapp-image';

  static String shareOrderWhatsAppVideo(int id) =>
      '/orders/$id/share-whatsapp-video';

  static String orderStatusHistory(int id) => '/orders/$id/status-history';

  static String updateOrderStatus(int id) => '/orders/$id/status';

  static const String dashboardSummary = "/dashboard/summary";
}
