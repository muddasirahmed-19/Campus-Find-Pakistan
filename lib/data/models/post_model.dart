import '../../core/constants/app_constants.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String universityShortName;
  final PostType type;
  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final List<String> imageUrls;
  final String campusArea;
  final DateTime dateLostFound;
  final PostStatus status;
  final int? rewardAmount;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.universityShortName,
    required this.type,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.imageUrls,
    required this.campusArea,
    required this.dateLostFound,
    required this.status,
    this.rewardAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'userName': userName,
    'universityShortName': universityShortName,
    'type': type.name, 'title': title, 'description': description,
    'categoryId': categoryId, 'categoryName': categoryName,
    'categoryIcon': categoryIcon, 'imageUrls': imageUrls,
    'campusArea': campusArea,
    'dateLostFound': dateLostFound.toIso8601String(),
    'status': status.firestoreValue,
    'rewardAmount': rewardAmount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PostModel.fromMap(Map<String, dynamic> map) => PostModel(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    userName: map['userName'] ?? 'Unknown',
    universityShortName: map['universityShortName'] ?? '',
    type: map['type'] == 'lost' ? PostType.lost : PostType.found,
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    categoryId: map['categoryId'] ?? 'other',
    categoryName: map['categoryName'] ?? 'Other',
    categoryIcon: map['categoryIcon'] ?? '📦',
    imageUrls: List<String>.from(map['imageUrls'] ?? []),
    campusArea: map['campusArea'] ?? '',
    dateLostFound: DateTime.tryParse(map['dateLostFound'] ?? '') ?? DateTime.now(),
    status: PostStatus.fromString(map['status'] ?? 'active'),
    rewardAmount: map['rewardAmount'],
    createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
  );
}