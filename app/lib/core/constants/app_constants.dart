class AppConstants {
  static const String appName = 'EduConnect';
  static const String appVersion = '1.0.0';
  static const String baseUrl = 'https://finalbackendd.onrender.com/api';
  
  // API Endpoints
  static const String authEndpoint = '/auth';
  static const String studentsEndpoint = '/students';
  static const String professorsEndpoint = '/professors';
  static const String alumniEndpoint = '/alumni';
  static const String managementEndpoint = '/management';
  static const String assessmentsEndpoint = '/assessments';
  static const String tasksEndpoint = '/tasks';
  static const String chatEndpoint = '/chat';
  static const String eventsEndpoint = '/api/events';
  static const String jobsEndpoint = '/jobs';
  static const String resumesEndpoint = '/resumes';
  static const String connectionsEndpoint = '/connections';
  static const String activitiesEndpoint = '/activities';
  static const String notificationsEndpoint = '/notifications';
  
  // Storage Keys
  static const String tokenKey = 'token';
  static const String userKey = 'user';
  static const String submittedAssessmentsKey = 'submittedAssessments';
  
  // User Roles
  static const String studentRole = 'STUDENT';
  static const String professorRole = 'PROFESSOR';
  static const String alumniRole = 'ALUMNI';
  static const String managementRole = 'MANAGEMENT';
  
  // Assessment Status
  static const String assessmentPending = 'PENDING';
  static const String assessmentInProgress = 'IN_PROGRESS';
  static const String assessmentCompleted = 'COMPLETED';
  static const String assessmentOverdue = 'OVERDUE';
  
  // Connection Status
  static const String connectionPending = 'PENDING';
  static const String connectionAccepted = 'ACCEPTED';
  static const String connectionRejected = 'REJECTED';
  
  // Event Status
  static const String eventUpcoming = 'UPCOMING';
  static const String eventActive = 'ACTIVE';
  static const String eventCompleted = 'COMPLETED';
  
  // Job Types
  static const String fullTime = 'FULL_TIME';
  static const String partTime = 'PART_TIME';
  static const String internship = 'INTERNSHIP';
  static const String contract = 'CONTRACT';
  
  // Attendance Status
  static const String present = 'PRESENT';
  static const String absent = 'ABSENT';
  static const String late = 'LATE';
  static const String excused = 'EXCUSED';
  
  // Notification Types
  static const String eventApproved = 'EVENT_APPROVED';
  static const String eventRejected = 'EVENT_REJECTED';
  static const String eventUpcomingNotif = 'EVENT_UPCOMING';
  static const String connectionRequest = 'CONNECTION_REQUEST';
  static const String connectionAcceptedNotif = 'CONNECTION_ACCEPTED';
  static const String jobPost = 'JOB_POST';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedFileTypes = ['pdf', 'doc', 'docx'];
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int maxBioLength = 500;
  static const int maxMessageLength = 1000;
  
  // College specific
  static const String collegeEmailDomain = '@stjosephstechnology.ac.in';
  static const List<String> departments = [
    'Computer Science Engineering',
    'Information Technology',
    'Electronics and Communication',
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical Engineering',
  ];
  
  static const List<String> classes = ['I', 'II', 'III', 'IV'];
  static const List<String> batches = ['A', 'B', 'C'];
  static const List<String> graduationYears = ['2018', '2019', '2020', '2021', '2022', '2023', '2024'];
}