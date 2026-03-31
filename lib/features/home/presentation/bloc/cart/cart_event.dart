import 'package:equatable/equatable.dart';
import '../../../domain/models/cart_item_model.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();
  
  @override
  List<Object?> get props => [];
}

class AddItemToCart extends CartEvent {
  final CartItemModel item;
  const AddItemToCart(this.item);

  @override
  List<Object?> get props => [item];
}

class RemoveItemFromCart extends CartEvent {
  final String itemId;
  const RemoveItemFromCart(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class IncrementItemQuantity extends CartEvent {
  final String itemId;
  const IncrementItemQuantity(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class DecrementItemQuantity extends CartEvent {
  final String itemId;
  const DecrementItemQuantity(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class ClearCart extends CartEvent {}
