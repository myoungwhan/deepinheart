import 'package:deepinheart/Controller/Model/feature_model.dart';
import 'package:deepinheart/Controller/Model/freq_question_model.dart';
import 'package:deepinheart/Controller/Model/service_category_model.dart';
import 'package:deepinheart/Controller/Model/sub_category_model.dart';
import 'package:deepinheart/Controller/Model/counselor_model.dart';
import 'package:deepinheart/Controller/Model/faq_and_reviews_model.dart';
import 'package:deepinheart/Controller/Model/counselor_reviews_model.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

enum enumServiceSection { Fortune, Counseling }

enum enumServiceStatus { Pending, Confirmed, Declined, InProgress, Completed }

class ServiceProvider extends ChangeNotifier {
  final userViewModel = navigatorKey.currentContext!.read<UserViewModel>();

  // Counselor data
  List<CounselorData> counselorsFortune = [];
  List<CounselorData> counselorsCounseling = [];
  List<CounselorData> topcounselorsFortune = [];
  List<CounselorData> topcounselorsCounseling = [];

  // Popular advisors
  List<CounselorData> popularAdvisorsFortune = [];
  List<CounselorData> popularAdvisorsCounseling = [];

  bool isLoadingCounselors = false;
  String? counselorError;

  // Make these static so they can be used in field initializers:
  static final List<FreqQuestionModel> listQuestionFortunes = [
    FreqQuestionModel(
      qestion: 'How accurate is tarot counseling?',
      ans:
          'The accuracy of the tarot counseling depends on the experience and expertise of the counselor, but the proven Tarot masters of our platform show an average of more than 90% accuracy.',
    ),
    FreqQuestionModel(
      qestion: 'Can I ask follow-up questions?',
      ans:
          'Yes, you can ask as many follow-up questions as needed within your session time.',
    ),
    FreqQuestionModel(
      qestion: 'Do I need prior knowledge?',
      ans:
          'No prior experience is needed—our counselors guide you through each step of the process.',
    ),
  ];
  static final List<FreqQuestionModel> listQuestionCounselings = [
    FreqQuestionModel(
      qestion: 'Is my consultation kept confidential?',
      ans:
          'Yes, all counseling sessions are fully encrypted and none of your personal information is shared without your explicit consent.',
    ),
    FreqQuestionModel(
      qestion: 'How soon will I get a response?',
      ans:
          'You will receive an initial response within 24 hours, and many issues are addressed in the same day.',
    ),
    FreqQuestionModel(
      qestion: 'What qualifications do counselors have?',
      ans:
          'All of our counselors are certified professionals with at least 5 years of clinical experience.',
    ),
  ];

  static final List<FeatureModel> fortuneFeatures = [
    FeatureModel(
      id: 0,
      categoryId: 0,
      title: 'Interpretation Through Spiritual Connection',
      text:
          'Intuitively understand the essence of current situations and problems through spiritual connections.',
      image: null,
    ),
    FeatureModel(
      id: 0,
      categoryId: 0,
      title: 'Immediate Problem-Solving Direction',
      text:
          'It gives fast and clear answers to specific questions and presents realistic advice and solutions.',
      image: null,
    ),
    FeatureModel(
      id: 0,
      categoryId: 0,
      title: 'Analysis of Influence of Ancestors and Energy',
      text:
          'We talk about the energy of our ancestors and the impact of karma on their current life.',
      image: null,
    ),
    FeatureModel(
      id: 0,
      categoryId: 0,
      title: 'Proposals for Good and Slander',
      text:
          'Specific methods of behavior, such as good prayers and amulets to solve the problem, are also proposed.',
      image: null,
    ),
  ];

