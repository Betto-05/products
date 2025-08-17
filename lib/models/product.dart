// --- MODELS with JSON Serialization ---
class Product {
  final String id;
  String name;
  int quantity;
  DateTime expiryDate;

  Product({
    required this.id,
    required this.name,
    required this.quantity,
    required this.expiryDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'expiryDate': expiryDate.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    quantity: json['quantity'],
    expiryDate: DateTime.parse(json['expiryDate']),
  );
}
