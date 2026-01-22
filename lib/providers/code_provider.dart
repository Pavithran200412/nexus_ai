import 'package:flutter/material.dart';

class CodeProvider extends ChangeNotifier {
  String _code = '';
  String get code => _code;

  void setCode(String code) {
    _code = code;
    notifyListeners();
  }
}