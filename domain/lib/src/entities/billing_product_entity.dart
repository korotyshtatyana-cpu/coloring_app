import 'package:equatable/equatable.dart';

/// A product offered by the platform store.
class BillingProductEntity extends Equatable {
  /// Store product identifier.
  final String id;

  /// Localized product title.
  final String title;

  /// Localized product description.
  final String description;

  /// Localized price formatted by the store, for example `249 ₽`.
  final String price;

  /// ISO 4217 currency code reported by the store.
  final String currencyCode;

  /// Whether the product is an auto-renewing subscription.
  final bool isSubscription;

  /// Creates a [BillingProductEntity].
  const BillingProductEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    required this.isSubscription,
  });

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    description,
    price,
    currencyCode,
    isSubscription,
  ];
}
