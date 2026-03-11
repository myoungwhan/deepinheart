import 'dart:convert';
import 'package:deepinheart/Controller/Model/counselor_model.dart';
import 'package:deepinheart/Controller/Viewmodel/api_client.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/services/translation_helper.dart';
import 'package:deepinheart/services/translation_service.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:provider/provider.dart';

class FavoriteProvider extends ChangeNotifier {
  ApiClient apiClient = ApiClient();
  List<CounselorData> favoriteCounselors = [];
  Set<int> favoriteCounselorIds = <int>{};
  bool isLoading = false;
  bool isCheckingFavorite = false;

  // Get token from UserViewModel
  String? get _token {
    try {
      final userViewModel = navigatorKey.currentContext!.read<UserViewModel>();
      return userViewModel.userModel?.data.token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Add counselor to favorites
  Future<bool> addToFavorites(int counselorId) async {
    if (_token == null) {
      UIHelper.showBottomFlash(
        Get.context!,
        title: "Error",
        message: "Authentication required. Please login again.",
        isError: true,
      );
      return false;
    }

    try {
      isLoading = true;
      notifyListeners();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndPoints.BASE_URL + 'favorite-counselor'),
      );

      request.headers.addAll({'Authorization': 'Bearer $_token'});

      request.fields['counselor_id'] = counselorId.toString();

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = jsonDecode(responseBody);
        if (data['success'] == true) {
          favoriteCounselorIds.add(counselorId);
          notifyListeners();

          UIHelper.showBottomFlash(
            Get.context!,
            title: "Success",
            message: "Counselor added to favorites".tr,
            isError: false,
          );
          return true;
        } else {
          String message = data['message'] ?? "Failed to add to favorites".tr;
          String translatedMessage = await TranslationHelper.translateError(
            message,
          );
          UIHelper.showBottomFlash(
            Get.context!,
            title: "Error",
            message: translatedMessage ?? "Failed to add to favorites".tr,
            isError: true,
          );
          return false;
        }
      } else {
        var data = jsonDecode(responseBody);
        String message = data['message'] ?? "Failed to add to favorites".tr;
        String translatedMessage = await TranslationHelper.translateError(
          message,
        );
        UIHelper.showBottomFlash(
          Get.context!,
          title: "Error",
          message: translatedMessage ?? "Failed to add to favorites".tr,
          isError: true,
        );
        return false;
      }
    } catch (e) {
      print('Error adding to favorites: $e');
      UIHelper.showBottomFlash(
        Get.context!,
        title: "Error",
        message: "Failed to add to favorites: ${e.toString()}".tr,
        isError: true,
      );
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Remove counselor from favorites
  Future<bool> removeFromFavorites(int counselorId) async {
    if (_token == null) {
      UIHelper.showBottomFlash(
        Get.context!,
        title: "Error",
        message: "Authentication required. Please login again.",
        isError: true,
      );
      return false;
    }

    try {
      isLoading = true;
      notifyListeners();

      var headers = {'Authorization': 'Bearer $_token'};

      var request = http.Request(
        'DELETE',
        Uri.parse(
          '${ApiEndPoints.BASE_URL}favorite-counselor?counselor_id=$counselorId',
        ),
      );

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = jsonDecode(responseBody);
        if (data['success'] == true) {
          favoriteCounselorIds.remove(counselorId);
          favoriteCounselors.removeWhere(
            (counselor) => counselor.id == counselorId,
          );
          notifyListeners();
          String message =
              data['message'] ?? "Failed to remove from favorites".tr;
          String translatedMessage = await TranslationHelper.translateError(
            message,
          );

          UIHelper.showBottomFlash(
            Get.context!,
            title: "Success",
            message: translatedMessage ?? "Counselor removed from favorites".tr,
            isError: false,
          );
          return true;
        } else {
          UIHelper.showBottomFlash(
            Get.context!,
            title: "Error",
            message: data['message'] ?? "Failed to remove from favorites",
            isError: true,
          );
          return false;
        }
      } else {
        var data = jsonDecode(responseBody);
        UIHelper.showBottomFlash(
          Get.context!,
          title: "Error",
          message: data['message'] ?? "Failed to remove from favorites".tr,
          isError: true,
        );
        return false;
      }
    } catch (e) {
      print('Error removing from favorites: $e');
      UIHelper.showBottomFlash(
        Get.context!,
        title: "Error",
        message: "Failed to remove from favorites: ${e.toString()}",
        isError: true,
      );
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Check if counselor is in favorites
  Future<bool> checkIsFavorite(int counselorId) async {
    if (_token == null) {
      return false;
    }

    try {
      isCheckingFavorite = true;
      //notifyListeners();

      var headers = {'Authorization': 'Bearer $_token'};

      var request = http.Request(
        'GET',
        Uri.parse(
          '${ApiEndPoints.BASE_URL}check-favorite-counselor?counselor_id=$counselorId',
        ),
      );

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);
        bool isFavorite = data['data'] == true || data['data'] == 1;

        if (isFavorite) {
          favoriteCounselorIds.add(counselorId);
        } else {
          favoriteCounselorIds.remove(counselorId);
        }

        notifyListeners();
        return isFavorite;
      } else {
        print('Error checking favorite status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    } finally {
      isCheckingFavorite = false;
      notifyListeners();
    }
  }

  // Fetch all favorite counselors
  Future<List<CounselorData>> fetchFavoriteCounselors() async {
    if (_token == null) {
      return [];
    }

    try {
      isLoading = true;
      notifyListeners();

      var headers = {'Authorization': 'Bearer $_token'};

      var request = http.Request(
        'GET',
        Uri.parse(ApiEndPoints.BASE_URL + 'favorite-counselors'),
      );

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);
        if (data['success'] == true) {
          favoriteCounselors = List<CounselorData>.from(
            data['data'].map((x) => CounselorData.fromJson(x)),
          );

          // Update favorite IDs set
          favoriteCounselorIds = favoriteCounselors.map((c) => c.id).toSet();

          notifyListeners();
          return favoriteCounselors;
        } else {
          print('Error fetching favorites: ${data['message']}');
          return [];
        }
      } else {
        print('Error fetching favorites: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching favorite counselors: $e');
      return [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(int counselorId) async {
    bool isCurrentlyFavorite = favoriteCounselorIds.contains(counselorId);

    if (isCurrentlyFavorite) {
      return await removeFromFavorites(counselorId);
    } else {
      return await addToFavorites(counselorId);
    }
  }

  // Check if counselor is favorite (from local state)
  bool isFavorite(int counselorId) {
    return favoriteCounselorIds.contains(counselorId);
  }

  // Clear all favorites (for logout)
  void clearFavorites() {
    favoriteCounselors.clear();
    favoriteCounselorIds.clear();
    notifyListeners();
  }

  // Initialize favorites (call this when user logs in)
  Future<void> initializeFavorites() async {
    if (_token != null) {
      await fetchFavoriteCounselors();
    }
  }
}
