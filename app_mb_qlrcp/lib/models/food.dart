class Food {
  final int foodId;
  final String name;
  final double price;
  final String? description;

  Food({
    required this.foodId,
    required this.name,
    required this.price,
    this.description,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      foodId: json['food_id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_id': foodId,
      'name': name,
      'price': price,
      'description': description,
    };
  }
}
