import 'package:equatable/equatable.dart';

class CartItemModel extends Equatable {
  final String id;
  final String name;
  final String image;
  final double price;
  final int quantity;

  const CartItemModel({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.quantity = 1,
  });

  CartItemModel copyWith({
    String? id,
    String? name,
    String? image,
    double? price,
    int? quantity,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [id, name, image, price, quantity];
}
