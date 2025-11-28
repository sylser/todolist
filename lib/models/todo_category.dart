class TodoCategory {
  final String id;
  final String name;
  final int order;

  TodoCategory({
    required this.id,
    required this.name,
    required this.order,
  });

  TodoCategory copyWith({
    String? id,
    String? name,
    int? order,
  }) {
    return TodoCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
    };
  }

  factory TodoCategory.fromJson(Map<String, dynamic> json) {
    return TodoCategory(
      id: json['id'],
      name: json['name'],
      order: json['order'] ?? 0,
    );
  }
}
