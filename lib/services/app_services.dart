import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_strings.dart';
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

class SettingsService {
  static AppSettings? _cache;

  /// Loads admin-controlled pricing settings. Any failure intentionally
  /// falls back to 0% tax/fee so a backend migration that has not run yet
  /// cannot resurrect the removed hard-coded charge.
  static Future<AppSettings> fetchSettings({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;
    try {
      final row = await _db
          .from('app_settings')
          .select('tax_percent, fee_percent')
          .eq('id', 1)
          .maybeSingle();
      _cache = row == null ? const AppSettings() : AppSettings.fromMap(row);
    } catch (_) {
      _cache = const AppSettings();
    }
    return _cache!;
  }
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
      if (h is Map<String, dynamic>) {
        cars.add(Car.fromMap(h, isFavourite: true));
      }
    }
    return cars;
  }

  static Future<bool> toggleFavourite(Car car) async {
    final uid = currentUserId;
    if (uid == null) throw Exception(tr('common_login_first'));
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
        .select('*')
        .eq('car_id', carId)
        .order('created_at', ascending: false);
    final mutableRows = rows.map((r) => Map<String, dynamic>.from(r)).toList();

    // profiles are private under RLS. Reviewer names/avatars are exposed only
    // through reviewer_profiles (migration 006), restricted to people who
    // actually wrote a review. If that migration has not run yet, reviews
    // still render with a generic customer name instead of failing.
    try {
      final userIds = mutableRows
          .map((r) => r['user_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      if (userIds.isNotEmpty) {
        final profiles = await _db
            .from('reviewer_profiles')
            .select('id, full_name, avatar_url')
            .inFilter('id', userIds);
        final profileById = <String, Map<String, dynamic>>{
          for (final p in profiles) p['id'].toString(): p,
        };
        for (final row in mutableRows) {
          final profile = profileById[row['user_id']?.toString()];
          if (profile != null) row['profiles'] = profile;
        }
      }
    } catch (_) {
      // Keep the review list usable before migration 006 is deployed.
    }
    return mutableRows.map(ReviewItem.fromMap).toList();
  }

  static Future<void> addReview(
      {required String carId,
      String? bookingId,
      required int rating,
      required String comment}) async {
    final uid = currentUserId;
    if (uid == null) throw Exception(tr('common_login_first'));
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

  /// Server-enforced when RPC `create_booking_secure` exists (migration 006);
  /// this pre-check only improves the message shown before submitting.
  static Future<int> availableUnits(
      {required String carId,
      required DateTime pickupDate,
      required DateTime returnDate,
      required int totalUnits}) async {
    try {
      final result = await _db.rpc('car_available_units', params: {
        'p_car_id': carId,
        'p_pickup_date': pickupDate.toIso8601String().substring(0, 10),
        'p_return_date': returnDate.toIso8601String().substring(0, 10),
      });
      if (result is num) return result.toInt();
      if (result is List && result.isNotEmpty && result.first is num) {
        return (result.first as num).toInt();
      }
    } catch (_) {
      // Migration 006 may not be deployed yet. The secure booking RPC (or the
      // legacy insert fallback) remains the final authority.
    }
    return totalUnits;
  }

  static Future<Booking> createBooking(BookingDraft draft,
      {required String customerName,
      required String customerEmail,
      required String customerPhone}) async {
    final uid = currentUserId;
    if (uid == null) throw Exception(tr('common_login_first'));
    final payload = <String, dynamic>{
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
      'fee': draft.fee,
      'tax_percent': draft.settings.taxPercent,
      'fee_percent': draft.settings.feePercent,
      'total': draft.total,
      'payment_method_code': draft.paymentMethodCode,
    };
    try {
      // Preferred path: the database recomputes price/tax/fee from the car and
      // app_settings and rejects unavailable dates. This prevents a modified
      // client from inventing a total or marking its own booking as paid.
      final rpcResult = await _db.rpc('create_booking_secure', params: {
        'p_car_id': draft.car.id,
        'p_pickup_date': draft.pickupDate.toIso8601String().substring(0, 10),
        'p_return_date': draft.returnDate.toIso8601String().substring(0, 10),
        'p_passengers': draft.passengers,
        'p_units': draft.units,
        'p_service_type': draft.serviceType,
        'p_customer_name': customerName.trim(),
        'p_customer_email': customerEmail.trim(),
        'p_customer_phone': customerPhone.trim(),
        'p_payment_method_code': draft.paymentMethodCode,
      });
      final rpcRow = rpcResult is List && rpcResult.isNotEmpty
          ? rpcResult.first
          : rpcResult;
      if (rpcRow is Map<String, dynamic>) {
        final full = await _db
            .from('bookings')
            .select(_bookingColumns)
            .eq('id', rpcRow['id'].toString())
            .single();
        return Booking.fromMap(full);
      }
      if (rpcRow is Map) {
        final full = await _db
            .from('bookings')
            .select(_bookingColumns)
            .eq('id', rpcRow['id'].toString())
            .single();
        return Booking.fromMap(full);
      }
      throw Exception(tr('svc_booking_invalid'));
    } on PostgrestException catch (rpcError) {
      // Before migration 006 is applied, rpc() returns PGRST202/function not
      // found. Fall through to the original insert so an existing deployment
      // keeps working during the upgrade window. Other RPC errors (notably
      // availability) are real business errors and must be shown to the user.
      final rpcMessage = '${rpcError.code} ${rpcError.message}'.toLowerCase();
      final rpcMissing = rpcMessage.contains('pgrst202') ||
          rpcMessage.contains('create_booking_secure') &&
              (rpcMessage.contains('could not find') ||
                  rpcMessage.contains('does not exist'));
      if (!rpcMissing) throw Exception(rpcError.message);
    }

    try {
      final row =
          await _db.from('bookings').insert(payload).select(_bookingColumns).single();
      return Booking.fromMap(row);
    } on PostgrestException catch (e) {
      // Compatibility while migration 005 has not been applied yet. The new
      // pricing columns are optional snapshots; the core booking must still
      // succeed against the original schema.
      final message = '${e.code} ${e.message}'.toLowerCase();
      if (!message.contains('fee') && !message.contains('tax_percent')) {
        rethrow;
      }
      final legacyPayload = Map<String, dynamic>.from(payload)
        ..remove('fee')
        ..remove('tax_percent')
        ..remove('fee_percent');
      final row = await _db
          .from('bookings')
          .insert(legacyPayload)
          .select(_bookingColumns)
          .single();
      return Booking.fromMap(row);
    }
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
    if (uid == null) throw Exception(tr('common_login_first'));
    await _db.from('profiles').update(
        {'full_name': name.trim(), 'phone': phone?.trim()}).eq('id', uid);
    await _db.auth.updateUser(UserAttributes(data: {'full_name': name.trim()}));
  }

}