  static final List<FeatureModel> counselingFeatures = [
    FeatureModel(
      id: 0,
      categoryId: 0,
      title: 'Professional Analysis',
      text: 'Accurate psychology analysis by proven experts.',
      image: null,
    ),
    FeatureModel(
      id: 0,
      categoryId: 0,
      title: 'Thorough Secret Guarantee',
      text: 'All consultations are 100% secret and confidential.',
      image: null,
    ),
    FeatureModel(
      id: 0,
      categoryId: 0,
      title: 'Rapid Feedback',
      text: 'We provide quick results after each session.',
      image: null,
    ),
    FeatureModel(
      id: 0,
      categoryId: 0,
      title: 'Custom Solution',
      text: 'Offer personalized solutions for each individual.',
      image: null,
    ),
  ];
  static final List<FeatureModel> PsycologycounselingFeatures = [
    FeatureModel(
      id: 0,
      categoryId: 0,
      title: 'Confidentiality',
      text: 'All counseling sessions are strictly confidential.',
      image: null,
    ),
    FeatureModel(
      id: 0,
      categoryId: 0,
      title: 'Verified Experts',
      text: 'Only certified professionals who pass strict screening.',
      image: null,
    ),
    FeatureModel(
      id: 0,
      categoryId: 0,
      title: '24/7 Support',
      text: 'Get counseling whenever you need it.',
      image: null,
    ),
    FeatureModel(
      id: 0,
      categoryId: 0,
      title: 'Safe Space',
      text: 'Access a secure and comfortable counseling environment.',
      image: null,
    ),
  ];

  // Fortune Categories
  final List<ServiceCategoryModel> listFortuneCategories = [
    ServiceCategoryModel(
      title: 'Tarot',
      img: 'images/Tarot.png',
      description:
          'Let us read your destiny. Understand your life\'s flow and prepare for the future through fortune telling. Our expert consultants will help solve your concerns.',
      subCategories: [
        SubCategoryModel(title: 'Love', color: '#C93C23'),
        SubCategoryModel(title: 'Today', color: '#268C2A'),
        SubCategoryModel(title: 'Wealth', color: '#3A1E88'),
        SubCategoryModel(title: 'Career', color: '#B78B00'),
      ],
      features: ServiceProvider.fortuneFeatures,
      questions: ServiceProvider.listQuestionFortunes,
    ),
    ServiceCategoryModel(
      title: 'Saju',
      img: 'images/Saju.png',
      description:
          'Saju (Four Pillars of Destiny) tells you your fate based on your birth year, month, day, and time.',
      subCategories: [
        SubCategoryModel(title: 'Career', color: '#7F4A56'),
        SubCategoryModel(title: 'Love', color: '#A5A5A5'),
        SubCategoryModel(title: 'Health', color: '#C77D19'),
        SubCategoryModel(title: 'Destiny', color: '#9E0030'),
      ],
      features: ServiceProvider.fortuneFeatures,
      questions: ServiceProvider.listQuestionFortunes,
    ),
    ServiceCategoryModel(
      title: 'Divine',
      img: 'images/Divine.png',
      description:
          'Divine readings include Tarot, Palmistry, and other spiritual practices to reveal deeper insights into your life.',
      subCategories: [
        SubCategoryModel(title: 'Tarot', color: '#7B1F6A'),
        SubCategoryModel(title: 'Palmistry', color: '#008C76'),
        SubCategoryModel(title: 'Crystal Ball', color: '#E17300'),
        SubCategoryModel(title: 'Numerology', color: '#388E3C'),
      ],
      features: ServiceProvider.fortuneFeatures,
      questions: ServiceProvider.listQuestionFortunes,
    ),
  ];

