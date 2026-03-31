import 'package:equatable/equatable.dart';
import '../../../domain/models/cart_item_model.dart';

class CartState extends Equatable {
  final List<CartItemModel> items;

  const CartState({this.items = const []});

  double get subtotal {
    return items.fold(0, (total, item) => total + (item.price * item.quantity));
  }

  double get deliveryFee => items.isEmpty ? 0 : 1500.0;

  double get grandTotal => subtotal + deliveryFee;

  CartState copyWith({List<CartItemModel>? items}) {
    return CartState(items: items ?? this.items);
  }

  @override
  List<Object?> get props => [items];
}
