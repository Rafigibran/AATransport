import '../models/hotel.dart';

class MockData {
  static const hotels = <Hotel>[
    Hotel(
      id: '1',
      name: 'Elysium Gardens',
      location: 'California, USA',
      image:
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=900&q=80',
      photos: [
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=900&q=80',
        'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=900&q=80',
        'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=900&q=80',
        'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=900&q=80',
      ],
      price: 1500,
      rating: 4.5,
      reviews: 1204,
      description:
          'Elysium Gardens is a luxury hotel located in the heart of California. '
          'Enjoy premium rooms, a relaxing pool, spa, and world-class dining. '
          'Perfect for family vacation, business trip, or a romantic getaway with modern facilities and warm hospitality.',
      facilities: ['Free Wifi', 'Restaurant', 'Pool', 'Gym', 'Spa', 'Parking'],
      isFavourite: true,
    ),
    Hotel(
      id: '2',
      name: 'Nexon Suites',
      location: 'California, USA',
      image:
          'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=900&q=80',
      photos: [
        'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=900&q=80',
        'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=900&q=80',
      ],
      price: 500,
      rating: 4.3,
      reviews: 842,
      description:
          'Modern suites with city view, comfortable beds, and easy access to downtown attractions.',
      facilities: ['Free Wifi', 'Pool', 'Gym', 'Parking'],
    ),
    Hotel(
      id: '3',
      name: 'Solara Springs',
      location: 'Florida, USA',
      image:
          'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=900&q=80',
      photos: [
        'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=900&q=80',
        'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=900&q=80',
      ],
      price: 349.7,
      rating: 4.6,
      reviews: 673,
      description:
          'Relax and enjoy your trip with tropical vibes, outdoor pool, and beach access.',
      facilities: ['Free Wifi', 'Beach', 'Pool', 'Restaurant'],
      isFavourite: true,
    ),
    Hotel(
      id: '4',
      name: 'Horizon Crest',
      location: 'New York, USA',
      image:
          'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=900&q=80',
      photos: [
        'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=900&q=80',
      ],
      price: 1100,
      rating: 4.4,
      reviews: 519,
      description:
          'Elegant hotel in the city center with premium service and spacious rooms.',
      facilities: ['Free Wifi', 'Restaurant', 'Gym', 'Spa'],
    ),
    Hotel(
      id: '5',
      name: 'Ventura Vista',
      location: 'Texas, USA',
      image:
          'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=900&q=80',
      photos: [
        'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=900&q=80',
      ],
      price: 600,
      rating: 4.2,
      reviews: 311,
      description:
          'Comfortable stay with ocean breeze, family rooms, and delicious breakfast.',
      facilities: ['Free Wifi', 'Pool', 'Parking'],
    ),
    Hotel(
      id: '6',
      name: 'Peakview Inn',
      location: 'Colorado, USA',
      image:
          'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=900&q=80',
      photos: [
        'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=900&q=80',
      ],
      price: 700,
      rating: 4.7,
      reviews: 928,
      description:
          'Mountain view inn, cozy atmosphere, perfect for healing and staycation.',
      facilities: ['Free Wifi', 'Spa', 'Restaurant', 'Parking'],
    ),
  ];

  static const reviews = <ReviewItem>[
    ReviewItem(
      name: 'Robert Kelvin',
      avatar: 'https://i.pravatar.cc/100?img=12',
      rating: 5,
      comment:
          'Very comfortable hotel, clean rooms, friendly staff. Recommended!',
      date: 'June 2025',
    ),
    ReviewItem(
      name: 'Andy Rubin',
      avatar: 'https://i.pravatar.cc/100?img=32',
      rating: 4.5,
      comment: 'Great location and facilities. Breakfast was delicious.',
      date: 'June 2025',
    ),
    ReviewItem(
      name: 'Ross Flint',
      avatar: 'https://i.pravatar.cc/100?img=56',
      rating: 4,
      comment: 'Good experience overall, pool area is amazing at sunset.',
      date: 'May 2025',
    ),
  ];

  static List<Booking> bookings() {
    return [
      Booking(
          id: 'B001',
          hotel: hotels[0],
          checkIn: '09/05/25 11:30 AM',
          checkOut: '12/05/25',
          status: 'Upcoming',
          total: 1515.18),
      Booking(
          id: 'B002',
          hotel: hotels[2],
          checkIn: '20/05/25',
          checkOut: '22/05/25',
          status: 'Upcoming',
          total: 349.7),
      Booking(
          id: 'B003',
          hotel: hotels[4],
          checkIn: '02/04/25',
          checkOut: '04/04/25',
          status: 'Completed',
          total: 600),
      Booking(
          id: 'B004',
          hotel: hotels[5],
          checkIn: '10/03/25',
          checkOut: '12/03/25',
          status: 'Completed',
          total: 700),
      Booking(
          id: 'B005',
          hotel: hotels[1],
          checkIn: '01/02/25',
          checkOut: '03/02/25',
          status: 'Cancelled',
          total: 500),
    ];
  }
}
