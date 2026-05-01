class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int categoryId;
  final double rating;
  final String roastedLevel;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    this.rating = 4.5,
    this.roastedLevel = 'Medium Roasted',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'],
      categoryId: json['category_id'],
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      roastedLevel: json['roasted_level'] ?? 'Medium Roasted',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category_id': categoryId,
      'rating': rating,
      'roasted_level': roastedLevel,
    };
  }
}
