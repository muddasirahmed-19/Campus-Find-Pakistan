// ─────────────────────────────────────────────
//  APP CONSTANTS
// ─────────────────────────────────────────────

class AppConstants {
  AppConstants._();

  static const String appName        = 'CampusFind PK';
  static const String appTagline     = 'Reuniting campus communities';
  static const String supportEmail   = 'support@campusfind.pk';
  static const String cloudinaryName   = 'lepymqne';
  static const String cloudinaryPreset = 'campusfind_unsigned';

  // Limits
  static const int maxPostImages     = 5;
  static const int maxImageSizeMB    = 5;
  static const int postExpiryDays    = 30;
  static const int handoffExpiryHours= 48;
  static const int otpExpiryMinutes  = 5;
  static const int maxRewardPKR      = 50000;
  static const int minRewardPKR      = 100;

  // Pagination
  static const int postsPerPage      = 15;
  static const int chatsPerPage      = 30;

  // OTP length
  static const int otpLength         = 6;
  static const int handoffCodeLength = 6;

  // Phone
  static const String pkPhonePrefix  = '+92';
  static const String pkFlag         = '🇵🇰';
}

// ─────────────────────────────────────────────
//  UNIVERSITY MODEL
// ─────────────────────────────────────────────
class University {
  final String id;
  final String name;
  final String shortName;
  final String emailDomain;
  final String city;
  final String province;
  final List<String> campusAreas;

  const University({
    required this.id,
    required this.name,
    required this.shortName,
    required this.emailDomain,
    required this.city,
    required this.province,
    this.campusAreas = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'shortName': shortName,
    'emailDomain': emailDomain,
    'city': city,
    'province': province,
  };
}

// ─────────────────────────────────────────────
//  UNIVERSITIES LIST
// ─────────────────────────────────────────────
class AppUniversities {
  AppUniversities._();

