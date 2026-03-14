import 'package:flutter/material.dart';

class LoadingProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _feedback;

  bool get isLoading => _isLoading;
  String? get feedback => _feedback;

  void showLoading({String? feedback}) {
    _isLoading = true;
    _feedback = feedback;
    notifyListeners();
  }

  void hideLoading() {
    _isLoading = false;
    _feedback = null;
    notifyListeners();
  }
}
