import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/cart_item_model.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddItemToCart>(_onAddItemToCart);
    on<RemoveItemFromCart>(_onRemoveItemFromCart);
    on<IncrementItemQuantity>(_onIncrementItemQuantity);
    on<DecrementItemQuantity>(_onDecrementItemQuantity);
    on<ClearCart>(_onClearCart);
  }

  void _onAddItemToCart(AddItemToCart event, Emitter<CartState> emit) {
    final List<CartItemModel> currentItems = List.from(state.items);
    final index = currentItems.indexWhere((item) => item.id == event.item.id);

    if (index >= 0) {
      currentItems[index] = currentItems[index].copyWith(
        quantity: currentItems[index].quantity + event.item.quantity,
      );
    } else {
      currentItems.add(event.item);
    }

    emit(state.copyWith(items: currentItems));
  }

  void _onRemoveItemFromCart(RemoveItemFromCart event, Emitter<CartState> emit) {
    final currentItems = state.items.where((item) => item.id != event.itemId).toList();
    emit(state.copyWith(items: currentItems));
  }

  void _onIncrementItemQuantity(IncrementItemQuantity event, Emitter<CartState> emit) {
    final List<CartItemModel> currentItems = List.from(state.items);
    final index = currentItems.indexWhere((item) => item.id == event.itemId);

    if (index >= 0) {
      currentItems[index] = currentItems[index].copyWith(
        quantity: currentItems[index].quantity + 1,
      );
      emit(state.copyWith(items: currentItems));
    }
  }

  void _onDecrementItemQuantity(DecrementItemQuantity event, Emitter<CartState> emit) {
    final List<CartItemModel> currentItems = List.from(state.items);
    final index = currentItems.indexWhere((item) => item.id == event.itemId);

    if (index >= 0) {
      if (currentItems[index].quantity > 1) {
        currentItems[index] = currentItems[index].copyWith(
          quantity: currentItems[index].quantity - 1,
        );
      } else {
        currentItems.removeAt(index);
      }
      emit(state.copyWith(items: currentItems));
    }
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState(items: []));
  }
}