  static const List<University> all = [
    University(
      id: 'nust',
      name: 'National University of Sciences and Technology',
      shortName: 'NUST',
      emailDomain: 'nust.edu.pk',
      city: 'Islamabad',
      province: 'ICT',
      campusAreas: [
        'SEECS', 'SMME', 'S3H', 'SNES', 'SCME', 'CAE',
        'NIT', 'RIMMS', 'ASAB', 'IGIS', 'Admin Block',
        'Student Centre', 'Main Gate', 'Sports Complex',
        'Library', 'Hostel Block A', 'Hostel Block B',
      ],
    ),
    University(
      id: 'fast',
      name: 'FAST National University of Computer & Emerging Sciences',
      shortName: 'FAST-NUCES',
      emailDomain: 'nu.edu.pk',
      city: 'Multiple Campuses',
      province: 'Punjab / Sindh / KPK',
      campusAreas: [
        'CS Block', 'EE Block', 'Management Block', 'Library',
        'Cafeteria', 'Parking', 'Auditorium', 'Lab Block',
      ],
    ),
    University(
      id: 'comsats',
      name: 'COMSATS University Islamabad',
      shortName: 'CUI',
      emailDomain: 'comsats.edu.pk',
      city: 'Islamabad',
      province: 'ICT',
      campusAreas: [
        'Block A', 'Block B', 'Block C', 'Block D',
        'Library', 'Sports Ground', 'Cafeteria', 'Hostel',
      ],
    ),
    University(
      id: 'uet_lahore',
      name: 'University of Engineering and Technology Lahore',
      shortName: 'UET Lahore',
      emailDomain: 'uet.edu.pk',
      city: 'Lahore',
      province: 'Punjab',
      campusAreas: [
        'Civil Block', 'Mechanical Block', 'EE Block',
        'CS Block', 'Library', 'Main Lawn', 'New Campus',
        'Hostel A', 'Hostel B', 'Cafeteria',
      ],
    ),
    University(
      id: 'lums',
      name: 'Lahore University of Management Sciences',
      shortName: 'LUMS',
      emailDomain: 'lums.edu.pk',
      city: 'Lahore',
      province: 'Punjab',
      campusAreas: [
        'SDSB', 'SBASSE', 'SSH', 'SOL', 'Muneeb IT Centre',
        'LUMS Library', 'Cafeteria', 'Sports Complex',
        'Resident Block', 'PDC',
      ],
    ),
    University(
      id: 'iba',
      name: 'Institute of Business Administration',
      shortName: 'IBA Karachi',
      emailDomain: 'iba.edu.pk',
      city: 'Karachi',
      province: 'Sindh',
      campusAreas: [
        'Main Campus', 'City Campus', 'Library',
        'CS Department', 'Amphitheatre', 'Cafeteria',
        'Sports Ground',
      ],
    ),
    University(
      id: 'qau',
      name: 'Quaid-i-Azam University',
      shortName: 'QAU',
      emailDomain: 'qau.edu.pk',
      city: 'Islamabad',
      province: 'ICT',
      campusAreas: [
        'Natural Sciences', 'Social Sciences', 'Pharmacy',
        'Biological Sciences', 'Library', 'Girls Hostel',
        'Boys Hostel', 'Main Gate', 'Sports Complex',
      ],
    ),
    University(
      id: 'uok',
      name: 'University of Karachi',
      shortName: 'UoK',
      emailDomain: 'uok.edu.pk',
      city: 'Karachi',
      province: 'Sindh',
      campusAreas: [
        'Arts Faculty', 'Science Faculty', 'Commerce Faculty',
        'Law Faculty', 'Library', 'NCC Ground', 'Student Union',
      ],
    ),
    University(
      id: 'bzu',
      name: 'Bahauddin Zakariya University',
      shortName: 'BZU',
      emailDomain: 'bzu.edu.pk',
      city: 'Multan',
      province: 'Punjab',
      campusAreas: [
        'Main Campus', 'Sub Campus', 'Library',
        'Hostel', 'Sports Ground', 'Faculty Block',
      ],
    ),
    University(
      id: 'uop',
      name: 'University of Peshawar',
      shortName: 'UoP',
      emailDomain: 'uop.edu.pk',
      city: 'Peshawar',
      province: 'KPK',
      campusAreas: [
        'Arts Block', 'Science Block', 'Commerce Block',
        'Library', 'Main Gate', 'Hostel', 'Sports Ground',
      ],
    ),
    University(
      id: 'giki',
      name: 'Ghulam Ishaq Khan Institute of Engineering Sciences',
      shortName: 'GIKI',
      emailDomain: 'giki.edu.pk',
      city: 'Topi',
      province: 'KPK',
      campusAreas: [
        'Faculty of Engineering', 'Faculty of CS & IT',
        'Faculty of Management', 'Library', 'Hostel Complex',
        'Sports Ground', 'Main Cafeteria',
      ],
    ),
    University(
      id: 'au',
      name: 'Air University',
      shortName: 'AU',
      emailDomain: 'mail.au.edu.pk',
      city: 'Islamabad',
      province: 'ICT',
      campusAreas: [
        'Engineering Block', 'Management Block', 'CS Block',
        'Library', 'Cafeteria', 'Main Gate', 'Auditorium',
      ],
    ),

    // ── BUITEMS Quetta ─────────────────────────────────────────
    University(
      id: 'buitems',
      name: 'Balochistan University of Information Technology, '
            'Engineering and Management Sciences',
      shortName: 'BUITEMS',
      emailDomain: 'buitms.edu.pk',
      city: 'Quetta',
      province: 'Balochistan',
      campusAreas: [
        'IT Block', 'Engineering Block', 'Management Block',
        'Library', 'Main Gate', 'Cafeteria', 'Girls Block',
        'Boys Hostel', 'Sports Ground', 'Admin Block',
        'New Block', 'Parking Area', 'Seminar Hall',
      ],
    ),

    University(
      id: 'uob',
      name: 'University of Balochistan',
      shortName: 'UoB',
      emailDomain: 'uob.edu.pk',
      city: 'Quetta',
      province: 'Balochistan',
      campusAreas: [
        'Arts Faculty', 'Science Faculty', 'Law Faculty',
        'Library', 'Main Gate', 'Hostel', 'Sports Ground',
      ],
    ),
    University(
      id: 'muet',
      name: 'Mehran University of Engineering and Technology',
      shortName: 'MUET',
      emailDomain: 'admin.muet.edu.pk',
      city: 'Jamshoro',
      province: 'Sindh',
      campusAreas: [
        'Civil Engineering', 'Mechanical Engineering',
        'Electrical Engineering', 'CS & IT', 'Library',
        'Main Ground', 'Hostel A', 'Hostel B',
      ],
    ),
    University(
      id: 'szu',
      name: 'Szabist University',
      shortName: 'SZABIST',
      emailDomain: 'szabist.edu.pk',
      city: 'Karachi',
      province: 'Sindh',
      campusAreas: [
        'Block A', 'Block B', 'CS Lab', 'Library',
        'Rooftop Cafeteria', 'Main Entrance',
      ],
    ),
    University(
      id: 'ned',
      name: 'NED University of Engineering and Technology',
      shortName: 'NED',
      emailDomain: 'neduet.edu.pk',
      city: 'Karachi',
      province: 'Sindh',
      campusAreas: [
        'Civil Block', 'Computer Block', 'EE Block',
        'Architecture Block', 'Library', 'Sports Ground',
        'Main Gate', 'Hostel',
      ],
    ),
  ];

