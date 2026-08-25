enum PaymentType { upi, creditCard, debitCard, netBanking, wallet, cashOnDelivery }

class SavedCardModel {
  final String id;
  final String last4;
  final String network; // Visa / Mastercard / Rupay
  final String expiry; // MM/YY

  const SavedCardModel({required this.id, required this.last4, required this.network, required this.expiry});

  factory SavedCardModel.fromJson(Map<String, dynamic> json) => SavedCardModel(
        id: json['id'].toString(),
        last4: json['last4'] as String,
        network: json['network'] as String,
        expiry: json['expiry'] as String,
      );
}

class PaymentMethodOption {
  final PaymentType type;
  final String label;
  final String? subtitle;

  const PaymentMethodOption({required this.type, required this.label, this.subtitle});
}

const kPaymentMethodOptions = <PaymentMethodOption>[
  PaymentMethodOption(type: PaymentType.upi, label: 'UPI', subtitle: 'Google Pay, PhonePe, Paytm & more'),
  PaymentMethodOption(type: PaymentType.creditCard, label: 'Credit Card'),
  PaymentMethodOption(type: PaymentType.debitCard, label: 'Debit Card'),
  PaymentMethodOption(type: PaymentType.netBanking, label: 'Net Banking'),
  PaymentMethodOption(type: PaymentType.wallet, label: 'Wallet', subtitle: 'Amazon Pay, Mobikwik & more'),
  PaymentMethodOption(type: PaymentType.cashOnDelivery, label: 'Cash on Delivery'),
];
