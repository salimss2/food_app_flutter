class Offer {
  final String id;
  final String description;
  final double? discountPrice;

  Offer({required this.id, required this.description, this.discountPrice});

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      discountPrice: double.tryParse(json['discount_price']?.toString() ?? ''),
    );
  }
}

class Meal {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final bool available;
  final List<Offer> offers;
  final String? discountType;
  final double? discountValue;
  final DateTime? discountStart;
  final DateTime? discountEnd;
  final double? priceAfterDiscount;

  Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.available = true,
    this.offers = const [],
    this.discountType,
    this.discountValue,
    this.discountStart,
    this.discountEnd,
    this.priceAfterDiscount,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    var offersList = json['offers'] as List?;
    
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return Meal(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url']?.toString(), // mapped from image_url
      available: _parseAvailable(json['available']),
      offers: offersList != null
          ? offersList
                .map((e) => Offer.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      discountType: json['discount_type']?.toString(),
      discountValue: double.tryParse(json['discount_value']?.toString() ?? ''),
      discountStart: parseDateTime(json['discount_start']),
      discountEnd: parseDateTime(json['discount_end']),
      priceAfterDiscount: double.tryParse(json['price_after_discount']?.toString() ?? ''),
    );
  }

  static bool _parseAvailable(dynamic value) {
    if (value == null) return true; // Default to true if not provided
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return true;
  }
}

class Menu {
  final String id;
  final String name;
  final List<Meal> meals;

  Menu({required this.id, required this.name, this.meals = const []});

  factory Menu.fromJson(Map<String, dynamic> json) {
    var mealsList = json['meals'] as List?;
    return Menu(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      meals: mealsList != null
          ? mealsList
                .map((e) => Meal.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
    );
  }
}

class Restaurant {
  final String id;
  final String name;
  final String address;
  final String distance;
  final double rating;
  final bool isOpen;
  final String? imageUrl;
  final List<String> tags;
  final List<Menu> menus;
  final List<Meal> meals;
  final List<Offer> offers;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.isOpen,
    this.imageUrl,
    this.tags = const [],
    this.menus = const [],
    this.meals = const [],
    this.offers = const [],
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    var tagsList = json['tags'] as List?;
    var menusList = json['menus'] as List?;
    var mealsList = json['meals'] as List?;
    var offersList = json['offers'] as List?;

    bool isOpen = (json['is_open'] == true) || 
                  (json['is_open'] == 1) || 
                  (json['is_open'] == '1') || 
                  (json['status']?.toString().toLowerCase() == 'open');

    print("🍔 Restaurant API Status -> name: ${json['name']}, status: ${json['status']}, is_open: ${json['is_open']} | Parsed isOpen: $isOpen");

    return Restaurant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      distance: json['distance']?.toString() ?? '0.0',
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      isOpen: isOpen,
      // imageUrl: json['image_url']?.toString() ?? json['logo']?.toString(),
      imageUrl: json['logo']?.toString() ?? json['image']?.toString(),
      tags: tagsList != null ? tagsList.map((e) => e.toString()).toList() : [],
      menus: menusList != null
          ? menusList
                .map((e) => Menu.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      meals: mealsList != null
          ? mealsList
                .map((e) => Meal.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      offers: offersList != null
          ? offersList
                .map((e) => Offer.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
    );
  }
}