  static University? findById(String id) =>
      all.where((u) => u.id == id).firstOrNull;

  static List<University> byProvince(String province) =>
      all.where((u) => u.province == province).toList();

  static List<String> get provinces =>
      all.map((u) => u.province).toSet().toList()..sort();
}

// ─────────────────────────────────────────────
//  ITEM CATEGORIES
// ─────────────────────────────────────────────
class ItemCategory {
  final String id;
  final String name;
  final String icon; // emoji
  final List<String> subcategories;

  const ItemCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.subcategories = const [],
  });
}

class AppCategories {
  AppCategories._();

  static const List<ItemCategory> all = [
    ItemCategory(
      id: 'electronics',
      name: 'Electronics',
      icon: '📱',
      subcategories: [
        'Mobile Phone', 'Laptop', 'Earphones / AirPods',
        'Charger / Cable', 'Power Bank', 'Calculator',
        'USB Drive', 'Tablet', 'Smartwatch', 'Other Electronics',
      ],
    ),
    ItemCategory(
      id: 'documents',
      name: 'Documents & Cards',
      icon: '🪪',
      subcategories: [
        'Student ID Card', 'CNIC / B-Form', 'Passport',
        'Library Card', 'Fee Challan', 'Admit Card',
        'Degree / Certificate', 'Other Documents',
      ],
    ),
    ItemCategory(
      id: 'bags',
      name: 'Bags & Wallets',
      icon: '🎒',
      subcategories: [
        'Backpack', 'Handbag', 'Wallet', 'Purse',
        'Laptop Bag', 'Sports Bag', 'Other Bag',
      ],
    ),
    ItemCategory(
      id: 'books',
      name: 'Books & Stationery',
      icon: '📚',
      subcategories: [
        'Textbook', 'Notebook / Diary', 'Notes / Handouts',
        'Pen / Pencil Case', 'Calculator', 'Compass Box',
        'Other Stationery',
      ],
    ),
    ItemCategory(
      id: 'clothing',
      name: 'Clothing & Accessories',
      icon: '👕',
      subcategories: [
        'Jacket / Hoodie', 'Scarf / Dupatta', 'Uniform',
        'Cap / Hat', 'Gloves', 'Belt', 'Other Clothing',
      ],
    ),
    ItemCategory(
      id: 'keys',
      name: 'Keys',
      icon: '🔑',
      subcategories: [
        'Room / House Key', 'Bike / Car Key',
        'Locker Key', 'Key Bundle', 'Other Keys',
      ],
    ),
    ItemCategory(
      id: 'glasses',
      name: 'Glasses & Accessories',
      icon: '👓',
      subcategories: [
        'Prescription Glasses', 'Sunglasses',
        'Glasses Case', 'Contact Lens Kit',
      ],
    ),
    ItemCategory(
      id: 'sports',
      name: 'Sports Equipment',
      icon: '⚽',
      subcategories: [
        'Cricket Bat / Ball', 'Football', 'Badminton Racket',
        'Water Bottle', 'Sports Shoes', 'Other Sports',
      ],
    ),
    ItemCategory(
      id: 'jewelry',
      name: 'Jewelry & Watches',
      icon: '⌚',
      subcategories: [
        'Watch', 'Ring', 'Necklace',
        'Earrings', 'Bracelet', 'Other Jewelry',
      ],
    ),
    ItemCategory(
      id: 'other',
      name: 'Other',
      icon: '📦',
      subcategories: ['Miscellaneous'],
    ),
  ];

