class Hotel {
  final String id;
  final String name;
  final String location;
  final String image;
  final List<String> photos;
  final int price; // IDR per night
  final double rating;
  final int reviews;
  final String description;
  final List<String> facilities;
  final bool isFavourite;

  const Hotel({
    required this.id,
    required this.name,
    required this.location,
    required this.image,
    required this.photos,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.description,
    required this.facilities,
    this.isFavourite = false,
  });

  Hotel copyWith({bool? isFavourite}) {
    return Hotel(
      id: id,
      name: name,
      location: location,
      image: image,
      photos: photos,
      price: price,
      rating: rating,
      reviews: reviews,
      description: description,
      facilities: facilities,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }

  factory Hotel.fromMap(Map<String, dynamic> map, {bool isFavourite = false}) {
    final photos = <String>[];
    final rawPhotos = map['hotel_photos'];
    if (rawPhotos is List) {
      final sorted = [...rawPhotos]..sort((a, b) =>
          ((a['sort_order'] ?? 0) as num)
              .compareTo((b['sort_order'] ?? 0) as num));
      for (final p in sorted) {
        if (p is Map && p['url'] != null) photos.add(p['url'].toString());
      }
    }
    final facilities = <String>[];
    final rawFacilities = map['hotel_facilities'];
    if (rawFacilities is List) {
      for (final f in rawFacilities) {
        final fac = f is Map ? f['facilities'] : null;
        if (fac is Map && fac['name'] != null)
          facilities.add(fac['name'].toString());
      }
    }
    final image = (map['image_url'] ?? '').toString();
    return Hotel(
      id: map['id'].toString(),
      name: (map['name'] ?? '').toString(),
      location: (map['location'] ?? '').toString(),
      image: image,
      photos: photos.isEmpty && image.isNotEmpty ? [image] : photos,
      price: (map['price_per_night'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviews: (map['review_count'] as num?)?.toInt() ?? 0,
      description: (map['description'] ?? '').toString(),
      facilities: facilities,
      isFavourite: isFavourite,
    );
  }
}

class Booking {
  final String id;
  final Hotel hotel;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int rooms;
  final String roomType;
  final String guestName;
  final String guestEmail;
  final String guestPhone;
  final int nights;
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
    required this.hotel,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.rooms,
    required this.roomType,
    required this.guestName,
    required this.guestEmail,
    required this.guestPhone,
    required this.nights,
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
    if (checkOut.isBefore(DateTime.now())) return 'completed';
    return 'upcoming';
  }

  bool get isPaid => paymentStatus == 'berhasil';

  factory Booking.fromMap(Map<String, dynamic> map) {
    final hotelMap = map['hotels'] as Map<String, dynamic>?;
    final hotel = hotelMap != null
        ? Hotel.fromMap(hotelMap)
        : const Hotel(
            id: '',
            name: 'Hotel',
            location: '',
            image: '',
            photos: [],
            price: 0,
            rating: 0,
            reviews: 0,
            description: '',
            facilities: []);
    DateTime parseDate(dynamic v) =>
        DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
    return Booking(
      id: map['id'].toString(),
      hotel: hotel,
      checkIn: parseDate(map['check_in']),
      checkOut: parseDate(map['check_out']),
      guests: (map['guests'] as num?)?.toInt() ?? 1,
      rooms: (map['rooms'] as num?)?.toInt() ?? 1,
      roomType: (map['room_type'] ?? 'Economy Room').toString(),
      guestName: (map['guest_name'] ?? '').toString(),
      guestEmail: (map['guest_email'] ?? '').toString(),
      guestPhone: (map['guest_phone'] ?? '').toString(),
      nights: (map['nights'] as num?)?.toInt() ?? 1,
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
      name: (profile?['full_name'] ?? 'Pengguna Hipo').toString(),
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
  final Hotel hotel;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int rooms;
  final String roomType;
  final String paymentMethodCode;

  const BookingDraft({
    required this.hotel,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.rooms,
    required this.roomType,
    required this.paymentMethodCode,
  });

  int get nights => checkOut.difference(checkIn).inDays;
  int get subtotal => hotel.price * nights * rooms;
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
