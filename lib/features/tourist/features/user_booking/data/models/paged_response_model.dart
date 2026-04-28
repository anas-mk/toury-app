class PagedResponse<T> {
  final List<T> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;

  bool get hasNextPage => pageNumber * pageSize < totalCount;
  bool get hasPreviousPage => pageNumber > 1;
  int get totalPages => totalCount == 0 ? 1 : ((totalCount + pageSize - 1) ~/ pageSize);

  PagedResponse({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResponse<T>(
      items: (json['items'] as List? ?? []).map((i) => fromJsonT(i)).toList(),
      // Backend returns 'page', not 'pageNumber'
      pageNumber: json['page'] ?? json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      totalCount: json['totalCount'] ?? 0,
    );
  }
}
