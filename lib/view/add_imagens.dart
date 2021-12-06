import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conhecafb/services/imagens_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:conhecafb/view/image_picker.dart';
import 'package:flutter/foundation.dart';

class AddImagens extends StatefulWidget {
  @override
  _AddImagensState createState() => _AddImagensState();
}

class _AddImagensState extends State<AddImagens> {
  List<XFile>? _imageFileList;

  set _imageFile(XFile? value) {
    _imageFileList = value == null ? null : [value];
  }

  dynamic _pickImageError;
  bool isVideo = false;
  String? _retrieveDataError;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController maxWidthController = TextEditingController();
  final TextEditingController maxHeightController = TextEditingController();
  final TextEditingController qualityController = TextEditingController();

  void _onImageButtonPressed(ImageSource source,
      {BuildContext? context, bool isMultiImage = false}) async {
    await _displayPickImageDialog(context!,
        (double? maxWidth, double? maxHeight, int? quality) async {
      try {
        final pickedFileList = await _picker.pickMultiImage(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: quality,
        );
        setState(() {
          _imageFileList = pickedFileList;
        });
      } catch (e) {
        setState(() {
          _pickImageError = e;
        });
      }
    });
  }

  Future<void> _displayPickImageDialog(
      BuildContext context, OnPickImageCallback onPick) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: Text('  Clique na opção desejada para prosseguir.'),
              ),
            ],
          ),
          // content: Column(
          //   children: <Widget>[
          //     TextField(
          //       controller: maxWidthController,
          //       keyboardType: TextInputType.numberWithOptions(decimal: true),
          //       decoration:
          //           InputDecoration(hintText: "Enter maxWidth if desired"),
          //     ),
          //     TextField(
          //       controller: maxHeightController,
          //       keyboardType: TextInputType.numberWithOptions(decimal: true),
          //       decoration:
          //           InputDecoration(hintText: "Enter maxHeight if desired"),
          //     ),
          //     TextField(
          //       controller: qualityController,
          //       keyboardType: TextInputType.number,
          //       decoration:
          //           InputDecoration(hintText: "Enter quality if desired"),
          //     ),
          //   ],
          // ),

          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.lightGreen[900],
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.lightGreen[900],
                    ),
                    child: Text(
                      'Selecionar imagens',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      double? width = maxWidthController.text.isNotEmpty
                          ? double.parse(maxWidthController.text)
                          : null;
                      double? height = maxHeightController.text.isNotEmpty
                          ? double.parse(maxHeightController.text)
                          : null;
                      int? quality = qualityController.text.isNotEmpty
                          ? int.parse(qualityController.text)
                          : null;
                      onPick(width, height, quality);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Widget _previewImages() {
    final Text? retrieveError = _getRetrieveErrorWidget();

    if (retrieveError != null) {
      return retrieveError;
    }
    if (_imageFileList != null) {
      return Semantics(
          child: ListView.builder(
            key: UniqueKey(),
            itemBuilder: (context, index) {
              return Semantics(
                label: 'image_picker_example_picked_image',
                child: kIsWeb
                    ? Image.network(_imageFileList![index].path)
                    : Image.file(File(_imageFileList![index].path)),
              );
            },
            itemCount: _imageFileList!.length,
          ),
          label: 'image_picker_example_picked_images');
    } else if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    } else {
      return const Text(
        'Você não selecionou nenhuma imagem.',
        textAlign: TextAlign.center,
      );
    }
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      setState(() {
        _imageFile = response.file;
        _imageFileList = response.files;
      });
    } else {
      _retrieveDataError = response.exception!.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            ImagensService service =
                Provider.of<ImagensService>(context, listen: false);
            service.listaImagens = _imageFileList;
            Navigator.of(context).maybePop();
          },
          icon: Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.lightGreen[900],
      ),
      body: Center(
        child: !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
            ? FutureBuilder<void>(
                future: retrieveLostData(),
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return const Text(
                        'Você não selecionou nenhuma imagem.',
                        textAlign: TextAlign.center,
                      );
                    case ConnectionState.done:
                      return _previewImages();
                    default:
                      if (snapshot.hasError) {
                        return Text(
                          'Erro ao selecionar imagem: ${snapshot.error}.',
                          textAlign: TextAlign.center,
                        );
                      } else {
                        return const Text(
                          'Você não selecionou nenhuma imagem.',
                          textAlign: TextAlign.center,
                        );
                      }
                  }
                },
              )
            : _previewImages(),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              backgroundColor: Colors.lightGreen[900],
              onPressed: () {
                _onImageButtonPressed(
                  ImageSource.gallery,
                  context: context,
                  isMultiImage: true,
                );
              },
              heroTag: 'image1',
              tooltip: 'Selecionar imagens da galeria.',
              child: const Icon(Icons.photo_library),
            ),
          ),
        ],
      ),
    );
  }
}
