import '../core/utils/image_url_helper.dart';

class OfferModel {
  final int id;
  final String title;
  final String? description;
  final String type; // 'banner' | 'direct_cart'
  final String clickAction; // 'restaurant' | 'cart' | 'coupon'
  final int? restaurantId;
  final int? mealId;
  final double? originalPrice;
  final double? offerPrice;
  final double? discountPercentage;
  final String? bannerImage;
  final String? couponCode;
  final Map<String, dynamic>? restaurant;
  final Map<String, dynamic>? meal;

  OfferModel({
    required this.id,
    required this.title,
    this.description,
    this.type = 'banner',
    this.clickAction = 'restaurant',
    this.restaurantId,
    this.mealId,
    this.originalPrice,
    this.offerPrice,
    this.discountPercentage,
    this.bannerImage,
    this.couponCode,
    this.restaurant,
    this.meal,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    // 1. Parse ID safely
    final int parsedId = int.tryParse(json['id']?.toString() ?? '0') ?? 0;

    // 2. Parse Title
    final String parsedTitle = json['title']?.toString() ??
        json['name']?.toString() ??
        json['meal']?['name']?.toString() ??
        '';

    // 3. Parse Description
    final String? parsedDescription = json['description']?.toString() ??
        json['subtitle']?.toString() ??
        json['meal']?['description']?.toString();

    // 4. Parse Type ('banner' | 'direct_cart')
    final String rawType = json['type']?.toString().toLowerCase() ?? '';
    final String parsedType =
        (rawType == 'direct_cart' || rawType == 'cart') ? 'direct_cart' : 'banner';

    // 5. Parse Click Action ('restaurant' | 'cart' | 'coupon')
    String parsedClickAction = json['click_action']?.toString().toLowerCase() ??
        json['clickAction']?.toString().toLowerCase() ??
        json['action']?.toString().toLowerCase() ??
        '';

    if (parsedClickAction.isEmpty) {
      if (parsedType == 'direct_cart') {
        parsedClickAction = 'cart';
      } else if (json['coupon_code'] != null ||
          json['coupon'] != null ||
          json['code'] != null) {
        parsedClickAction = 'coupon';
      } else if (json['meal_id'] != null) {
        parsedClickAction = 'cart';
      } else {
        parsedClickAction = 'restaurant';
      }
    }

    // 6. Parse Restaurant ID & Meal ID
    final int? parsedRestaurantId = int.tryParse(
      json['restaurant_id']?.toString() ??
          json['restaurantId']?.toString() ??
          json['restaurant']?['id']?.toString() ??
          json['meal']?['restaurant_id']?.toString() ??
          json['meal']?['restaurant']?['id']?.toString() ??
          '',
    );

    final int? parsedMealId = int.tryParse(
      json['meal_id']?.toString() ??
          json['meal']?['id']?.toString() ??
          '',
    );

    // 7. Parse Prices & Discounts
    final double? parsedOriginalPrice = double.tryParse(
      json['original_price']?.toString() ??
          json['price']?.toString() ??
          json['meal']?['price']?.toString() ??
          '',
    );

    final double? parsedOfferPrice = double.tryParse(
      json['offer_price']?.toString() ??
          json['discount_price']?.toString() ??
          json['price_after_discount']?.toString() ??
          json['combo_price']?.toString() ??
          json['meal']?['price_after_discount']?.toString() ??
          '',
    );

    double? parsedDiscountPercentage = double.tryParse(
      json['discount_percentage']?.toString() ??
          json['discount_percent']?.toString() ??
          json['discount_value']?.toString() ??
          '',
    );

    if (parsedDiscountPercentage == null &&
        parsedOriginalPrice != null &&
        parsedOriginalPrice > 0 &&
        parsedOfferPrice != null &&
        parsedOfferPrice < parsedOriginalPrice) {
      parsedDiscountPercentage =
          ((parsedOriginalPrice - parsedOfferPrice) / parsedOriginalPrice) * 100;
    }

    // 8. Image parsing with mandatory ImageUrlHelper.normalize()
    final String? rawImage = json['banner_image']?.toString() ??
        json['bannerImage']?.toString() ??
        json['image_url']?.toString() ??
        json['image']?.toString() ??
        json['photo']?.toString() ??
        json['meal']?['image_url']?.toString() ??
        json['meal']?['image']?.toString();

    final String? normalizedImage = (rawImage != null && rawImage.trim().isNotEmpty)
        ? ImageUrlHelper.normalize(rawImage)
        : null;

    // 9. Coupon Code
    final String? parsedCouponCode = json['coupon_code']?.toString() ??
        json['coupon']?.toString() ??
        json['code']?.toString();

    return OfferModel(
      id: parsedId,
      title: parsedTitle,
      description: parsedDescription,
      type: parsedType,
      clickAction: parsedClickAction,
      restaurantId: parsedRestaurantId,
      mealId: parsedMealId,
      originalPrice: parsedOriginalPrice,
      offerPrice: parsedOfferPrice,
      discountPercentage: parsedDiscountPercentage,
      bannerImage: normalizedImage,
      couponCode: parsedCouponCode,
      restaurant: json['restaurant'] is Map<String, dynamic>
          ? json['restaurant'] as Map<String, dynamic>
          : null,
      meal: json['meal'] is Map<String, dynamic>
          ? json['meal'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'click_action': clickAction,
      'restaurant_id': restaurantId,
      'meal_id': mealId,
      'original_price': originalPrice,
      'offer_price': offerPrice,
      'discount_percentage': discountPercentage,
      'banner_image': bannerImage,
      'coupon_code': couponCode,
      'restaurant': restaurant,
      'meal': meal,
    };
  }
}
