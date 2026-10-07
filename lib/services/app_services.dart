import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hotel.dart';

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

class HotelService {
  static const _hotelColumns =
      '*, hotel_photos(url, sort_order), hotel_facilities(facilities(name))';

  static Future<Set<String>> favouriteIds() async {
    final uid = currentUserId;
    if (uid == null) return {};
    final rows =
        await _db.from('favourites').select('hotel_id').eq('user_id', uid);
    return rows.map((r) => r['hotel_id'].toString()).toSet();
  }

  static Future<List<Hotel>> fetchHotels({String query = ''}) async {
    final rows = await _db
        .from('hotels')
        .select(_hotelColumns)
        .eq('is_active', true)
        .order('rating', ascending: false);
    final favs = await favouriteIds();
    var hotels = rows
        .map((r) =>
            Hotel.fromMap(r, isFavourite: favs.contains(r['id'].toString())))
        .toList();
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      hotels = hotels
          .where((h) =>
              h.name.toLowerCase().contains(q) ||
              h.location.toLowerCase().contains(q))
          .toList();
    }
    return hotels;
  }

  static Future<List<Hotel>> fetchFavourites() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final rows = await _db
        .from('favourites')
        .select('hotel_id, hotels($_hotelColumns)')
        .eq('user_id', uid);
    final hotels = <Hotel>[];
    for (final r in rows) {
      final h = r['hotels'];
      if (h is Map<String, dynamic>)
        hotels.add(Hotel.fromMap(h, isFavourite: true));
    }
    return hotels;
  }

  static Future<bool> toggleFavourite(Hotel hotel) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Silakan login terlebih dahulu');
    if (hotel.isFavourite) {
      await _db
          .from('favourites')
          .delete()
          .eq('user_id', uid)
          .eq('hotel_id', hotel.id);
      return false;
    }
    await _db.from('favourites').insert({'user_id': uid, 'hotel_id': hotel.id});
    return true;
  }

  static Future<List<ReviewItem>> fetchReviews(String hotelId) async {
    final rows = await _db
        .from('reviews')
        .select('*, profiles(full_name, avatar_url)')
        .eq('hotel_id', hotelId)
        .order('created_at', ascending: false);
    return rows.map((r) => ReviewItem.fromMap(r)).toList();
  }

  static Future<void> addReview(
      {required String hotelId,
      String? bookingId,
      required int rating,
      required String comment}) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Silakan login terlebih dahulu');
    await _db.from('reviews').insert({
      'user_id': uid,
      'hotel_id': hotelId,
      if (bookingId != null) 'booking_id': bookingId,
      'rating': rating,
      'comment': comment.trim(),
    });
  }
}

class BookingService {
  static const _bookingColumns = '*, hotels(*)';

  static Future<Booking> createBooking(BookingDraft draft,
      {required String guestName,
      required String guestEmail,
      required String guestPhone}) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Silakan login terlebih dahulu');
    final row = await _db
        .from('bookings')
        .insert({
          'user_id': uid,
          'hotel_id': draft.hotel.id,
          'check_in': draft.checkIn.toIso8601String().substring(0, 10),
          'check_out': draft.checkOut.toIso8601String().substring(0, 10),
          'guests': draft.guests,
          'rooms': draft.rooms,
          'room_type': draft.roomType,
          'guest_name': guestName.trim(),
          'guest_email': guestEmail.trim(),
          'guest_phone': guestPhone.trim(),
          'nights': draft.nights,
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
