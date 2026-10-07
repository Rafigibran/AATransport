class Hotel {
  final String id;
  final String name;
  final String location;
  final String image;
  final List<String> photos;
  final double price;
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
}

class Booking {
  final String id;
  final Hotel hotel;
  final String checkIn;
  final String checkOut;
  final String status; // Upcoming, Completed, Cancelled
  final double total;

  const Booking({
    required this.id,
    required this.hotel,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.total,
  });
}

class ReviewItem {
  final String name;
  final String avatar;
  final double rating;
  final String comment;
  final String date;

  const ReviewItem({
    required this.name,
    required this.avatar,
    required this.rating,
    required this.comment,
    required this.date,
  });
}
