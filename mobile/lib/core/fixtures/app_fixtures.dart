class FixtureWorker {
  final String id;
  final String name;
  final String profession;
  final String imageUrl;
  final double rating;
  final int reviews;
  final double distanceKm;
  final String priceRange;
  final String startingPrice;
  final int experienceYears;
  final int jobsDone;
  final String availability;
  final String badge;
  final bool verified;
  final List<String> skills;
  final String about;
  final String responseTime;
  final List<String> languages;

  const FixtureWorker({
    required this.id,
    required this.name,
    required this.profession,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.distanceKm,
    required this.priceRange,
    required this.startingPrice,
    required this.experienceYears,
    required this.jobsDone,
    required this.availability,
    required this.badge,
    this.verified = true,
    this.skills = const [],
    this.about = '',
    this.responseTime = '2 mins',
    this.languages = const ['Hindi', 'English'],
  });
}

class FixtureService {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final IconKey icon;
  final double rating;
  final int reviews;
  final String startingPrice;
  final bool verified;

  const FixtureService({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.icon,
    required this.rating,
    required this.reviews,
    required this.startingPrice,
    this.verified = true,
  });
}

class FixtureSavedJob {
  final String id;
  final String title;
  final String location;
  final String postedAgo;
  final String budget;
  final int applications;
  final bool urgent;
  final ColorKey color;

  const FixtureSavedJob({
    required this.id,
    required this.title,
    required this.location,
    required this.postedAgo,
    required this.budget,
    required this.applications,
    this.urgent = false,
    this.color = ColorKey.purple,
  });
}

enum IconKey { electrical, plumbing, painting, cleaning, tutor, driver, shop, briefcase, ac, salon }
enum ColorKey { purple, blue, orange, green }

class AppFixtures {
  static const categories = [
    ('Electrician', IconKey.electrical),
    ('Plumbing', IconKey.plumbing),
    ('Cleaning', IconKey.cleaning),
    ('Painting', IconKey.painting),
    ('AC Repair', IconKey.ac),
    ('Salon', IconKey.salon),
    ('Tutors', IconKey.tutor),
    ('More', IconKey.shop),
  ];

  static const popularSearches = [
    'Electrician', 'Plumber', 'Painter', 'House Cleaning', 'Driver', 'Tutor',
  ];

  static const workers = [
    FixtureWorker(
      id: 'w1',
      name: 'Om Electricals',
      profession: 'Electrician',
      imageUrl: 'https://images.unsplash.com/photo-1621905251918-48416bd8575a?w=600',
      rating: 4.8,
      reviews: 128,
      distanceKm: 2.3,
      priceRange: '₹250 - ₹400 / hr',
      startingPrice: '₹250',
      experienceYears: 15,
      jobsDone: 512,
      availability: 'Available Now',
      badge: 'VERIFIED',
      skills: ['Wiring', 'Repairs', 'Installation', 'MCB / DB', 'Fan / Light', 'AC Wiring'],
      about: 'Professional electrician with 15+ years of experience in home wiring, repairs, and installations across Patna.',
      languages: ['Hindi', 'English', 'Bhojpuri'],
    ),
    FixtureWorker(
      id: 'w2',
      name: 'Ravi Kumar',
      profession: 'Electrician',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600',
      rating: 4.7,
      reviews: 96,
      distanceKm: 2.6,
      priceRange: '₹200 - ₹350 / hr',
      startingPrice: '₹200',
      experienceYears: 10,
      jobsDone: 340,
      availability: 'Available Today, 10:00 AM',
      badge: 'VERIFIED',
      skills: ['Wiring', 'Repairs', 'Installation'],
      about: 'Reliable electrician for homes and small shops in Patna.',
    ),
    FixtureWorker(
      id: 'w3',
      name: 'Shakti Electrical Services',
      profession: 'Electrician',
      imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=600',
      rating: 4.6,
      reviews: 74,
      distanceKm: 1.8,
      priceRange: '₹300 - ₹450 / hr',
      startingPrice: '₹300',
      experienceYears: 8,
      jobsDone: 280,
      availability: 'Available Now',
      badge: 'TOP RATED',
      skills: ['Wiring', 'Repairs', 'Fan / Light'],
      about: 'Top rated electrical services with quick response time.',
    ),
    FixtureWorker(
      id: 'w4',
      name: 'Aman Electrician',
      profession: 'Electrician',
      imageUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=600',
      rating: 4.7,
      reviews: 82,
      distanceKm: 2.6,
      priceRange: '₹200 - ₹350 / hr',
      startingPrice: '₹200',
      experienceYears: 10,
      jobsDone: 410,
      availability: 'Available Today, 10:00 AM',
      badge: 'VERIFIED',
    ),
  ];

