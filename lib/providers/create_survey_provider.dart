import 'package:flutter/material.dart';

class CreateSurveyProvider extends ChangeNotifier {
  bool _publicToken  = false;
  bool _surveyTarget = false;

  // ── GETTERS ──
  bool get publicToken  => _publicToken;
  bool get surveyTarget => _surveyTarget;

  // ── TOGGLE ──
  void togglePublicToken(bool value) {
    _publicToken = value;
    notifyListeners();
  }

  void toggleSurveyTarget(bool value) {
    _surveyTarget = value;
    notifyListeners();
  }
}