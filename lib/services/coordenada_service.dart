import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CoordenadasService extends ChangeNotifier {
  GeoPoint? _coordenadas;

  set coordenadas(GeoPoint? coordenadas) {
    this._coordenadas = coordenadas;
    notifyListeners();
  }

  GeoPoint? get coordenadas => _coordenadas;

  @override
  String toString() {
    return coordenadas.toString();
  }
}
