class PaginationMeta {
  final int page;
  final int perPage;
  final int total;
  final int totalPages;
  final bool firstPage;
  final bool lastPage;

  const PaginationMeta({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
    required this.firstPage,
    required this.lastPage,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: (json['page'] ?? 1) as int,
      perPage: (json['perPage'] ?? 20) as int,
      total: (json['total'] ?? 0) as int,
      totalPages: (json['totalPages'] ?? 1) as int,
      firstPage: (json['firstPage'] ?? true) as bool,
      lastPage: (json['lastPage'] ?? true) as bool,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final PaginationMeta pagination;

  const PaginatedResponse({required this.data, required this.pagination});
}
