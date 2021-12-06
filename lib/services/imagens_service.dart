import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagensService extends ChangeNotifier {
  List<XFile>? _listaImagens;

  set listaImagens(List<XFile>? listaImagens) {
    this._listaImagens = listaImagens;
    notifyListeners();
  }

  List<XFile>? get listaImagens => _listaImagens;
}
