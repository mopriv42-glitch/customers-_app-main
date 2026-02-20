class TeacherModel {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? bio;
  final double? rating;
  final int? totalLessons;
  final int? totalStudents;
  final List<String>? subjects;
  final List<String>? grades;
  final bool? isOnline;
  final String? lastSeen;
  final String? joinDate;
  final String? experience;
  final String? education;
  final String? matrixRoomId;
  final List<String>? specializations;

  TeacherModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.avatar,
    this.bio,
    this.rating,
    this.totalLessons,
    this.totalStudents,
    this.subjects,
    this.grades,
    this.isOnline,
    this.lastSeen,
    this.joinDate,
    this.experience,
    this.matrixRoomId,
    this.education,
    this.specializations,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      bio: json['bio'],
      rating: json['rating']?.toDouble(),
      totalLessons: json['total_lessons'],
      totalStudents: json['total_students'],
      subjects:
          json['subjects'] != null ? List<String>.from(json['subjects']) : null,
      grades: json['grades'] != null ? List<String>.from(json['grades']) : null,
      isOnline: json['is_online'],
      lastSeen: json['last_seen'],
      joinDate: json['join_date'],
      experience: json['experience'],
      education: json['education'],
      matrixRoomId: json['matrix_room_id'],
      specializations: json['specializations'] != null
          ? List<String>.from(json['specializations'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'bio': bio,
      'rating': rating,
      'total_lessons': totalLessons,
      'total_students': totalStudents,
      'subjects': subjects,
      'grades': grades,
      'is_online': isOnline,
      'last_seen': lastSeen,
      'join_date': joinDate,
      'experience': experience,
      'education': education,
      'specializations': specializations,
    };
  }

  // Sample data for demonstration
  static List<TeacherModel> getSampleTeachers() {
    return [
      TeacherModel(
        id: 1,
        name: 'أحمد محمد',
        email: 'ahmed@example.com',
        phone: '+965123456789',
        avatar: null,
        bio: 'مدرس رياضيات بخبرة 5 سنوات، متخصص في المرحلة الثانوية',
        rating: 4.8,
        totalLessons: 150,
        totalStudents: 45,
        subjects: ['الرياضيات', 'الفيزياء'],
        grades: ['الصف العاشر', 'الصف الحادي عشر', 'الصف الثاني عشر'],
        isOnline: true,
        lastSeen: 'الآن',
        joinDate: '2023-01-15',
        experience: '5 سنوات',
        education: 'بكالوريوس رياضيات',
        specializations: ['الجبر', 'الهندسة', 'التفاضل والتكامل'],
      ),
      TeacherModel(
        id: 2,
        name: 'فاطمة علي',
        email: 'fatima@example.com',
        phone: '+965987654321',
        avatar: null,
        bio: 'مدرسة لغة عربية، حاصلة على ماجستير في الأدب العربي',
        rating: 4.9,
        totalLessons: 200,
        totalStudents: 60,
        subjects: ['اللغة العربية', 'الأدب'],
        grades: ['الصف التاسع', 'الصف العاشر', 'الصف الحادي عشر'],
        isOnline: false,
        lastSeen: 'منذ ساعتين',
        joinDate: '2022-09-01',
        experience: '7 سنوات',
        education: 'ماجستير أدب عربي',
        specializations: ['النحو', 'الصرف', 'الأدب الجاهلي'],
      ),
      TeacherModel(
        id: 3,
        name: 'محمد حسن',
        email: 'mohammed@example.com',
        phone: '+965555666777',
        avatar: null,
        bio: 'مدرس كيمياء، متخصص في الكيمياء العضوية والتحليلية',
        rating: 4.7,
        totalLessons: 120,
        totalStudents: 35,
        subjects: ['الكيمياء', 'العلوم'],
        grades: ['الصف الحادي عشر', 'الصف الثاني عشر'],
        isOnline: true,
        lastSeen: 'الآن',
        joinDate: '2023-03-10',
        experience: '3 سنوات',
        education: 'بكالوريوس كيمياء',
        specializations: ['الكيمياء العضوية', 'الكيمياء التحليلية'],
      ),
    ];
  }
}
