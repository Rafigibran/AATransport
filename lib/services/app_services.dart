import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/car.dart';

SupabaseClient get _db => Supabase.instance.client;

String? get currentUserId => _db.auth.currentUser?.id;

class AuthService {
  static Future<AuthResponse> signIn(String email, String password) {
    return _db.auth.signInWithPassword(email: email.trim(), password: password);
  }

  static Future<AuthResponse> signUp(
      String name, String email, String password, String? phone) {
    return _db.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': name.trim(),
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim()
      },
    );
  }

  static Future<void> sendPasswordReset(String email) {
    return _db.auth.resetPasswordForEmail(email.trim());
  }

  static Future<AuthResponse> verifyRecoveryOtp(String email, String token) {
    return _db.auth.verifyOTP(
        email: email.trim(), token: token.trim(), type: OtpType.recovery);
  }

  static Future<void> updatePassword(String newPassword) async {
    await _db.auth.updateUser(UserAttributes(password: newPassword));
  }

  static Future<void> signOut() => _db.auth.signOut();

  static bool get isLoggedIn => _db.auth.currentSession != null;
}

class CarService {
  static const _carColumns =
      '*, car_photos(url, sort_order), car_features(features(name))';

  static Future<Set<String>> favouriteIds() async {
    final uid = currentUserId;
    if (uid == null) return {};
    final rows =
        await _db.from('favourites').select('car_id').eq('user_id', uid);
    return rows.map((r) => r['car_id'].toString()).toSet();
  }

  static Future<List<Car>> fetchCars({String query = ''}) async {
    final rows = await _db
        .from('cars')
        .select(_carColumns)
        .eq('is_active', true)
        .order('rating', ascending: false);
    final favs = await favouriteIds();
    var cars = rows
        .map((r) =>
            Car.fromMap(r, isFavourite: favs.contains(r['id'].toString())))
        .toList();
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      cars = cars
          .where((h) =>
              h.name.toLowerCase().contains(q) ||
              h.location.toLowerCase().contains(q))
          .toList();
    }
    return cars;
  }

  static Future<List<Car>> fetchFavourites() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final rows = await _db
        .from('favourites')
        .select('car_id, cars($_carColumns)')
        .eq('user_id', uid);
    final cars = <Car>[];
    for (final r in rows) {
      final h = r['cars'];
      if (h is Map<String, dynamic>)
        cars.add(Car.fromMap(h, isFavourite: true));
    }
    return cars;
  }

  static Future<bool> toggleFavourite(Car car) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Silakan login terlebih dahulu');
    if (car.isFavourite) {
      await _db
          .from('favourites')
          .delete()
          .eq('user_id', uid)
          .eq('car_id', car.id);
      return false;
    }
    await _db.from('favourites').insert({'user_id': uid, 'car_id': car.id});
    return true;
  }

  static Future<List<ReviewItem>> fetchReviews(String carId) async {
    final rows = await _db
        .from('reviews')
        .select('*, profiles(full_name, avatar_url)')
        .eq('car_id', carId)
        .order('created_at', ascending: false);
    return rows.map((r) => ReviewItem.fromMap(r)).toList();
  }

  static Future<void> addReview(
      {required String carId,
      String? bookingId,
      required int rating,
      required String comment}) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Silakan login terlebih dahulu');
    await _db.from('reviews').insert({
      'user_id': uid,
      'car_id': carId,
      if (bookingId != null) 'booking_id': bookingId,
      'rating': rating,
      'comment': comment.trim(),
    });
  }
}

class BookingService {
  static const _bookingColumns = '*, cars(*)';

  static Future<Booking> createBooking(BookingDraft draft,
      {required String customerName,
      required String customerEmail,
      required String customerPhone}) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Silakan login terlebih dahulu');
    final row = await _db
        .from('bookings')
        .insert({
          'user_id': uid,
          'car_id': draft.car.id,
          'pickup_date': draft.pickupDate.toIso8601String().substring(0, 10),
          'return_date': draft.returnDate.toIso8601String().substring(0, 10),
          'passengers': draft.passengers,
          'units': draft.units,
          'service_type': draft.serviceType,
          'customer_name': customerName.trim(),
          'customer_email': customerEmail.trim(),
          'customer_phone': customerPhone.trim(),
          'days': draft.days,
          'subtotal': draft.subtotal,
          'tax': draft.tax,
          'total': draft.total,
          'payment_method_code': draft.paymentMethodCode,
        })
        .select(_bookingColumns)
        .single();
    return Booking.fromMap(row);
  }

  static Future<List<Booking>> fetchBookings() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final rows = await _db
        .from('bookings')
        .select(_bookingColumns)
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return rows.map((r) => Booking.fromMap(r)).toList();
  }

  static Future<void> cancelBooking(String bookingId) async {
    await _db
        .from('bookings')
        .update({'status': 'cancelled'}).eq('id', bookingId);
  }

  static Future<PaymentResult> createPayment(
      String bookingId, String methodCode) async {
    final res = await _db.functions.invoke('create-payment',
        body: {'booking_id': bookingId, 'method_code': methodCode});
    final data = res.data;
    if (data is Map<String, dynamic>) {
      if (data['error'] != null) throw Exception(data['error'].toString());
      return PaymentResult.fromMap(data);
    }
    if (data is Map)
      return PaymentResult.fromMap(Map<String, dynamic>.from(data));
    throw Exception('Respons pembayaran tidak valid');
  }

  /// Returns the SakuRupiah status string: pending | berhasil | expired
  static Future<String> checkPayment(String bookingId) async {
    final res = await _db.functions
        .invoke('check-payment', body: {'booking_id': bookingId});
    final data = res.data;
    if (data is Map && data['error'] != null)
      throw Exception(data['error'].toString());
    if (data is Map && data['status'] != null) return data['status'].toString();
    throw Exception('Gagal mengecek status pembayaran');
  }
}

class ProfileService {
  static Future<Map<String, dynamic>?> fetchProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    final existing =
        await _db.from('profiles').select().eq('id', uid).maybeSingle();
    if (existing != null) return existing;
    // Fallback for accounts created before the profile trigger existed.
    final user = _db.auth.currentUser;
    final created = await _db
        .from('profiles')
        .insert({
          'id': uid,
          'full_name': (user?.userMetadata?['full_name'] ?? '').toString(),
          'email': user?.email ?? '',
          'phone': user?.userMetadata?['phone']?.toString(),
        })
        .select()
        .single();
    return created;
  }

  static Future<void> updateProfile(
      {required String name, String? phone}) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Silakan login terlebih dahulu');
    await _db.from('profiles').update(
        {'full_name': name.trim(), 'phone': phone?.trim()}).eq('id', uid);
    await _db.auth.updateUser(UserAttributes(data: {'full_name': name.trim()}));
  }

  static Future<List<Map<String, dynamic>>> savedPaymentMethods() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final rows = await _db
        .from('saved_payment_methods')
        .select()
        .eq('user_id', uid)
        .order('created_at');
    return rows.cast<Map<String, dynamic>>();
  }

  static Future<void> addSavedPaymentMethod(String code, String label) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Silakan login terlebih dahulu');
    await _db
        .from('saved_payment_methods')
        .insert({'user_id': uid, 'method_code': code, 'label': label});
  }

  static Future<void> deleteSavedPaymentMethod(String id) async {
    await _db.from('saved_payment_methods').delete().eq('id', id);
  }
}