  static const services = [
    FixtureService(
      id: 's1',
      title: 'Electrical Services',
      subtitle: 'Wiring, repairs, installation & more',
      imageUrl: 'https://images.unsplash.com/photo-1621905252507-b5822a883b08?w=600',
      icon: IconKey.electrical,
      rating: 4.8,
      reviews: 128,
      startingPrice: '₹250',
    ),
    FixtureService(
      id: 's2',
      title: 'Plumbing Services',
      subtitle: 'Leak repair, pipe fitting, bathroom work',
      imageUrl: 'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=600',
      icon: IconKey.plumbing,
      rating: 4.7,
      reviews: 96,
      startingPrice: '₹300',
    ),
    FixtureService(
      id: 's3',
      title: 'House Painting',
      subtitle: 'Interior & exterior painting',
      imageUrl: 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=600',
      icon: IconKey.painting,
      rating: 4.6,
      reviews: 64,
      startingPrice: '₹500',
    ),
  ];

  static const savedJobs = [
    FixtureSavedJob(
      id: 'j1',
      title: 'Need Electrician for Home Wiring',
      location: 'Patna, Bihar',
      postedAgo: 'Posted 2 days ago',
      budget: '₹2,000 - ₹3,000',
      applications: 5,
      urgent: true,
      color: ColorKey.purple,
    ),
    FixtureSavedJob(
      id: 'j2',
      title: 'Plumber Required for Bathroom Repair',
      location: 'Patna, Bihar',
      postedAgo: 'Posted 1 day ago',
      budget: '₹800 - ₹1,200',
      applications: 3,
      color: ColorKey.blue,
    ),
    FixtureSavedJob(
      id: 'j3',
      title: 'House Painting - 2 BHK',
      location: 'Patna, Bihar',
      postedAgo: 'Posted 3 days ago',
      budget: '₹5,000 - ₹8,000',
      applications: 8,
      color: ColorKey.orange,
    ),
  ];

  static FixtureWorker? workerById(String id) {
    for (final w in workers) {
      if (w.id == id) return w;
    }
    return null;
  }

  static String jobImageFor(String category, {String? title}) {
    final text = '${category.toLowerCase()} ${title?.toLowerCase() ?? ''}';
    if (text.contains('electric') || text.contains('fan') || text.contains('switch')) {
      return 'https://images.unsplash.com/photo-1621905251918-48416bd8575a?w=900';
    }
    if (text.contains('plumb') || text.contains('pipe') || text.contains('bathroom')) {
      return 'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=900';
    }
    if (text.contains('paint')) {
      return 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=900';
    }
    if (text.contains('deliver') || text.contains('driver')) {
      return 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=900';
    }
    if (text.contains('clean')) {
      return 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=900';
    }
    if (text.contains('cook') || text.contains('hotel') || text.contains('restaurant')) {
      return 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=900';
    }
    if (text.contains('shop') || text.contains('helper') || text.contains('load')) {
      return 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=900';
    }
    return 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=900';
  }

  static List<String> jobGalleryFor(String category, {String? title}) {
    final hero = jobImageFor(category, title: title);
    return [
      hero,
      'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=600',
      'https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=600',
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600',
    ];
  }

  static const workerGallery = [
    'https://images.unsplash.com/photo-1621905252507-b5822a883b08?w=600',
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600',
    'https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=600',
    'https://images.unsplash.com/photo-1621905251918-48416bd8575a?w=600',
    'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=600',
  ];

  static const profileCover = 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1200';
}