  // Counseling Categories
  final List<ServiceCategoryModel> listCounselingCategories = [
    ServiceCategoryModel(
      title: 'Psychological Test',
      img: 'images/Psychological.png',
      description:
          'Assess your mental health through various psychological tests including anxiety, depression, and stress tests.',
      subCategories: [
        SubCategoryModel(title: 'Anxiety', color: '#D32F2F'),
        SubCategoryModel(title: 'Depression', color: '#D81B60'),
        SubCategoryModel(title: 'Stress', color: '#6A1B9A'),
        SubCategoryModel(title: 'Trauma', color: '#512DA8'),
      ],
      features: ServiceProvider.counselingFeatures,
      questions: ServiceProvider.listQuestionCounselings,
    ),
    ServiceCategoryModel(
      title: 'Counseling',
      img: 'images/Counseling.png',
      description:
          'Receive guidance on various issues including stress, anxiety, relationships, and personal growth.',
      subCategories: [
        SubCategoryModel(title: 'Stress & Anxiety', color: '#2C387E'),
        SubCategoryModel(title: 'Marriage & Couples', color: '#1565C0'),
        SubCategoryModel(title: 'Domestic Violence', color: '#388E3C'),
      ],
      features: ServiceProvider.counselingFeatures,
      questions: ServiceProvider.listQuestionCounselings,
    ),
    ServiceCategoryModel(
      title: 'Relationship',
      img: 'images/Relationship.png',
      description:
          'Guidance for your love life, including breakups, compatibility, and advice for building lasting relationships.',
      subCategories: [
        SubCategoryModel(title: 'Love', color: '#D32F2F'),
        SubCategoryModel(title: 'Breakups', color: '#5D4037'),
        SubCategoryModel(title: 'Compatibility', color: '#FF8F00'),
      ],
      features: ServiceProvider.counselingFeatures,
      questions: ServiceProvider.listQuestionCounselings,
    ),
    ServiceCategoryModel(
      title: 'Life Advice',
      img: 'images/Life Advice.png',
      description:
          'Get personalized life advice for your career, personal growth, and decision making.',
      subCategories: [
        SubCategoryModel(title: 'Career Advice', color: '#00796B'),
        SubCategoryModel(title: 'Personal Growth', color: '#558B2F'),
        SubCategoryModel(title: 'Decision Making', color: '#F57F17'),
      ],
      features: ServiceProvider.counselingFeatures,
      questions: ServiceProvider.listQuestionCounselings,
    ),
  ];

