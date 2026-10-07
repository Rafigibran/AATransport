class Car {
  final String id;
  final String name;
  final String location;
  final String image;
  final List<String> photos;
  final int price; // IDR per day
  final String carType; // MPV, SUV, Van, Premium, City Car
  final int seats;
  final String transmission; // Automatic / Manual
  final String fuelType; // Bensin / Diesel / Hybrid
  final int baggage; // number of large bags
  final double rating;
  final int reviews;
  final String description;
  final List<String> features;
  final bool isFavourite;

  const Car({
    required this.id,
    required this.name,
    required this.location,
    required this.image,
    required this.photos,
    required this.price,
    this.carType = 'MPV',
    this.seats = 7,
    this.transmission = 'Automatic',
    this.fuelType = 'Bensin',
    this.baggage = 2,
    required this.rating,
    required this.reviews,
    required this.description,
    required this.features,
    this.isFavourite = false,
  });

  Car copyWith({bool? isFavourite}) {
    return Car(
      id: id,
      name: name,
      location: location,
      image: image,
      photos: photos,
      price: price,
      carType: carType,
      seats: seats,
      transmission: transmission,
      fuelType: fuelType,
      baggage: baggage,
      rating: rating,
      reviews: reviews,
      description: description,
      features: features,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }

  factory Car.fromMap(Map<String, dynamic> map, {bool isFavourite = false}) {
    final photos = <String>[];
    final rawPhotos = map['car_photos'];
    if (rawPhotos is List) {
      final sorted = [...rawPhotos]..sort((a, b) =>
          ((a['sort_order'] ?? 0) as num)
              .compareTo((b['sort_order'] ?? 0) as num));
      for (final p in sorted) {
        if (p is Map && p['url'] != null) photos.add(p['url'].toString());
      }
    }
    final features = <String>[];
    final rawFeatures = map['car_features'];
    if (rawFeatures is List) {
      for (final f in rawFeatures) {
        final fac = f is Map ? f['features'] : null;
        if (fac is Map && fac['name'] != null)
          features.add(fac['name'].toString());
      }
    }
    final image = (map['image_url'] ?? '').toString();
    return Car(
      id: map['id'].toString(),
      name: (map['name'] ?? '').toString(),
      location: (map['location'] ?? '').toString(),
      image: image,
      photos: photos.isEmpty && image.isNotEmpty ? [image] : photos,
      price: (map['price_per_day'] as num?)?.toInt() ?? 0,
      carType: (map['car_type'] ?? 'MPV').toString(),
      seats: (map['seats'] as num?)?.toInt() ?? 7,
      transmission: (map['transmission'] ?? 'Automatic').toString(),
      fuelType: (map['fuel_type'] ?? 'Bensin').toString(),
      baggage: (map['baggage'] as num?)?.toInt() ?? 2,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviews: (map['review_count'] as num?)?.toInt() ?? 0,
      description: (map['description'] ?? '').toString(),
      features: features,
      isFavourite: isFavourite,
    );
  }
}

class Booking {
  final String id;
  final Car car;
  final DateTime pickupDate;
  final DateTime returnDate;
  final int passengers;
  final int units;
  final String serviceType;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final int days;
  final int subtotal;
  final int tax;
  final int total;
  final String
      status; // pending_payment, confirmed, completed, cancelled, expired
  final String paymentStatus; // pending, berhasil, expired, failed
  final String? paymentMethodCode;
  final String? checkoutUrl;
  final String? paymentNo;
  final String? qrString;
  final String? trxId;
  final DateTime? createdAt;

  const Booking({
    required this.id,
    required this.car,
    required this.pickupDate,
    required this.returnDate,
    required this.passengers,
    required this.units,
    required this.serviceType,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.days,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    required this.paymentStatus,
    this.paymentMethodCode,
    this.checkoutUrl,
    this.paymentNo,
    this.qrString,
    this.trxId,
    this.createdAt,
  });

  /// Tab bucket used by My Booking: upcoming | completed | cancelled
  String get tabStatus {
    if (status == 'cancelled' || status == 'expired') return 'cancelled';
    if (status == 'completed') return 'completed';
    if (returnDate.isBefore(DateTime.now())) return 'completed';
    return 'upcoming';
  }

  bool get isPaid => paymentStatus == 'berhasil';

  factory Booking.fromMap(Map<String, dynamic> map) {
    final carMap = map['cars'] as Map<String, dynamic>?;
    final car = carMap != null
        ? Car.fromMap(carMap)
        : const Car(
            id: '',
            name: 'Car',
            location: '',
            image: '',
            photos: [],
            price: 0,
            rating: 0,
            reviews: 0,
            description: '',
            features: []);
    DateTime parseDate(dynamic v) =>
        DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
    return Booking(
      id: map['id'].toString(),
      car: car,
      pickupDate: parseDate(map['pickup_date']),
      returnDate: parseDate(map['return_date']),
      passengers: (map['passengers'] as num?)?.toInt() ?? 1,
      units: (map['units'] as num?)?.toInt() ?? 1,
      serviceType: (map['service_type'] ?? 'Dengan Sopir').toString(),
      customerName: (map['customer_name'] ?? '').toString(),
      customerEmail: (map['customer_email'] ?? '').toString(),
      customerPhone: (map['customer_phone'] ?? '').toString(),
      days: (map['days'] as num?)?.toInt() ?? 1,
      subtotal: (map['subtotal'] as num?)?.toInt() ?? 0,
      tax: (map['tax'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 0,
      status: (map['status'] ?? 'pending_payment').toString(),
      paymentStatus: (map['payment_status'] ?? 'pending').toString(),
      paymentMethodCode: map['payment_method_code']?.toString(),
      checkoutUrl: map['checkout_url']?.toString(),
      paymentNo: map['payment_no']?.toString(),
      qrString: map['qr_string']?.toString(),
      trxId: map['sakurupiah_trx_id']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}

class ReviewItem {
  final String id;
  final String name;
  final String avatar;
  final double rating;
  final String comment;
  final String date;

  const ReviewItem({
    required this.id,
    required this.name,
    required this.avatar,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory ReviewItem.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    final created = DateTime.tryParse(map['created_at']?.toString() ?? '');
    return ReviewItem(
      id: map['id'].toString(),
      name: (profile?['full_name'] ?? 'Pengguna A&A Transport').toString(),
      avatar: (profile?['avatar_url'] ?? '').toString(),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      comment: (map['comment'] ?? '').toString(),
      date: created != null
          ? '${created.day}/${created.month}/${created.year}'
          : '',
    );
  }
}

class BookingDraft {
  final Car car;
  final DateTime pickupDate;
  final DateTime returnDate;
  final int passengers;
  final int units;
  final String serviceType;
  final String paymentMethodCode;

  const BookingDraft({
    required this.car,
    required this.pickupDate,
    required this.returnDate,
    required this.passengers,
    required this.units,
    required this.serviceType,
    required this.paymentMethodCode,
  });

  int get days => returnDate.difference(pickupDate).inDays;
  int get subtotal => car.price * days * units;
  int get tax => (subtotal * 0.10).round(); // Pajak & biaya layanan 10%
  int get total => subtotal + tax;
}

class PaymentChannel {
  final String code;
  final String name;
  const PaymentChannel(this.code, this.name);
}

const paymentChannels = <PaymentChannel>[
  PaymentChannel('QRIS', 'QRIS'),
  PaymentChannel('QRISC', 'QRIS (semua e-wallet)'),
  PaymentChannel('BCAVA', 'BCA Virtual Account'),
  PaymentChannel('BRIVA', 'BRI Virtual Account'),
  PaymentChannel('BSIVA', 'BSI Virtual Account'),
  PaymentChannel('BNCVA', 'BNC Virtual Account'),
  PaymentChannel('DANAMON', 'Danamon Virtual Account'),
  PaymentChannel('GOPAY', 'GoPay'),
  PaymentChannel('ShopeePay', 'ShopeePay'),
  PaymentChannel('ALFAMART', 'Alfamart'),
  PaymentChannel('INDOMARET', 'Indomaret'),
];

class PaymentResult {
  final String? trxId;
  final String? merchantRef;
  final String? checkoutUrl;
  final String? paymentNo;
  final String? qrString;
  final String? methodCode;

  const PaymentResult(
      {this.trxId,
      this.merchantRef,
      this.checkoutUrl,
      this.paymentNo,
      this.qrString,
      this.methodCode});

  factory PaymentResult.fromMap(Map<String, dynamic> map) {
    return PaymentResult(
      trxId: map['trx_id']?.toString(),
      merchantRef: map['merchant_ref']?.toString(),
      checkoutUrl: map['checkout_url']?.toString(),
      paymentNo: map['payment_no']?.toString(),
      qrString: map['qr_string']?.toString(),
      methodCode: map['method_code']?.toString(),
    );
  }
}