  static ItemCategory? findById(String id) =>
      all.where((c) => c.id == id).firstOrNull;
}

// ─────────────────────────────────────────────
//  POST STATUS ENUM
// ─────────────────────────────────────────────
enum PostStatus {
  active,
  claimPending,
  claimApproved,
  handoffPending,
  resolved,
  expired,
  removed,
  reported;

  String get label {
    switch (this) {
      case PostStatus.active:         return 'Active';
      case PostStatus.claimPending:   return 'Claim Pending';
      case PostStatus.claimApproved:  return 'Claim Approved';
      case PostStatus.handoffPending: return 'Handoff Pending';
      case PostStatus.resolved:       return 'Resolved ✅';
      case PostStatus.expired:        return 'Expired';
      case PostStatus.removed:        return 'Removed';
      case PostStatus.reported:       return 'Under Review';
    }
  }

  String get firestoreValue => name;

  static PostStatus fromString(String val) =>
      PostStatus.values.firstWhere(
        (s) => s.name == val,
        orElse: () => PostStatus.active,
      );
}

// ─────────────────────────────────────────────
//  CLAIM STATUS ENUM
// ─────────────────────────────────────────────
enum ClaimStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case ClaimStatus.pending:  return 'Pending Review';
      case ClaimStatus.approved: return 'Approved';
      case ClaimStatus.rejected: return 'Rejected';
    }
  }

  static ClaimStatus fromString(String val) =>
      ClaimStatus.values.firstWhere(
        (s) => s.name == val,
        orElse: () => ClaimStatus.pending,
      );
}

// ─────────────────────────────────────────────
//  USER ROLE ENUM
// ─────────────────────────────────────────────
enum UserRole {
  student,
  moderator,
  admin;

  static UserRole fromString(String val) =>
      UserRole.values.firstWhere(
        (r) => r.name == val,
        orElse: () => UserRole.student,
      );
}

// ─────────────────────────────────────────────
//  POST TYPE ENUM
// ─────────────────────────────────────────────
enum PostType {
  lost,
  found;

  String get label => name == 'lost' ? 'Lost' : 'Found';
}

// ─────────────────────────────────────────────
//  CONTACT PREFERENCE ENUM
// ─────────────────────────────────────────────
enum ContactPreference {
  inApp,
  whatsapp,
  call;

  String get label {
    switch (this) {
      case ContactPreference.inApp:    return 'In-App Chat';
      case ContactPreference.whatsapp: return 'WhatsApp';
      case ContactPreference.call:     return 'Phone Call';
    }
  }

  String get icon {
    switch (this) {
      case ContactPreference.inApp:    return '💬';
      case ContactPreference.whatsapp: return '📲';
      case ContactPreference.call:     return '📞';
    }
  }
}

// ─────────────────────────────────────────────
//  FIRESTORE COLLECTION NAMES
// ─────────────────────────────────────────────
class FirestoreCollections {
  FirestoreCollections._();

  static const String users       = 'users';
  static const String posts       = 'posts';
  static const String claims      = 'claims';
  static const String handoffs    = 'handoffs';
  static const String chats       = 'chats';
  static const String messages    = 'messages';
  static const String ratings     = 'ratings';
  static const String reports     = 'reports';
  static const String universities= 'universities';
  static const String notifications = 'notifications';
}

// ─────────────────────────────────────────────
//  ROUTE NAMES
// ─────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const String splash       = '/';
  static const String onboarding   = '/onboarding';
  static const String phoneAuth    = '/auth/phone';
  static const String otpVerify    = '/auth/otp';
  static const String emailSignup  = '/auth/email';
  static const String idUpload     = '/auth/id-upload';
  static const String verifyPending= '/auth/pending';
  static const String home         = '/home';
  static const String search       = '/search';
  static const String postDetail   = '/post/:id';
  static const String createPost   = '/post/create';
  static const String myPosts      = '/my-posts';
  static const String claims       = '/claims';
  static const String handoff      = '/handoff/:id';
  static const String chat         = '/chat/:id';
  static const String notifications= '/notifications';
  static const String profile      = '/profile';
  static const String settings     = '/settings';
  static const String adminPanel   = '/admin';
}