  // Fetch counselors from API
  Future<void> fetchCounselorsFroutune() async {
    try {
      isLoadingCounselors = true;
      counselorError = null;
      notifyListeners();

      // Get UserViewModel to access the token

      // Get token from UserViewModel
      String? token;
      if (userViewModel.userModel != null &&
          userViewModel.userModel!.data.token.isNotEmpty) {
        token = userViewModel.userModel!.data.token;
      } else {
        counselorError = 'No authentication token available';
        isLoadingCounselors = false;
        notifyListeners();
        return;
      }

      var headers = {'Authorization': 'Bearer $token'};

      var request = http.Request(
        'GET',
        Uri.parse(
          '${ApiEndPoints.BASE_URL}users?role=counselor&section_id=${userViewModel.texnomyData!.fortune.id}',
        ),
      );

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        var jsonData = jsonDecode(data);

        ///    print("Counselors fetched successfully: " + data.toString());

        CounselorModel counselorModel = CounselorModel.fromJson(jsonData);
        counselorsFortune = counselorModel.data;
        counselorError = null;
      } else {
        var errorData = await response.stream.bytesToString();

        counselorError = 'Failed to fetch counselors: ${response.statusCode}';
      }
    } catch (e) {
      counselorError = 'Error fetching counselors: $e';
    } finally {
      isLoadingCounselors = false;
      notifyListeners();
    }
  }

  Future<void> fetchCounselorsCounseling() async {
    try {
      isLoadingCounselors = true;
      counselorError = null;
      notifyListeners();

      // Get UserViewModel to access the token

      // Get token from UserViewModel
      String? token;
      if (userViewModel.userModel != null &&
          userViewModel.userModel!.data.token.isNotEmpty) {
        token = userViewModel.userModel!.data.token;
      } else {
        counselorError = 'No authentication token available';
        isLoadingCounselors = false;
        notifyListeners();
        return;
      }

      var headers = {'Authorization': 'Bearer $token'};

      var request = http.Request(
        'GET',
        Uri.parse(
          '${ApiEndPoints.BASE_URL}users?role=counselor&section_id=${userViewModel.texnomyData!.counseling.id}',
        ),
      );

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        var jsonData = jsonDecode(data);
        //  print("Counselors fetched successfully: " + data.toString());

        CounselorModel counselorModel = CounselorModel.fromJson(jsonData);
        counselorsCounseling = counselorModel.data;
        counselorError = null;
      } else {
        var errorData = await response.stream.bytesToString();

        counselorError = 'Failed to fetch counselors: ${response.statusCode}';
      }
    } catch (e) {
      counselorError = 'Error fetching counselors: $e';
    } finally {
      isLoadingCounselors = false;
      notifyListeners();
    }
  }

  Future<List<CounselorData>> fetchCounselorsByCategory(
    String categoryId,
  ) async {
    print("****" + categoryId);

    List<CounselorData> counselors = [];
    try {
      userViewModel.setLoading(true);

      // Make API call to fetch counselors by category
      final response = await http.get(
        Uri.parse(
          '${ApiEndPoints.BASE_URL}category-by-counselor?category_id=$categoryId',
        ),
        headers: {
          'Authorization': 'Bearer ${await userViewModel.getToken()}',
          'Accept': 'application/json',
        },
      );
      //request print
      print('Request: ${response.request?.url}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Counselors by category API Response: $responseData');

        if (responseData['success'] == true && responseData['data'] != null) {
          counselors = List<CounselorData>.from(
            responseData['data'].map((x) => CounselorData.fromJson(x)),
          );

          // Update the appropriate list based on category
          if (categoryId == '1') {
            counselorsFortune = counselors;
          } else {
            counselorsCounseling = counselors;
          }

          notifyListeners();
        }
      } else {
        debugPrint('Failed to fetch counselors by category: ${response.body}');
        counselorError = 'Failed to fetch counselors';
      }
    } catch (e) {
      debugPrint('Error fetching counselors by category: $e');
      counselorError = 'Error: $e';
    } finally {
      userViewModel.setLoading(false);
    }
    return counselors;
  }

  // Fetch top advisors by section
  Future<List<CounselorData>> fetchTopAdvisors(
    int sectionId, {
    bool isSilently = false,
  }) async {
    List<CounselorData> topCounselors = [];
    try {
      if (!isSilently) {
        userViewModel.setLoading(true);
      }

      // Make API call to fetch top advisors
      final response = await http.get(
        Uri.parse('${ApiEndPoints.BASE_URL}top-advisor?section_id=$sectionId'),
        headers: {
          'Authorization': 'Bearer ${await userViewModel.getToken()}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // debugPrint('Top Advisors API Response: $responseData');

        if (responseData['success'] == true && responseData['data'] != null) {
          topCounselors = List<CounselorData>.from(
            responseData['data'].map((x) => CounselorData.fromJson(x)),
          );

          // Update the appropriate list based on section
          if (sectionId == 1) {
            topcounselorsFortune = topCounselors;
          } else if (sectionId == 2) {
            topcounselorsCounseling = topCounselors;
          }

          notifyListeners();
        }
      } else {
        debugPrint('Failed to fetch top advisors: ${response.body}');
        counselorError = 'Failed to fetch top advisors';
      }
    } catch (e) {
      debugPrint('Error fetching top advisors: $e');
      counselorError = 'Error: $e';
    } finally {
      userViewModel.setLoading(false);
    }
    return topCounselors;
  }

  // Fetch popular advisors by section
  Future<List<CounselorData>> fetchPopularAdvisors(
    int sectionId, {
    bool isSilently = false,
  }) async {
    List<CounselorData> popularCounselors = [];
    try {
      if (!isSilently) {
        userViewModel.setLoading(true);
      }

      // Make API call to fetch popular advisors
      final response = await http.get(
        Uri.parse(
          '${ApiEndPoints.BASE_URL}popular-advisors?section_id=$sectionId',
        ),
        headers: {
          'Authorization': 'Bearer ${await userViewModel.getToken()}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        //  debugPrint('Popular Advisors API Response: $responseData');

        if (responseData['success'] == true && responseData['data'] != null) {
          popularCounselors = List<CounselorData>.from(
            responseData['data'].map((x) => CounselorData.fromJson(x)),
          );

          // Update the appropriate list based on section
          if (sectionId == 1) {
            popularAdvisorsFortune = popularCounselors;
          } else if (sectionId == 2) {
            popularAdvisorsCounseling = popularCounselors;
          }

          notifyListeners();
        }
      } else {
        debugPrint('Failed to fetch popular advisors: ${response.body}');
        counselorError = 'Failed to fetch popular advisors';
      }
    } catch (e) {
      debugPrint('Error fetching popular advisors: $e');
      counselorError = 'Error: $e';
    } finally {
      userViewModel.setLoading(false);
    }
    return popularCounselors;
  }

  Future pullRefresh() async {
    await fetchCounselorsFroutune();
    await fetchCounselorsCounseling();
    userViewModel.fetchtaxonomie();
    await fetchTopAdvisors(userViewModel.texnomyData!.fortune.id);
    await fetchTopAdvisors(userViewModel.texnomyData!.counseling.id);
    await fetchPopularAdvisors(userViewModel.texnomyData!.fortune.id);
    await fetchPopularAdvisors(userViewModel.texnomyData!.counseling.id);
  }

  Future pullRefreshSilently() async {
    // Refresh main counselor lists (used by advoisor_tile.dart)
    await fetchCounselorsFroutune();
    await fetchCounselorsCounseling();

    // Refresh top and popular advisors
    await fetchTopAdvisors(
      userViewModel.texnomyData!.fortune.id,
      isSilently: true,
    );
    await fetchTopAdvisors(
      userViewModel.texnomyData!.counseling.id,
      isSilently: true,
    );
    await fetchPopularAdvisors(
      userViewModel.texnomyData!.fortune.id,
      isSilently: true,
    );
    await fetchPopularAdvisors(
      userViewModel.texnomyData!.counseling.id,
      isSilently: true,
    );
    notifyListeners();
  }

  // Get counselor by ID
  CounselorData? getCounselorById(int id) {
    try {
      return counselorsFortune.firstWhere((counselor) => counselor.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get counselors by specialty
  List<CounselorData> getCounselorsBySpecialty(String specialtyName) {
    return counselorsFortune.where((counselor) {
      return counselor.specialties.any(
        (specialty) =>
            specialty.name.toLowerCase() == specialtyName.toLowerCase(),
      );
    }).toList();
  }

  // Clear counselors data
  void clearCounselors() {
    counselorsFortune.clear();
    counselorsCounseling.clear();
    topcounselorsFortune.clear();
    topcounselorsCounseling.clear();
    popularAdvisorsFortune.clear();
    popularAdvisorsCounseling.clear();
    counselorError = null;
    notifyListeners();
  }

  // Fetch FAQ and Reviews by category ID
  Future<FaqAndReviewsData?> fetchFaqAndReviews(int categoryId) async {
    try {
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        debugPrint('❌ FAQ and Reviews: No token available');
        return null;
      }

      debugPrint('📋 Fetching FAQ and Reviews for category: $categoryId');

      final response = await http.get(
        Uri.parse(
          '${ApiEndPoints.FAQ_AND_REVIEWS}?category_id=$categoryId&screen=category&lang=${Get.locale?.languageCode == 'ko' ? 'ko' : 'en'}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final result = FaqAndReviewsModel.fromJson(data);
          debugPrint(
            '✅ FAQ and Reviews fetched: ${result.data.faqs.length} FAQs, ${result.data.reviews.length} Reviews',
          );
          return result.data;
        } else {
          print("categoryId****" + categoryId.toString());

          debugPrint('❌ FAQ and Reviews API error: ${data['message']}');
          return null;
        }
      } else {
        print("categoryId****" + categoryId.toString());

        debugPrint(
          '❌ FAQ and Reviews API failed: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching FAQ and Reviews: $e');
      return null;
    }
  }

  // Fetch Counselor Reviews by counselor ID
  Future<CounselorReviewsData?> fetchCounselorReviews(int counselorId) async {
    try {
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        debugPrint('❌ Counselor Reviews: No token available');
        return null;
      }

      debugPrint('📋 Fetching Counselor Reviews for counselor: $counselorId');

      final response = await http.get(
        Uri.parse(
          '${ApiEndPoints.COUNSELOR_REVIEWS}?counselor_id=$counselorId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final result = CounselorReviewsModel.fromJson(data);
          debugPrint(
            '✅ Counselor Reviews fetched: ${result.data.reviews.length} reviews, avg rating: ${result.data.summary.averageRating}',
          );
          return result.data;
        } else {
          debugPrint('❌ Counselor Reviews API error: ${data['message']}');
          return null;
        }
      } else {
        debugPrint(
          '❌ Counselor Reviews API failed: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching Counselor Reviews: $e');
      return null;
    }
  }
}
