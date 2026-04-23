class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic json) fromJsonT) {
    return ApiResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic json) fromJsonT) {
    return PaginatedResponse(
      items: (json['items'] as List<dynamic>?)?.map(fromJsonT).toList() ?? [],
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
    );
  }
}
