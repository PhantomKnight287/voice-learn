class ApiResponseHelper {
  static String getErrorMessage(dynamic error, [String? message]) {
    if (error is String) {
      return error;
    } else if (error is Map) {
      if (error['message'] is List) {
        return error['message'][0];
      } else {
        return error['message'];
      }
    } else {
      return message ?? 'Something went wrong';
    }
  }
}
