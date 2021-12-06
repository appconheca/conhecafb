import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conhecafb/model/categoria.dart';
import 'package:conhecafb/model/cidade.dart';
import 'package:conhecafb/model/endereco.dart';
import 'package:conhecafb/model/estado.dart';
import 'package:conhecafb/model/ponto_turistico.dart';
import 'package:conhecafb/services/coordenada_service.dart';
import 'package:conhecafb/services/imagens_service.dart';
import 'package:conhecafb/view/pagina_principal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:provider/provider.dart';

class CadastroPontoTuristico extends StatefulWidget {
  @override
  _CadastroPontoTuristicoState createState() => _CadastroPontoTuristicoState();
}

class _CadastroPontoTuristicoState extends State<CadastroPontoTuristico> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  PontoTuristico ponto = PontoTuristico();
  String estadoUf = '';
  TextEditingController _textEditingController = TextEditingController();

  _CadastroPontoTuristicoState() {
    ponto.endereco = Endereco(cidade: Cidade(estado: Estado.values[0]));
  }

  final mask = MaskTextInputFormatter(mask: '#####-###');
  final Stream<QuerySnapshot> _categoriasStream = FirebaseFirestore.instance
      .collection('categorias')
      .orderBy('tipo', descending: false)
      .snapshots();

  final Stream<QuerySnapshot> _estadosStream = FirebaseFirestore.instance
      .collection('estados')
      .orderBy('uf', descending: false)
      .snapshots();

  List<Categoria> categoriasSelecionadas = [];

  List<Categoria> getListaCategorias() {
    List<Categoria> lista = [];
    //carregarCategorias(lista);
    return lista;
  }

  Future<void> _cadastrarPontoTuristico(BuildContext context) async {
    FormState? formState = _formKey.currentState;
    if (formState!.validate()) {
      formState.save();
      try {
        ponto.usuarioUid = auth.currentUser?.uid;
        ponto.usuarioNome = auth.currentUser?.displayName;
        ponto.dataCriacao = DateTime.now();
        await firestore.collection("pontos_turisticos").add({
          'nome': ponto.nome,
          'descricao': ponto.descricao,
          'dataCriacao': ponto.dataCriacao,
          'coordenadas': ponto.coordenadas,
          'usuario.uid': ponto.usuarioUid,
          'usuario.nome': ponto.usuarioNome,
          'endereco': ponto.endereco!.toJson(),
          'categorias': categoriasSelecionadas.map((c) => c.tipo).toList(),
        });

        await Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => PaginaPrincipal()),
              (route) => false);
        });
      } on FirebaseAuthException catch (exp) {
        print('Problemas ao salvar Ponto Turístico!');
        print(exp.message);
      }
    }
  }

  Future<void> _upload(String path, String ref) async {
    File file = File(path);
    try {
      await storage.ref(ref).putFile(file);
    } on FirebaseException catch (e) {
      throw Exception('Erro no upload: ${e.code}');
    }
  }

  _getPathAndCallUpload() async {
    var getImagens = Provider.of<ImagensService>(context, listen: false);
    List<XFile>? imagens = getImagens.listaImagens;

    if (imagens != null) {
      imagens.forEach((element) async {
        String ref = 'images/img-${DateTime.now().toString()}.jpg';
        await _upload(element.path, ref);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/principal');
          },
        ),
        title: const Text("Cadastro de Ponto Turístico"),
        actions: const [],
        backgroundColor: Colors.lightGreen[900],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // DropDownButton para escolher a categoria
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                            //color: Theme.of(context).primaryColor.withOpacity(.4),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.all(Radius.circular(4))),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _categoriasStream,
                          builder: (BuildContext context,
                              AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (snapshot.hasError) {
                              return Text(
                                'Something went wrong',
                                textDirection: TextDirection.ltr,
                              );
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            var listaItens = snapshot.data!.docs
                                .map((DocumentSnapshot document) {
                              Map<String, dynamic> json =
                                  document.data()! as Map<String, dynamic>;
                              var categoria = Categoria.fromJson(json);
                              return MultiSelectItem<Categoria>(
                                  categoria, categoria.tipo!);
                            }).toList();
                            return Column(
                              children: <Widget>[
                                MultiSelectBottomSheetField(
                                  barrierColor: Colors.black.withOpacity(.7),
                                  selectedColor: Colors.lightGreen[900],
                                  confirmText: Text(
                                    'Ok',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  cancelText: Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  initialChildSize: 0.4,
                                  listType: MultiSelectListType.LIST,
                                  searchable: true,
                                  buttonIcon: Icon(Icons.arrow_drop_down),
                                  buttonText: Text(
                                    "Selecione as categorias",
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  title: Text(
                                    "Categorias",
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  items: listaItens,
                                  onConfirm: (values) {
                                    categoriasSelecionadas =
                                        values.cast<Categoria>();
                                    print(
                                        'categoriasSelecionadas: ${categoriasSelecionadas}');
                                  },
                                  chipDisplay: MultiSelectChipDisplay(
                                    chipColor: Colors.lightGreen[900],
                                    textStyle: TextStyle(color: Colors.white),
                                    onTap: (value) {
                                      setState(() {
                                        categoriasSelecionadas.remove(value);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 65,
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/cadastroCategoria');
                        },
                        icon: Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ),
              // Caixas de texto para nome
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Defina um nome",
                  ),
                  onSaved: (value) => this.ponto.nome = value,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Campo obrigatório";
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),

              // Descrição do ponto turístico
              Padding(
                padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
                child: Container(
                  width: double.infinity,
                  child: Text(
                    "Descrição",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextFormField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => this.ponto.descricao = value,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Campo obrigatório";
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),

              // TextField para inserção de coordenada
              Center(
                child: Row(
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Consumer<CoordenadasService>(
                          builder: (context, service, child) {
                            var coordenadas = service.coordenadas;
                            if (coordenadas != null)
                              _textEditingController.text =
                                  '${coordenadas.latitude}, ${coordenadas.longitude}';

                            return TextFormField(
                              controller: _textEditingController,
                              readOnly: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Coordenadas",
                              ),
                              onSaved: (value) {
                                if (coordenadas != null) {
                                  ponto.coordenadas = coordenadas;
                                } else {
                                  ponto.coordenadas = GeoPoint(0.0, 0.0);
                                }
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      height: 65,
                      width: 65,
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/mapa');
                        },
                        icon: Icon(
                          Icons.map,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ENDERECO -----------------------------------------------------------------------------------
              Padding(
                padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
                child: Container(
                  width: double.infinity,
                  child: Text(
                    "Endereço",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Logradouro",
                  ),
                  onSaved: (value) => this.ponto.endereco!.logradouro = value,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Número",
                  ),
                  onSaved: (value) => this.ponto.endereco!.numero = value,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Complemento",
                  ),
                  onSaved: (value) => this.ponto.endereco!.complemento = value,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  inputFormatters: [mask],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "CEP",
                  ),
                  onSaved: (value) => this.ponto.endereco!.cep = value,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Referência",
                  ),
                  onSaved: (value) => this.ponto.endereco!.referencia = value,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),

              Row(
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Cidade",
                        ),
                        onSaved: (value) =>
                            this.ponto.endereco!.cidade!.nome = value,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Campo obrigatório";
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _estadosStream,
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            'Something went wrong',
                            textDirection: TextDirection.ltr,
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        return Container(
                          decoration: BoxDecoration(
                            //color: Theme.of(context).primaryColor.withOpacity(.4),
                            border: Border.all(
                              color: Colors.grey,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: DropdownButton(
                                onChanged: (value) {
                                  setState(() {
                                    String uf = value as String;
                                    ponto.endereco!.cidade!.estado = Estado
                                        .values
                                        .firstWhere((e) => e.uf == uf);
                                  });
                                },
                                value: ponto.endereco!.cidade!.estado!.uf,
                                items: snapshot.data!.docs
                                    .map((DocumentSnapshot document) {
                                  Map<String, dynamic> data =
                                      document.data()! as Map<String, dynamic>;
                                  var estado = Estado.fromJson(data);
                                  return DropdownMenuItem(
                                    value: estado.uf,
                                    child: Text(estado.nome),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 205,
                      height: 35,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.lightGreen[900],
                        ),
                        child: Row(
                          children: [
                            Text(
                              "Adicionar imagens",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Icon(Icons.photo_library)
                          ],
                        ),
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/imagens'),
                      ),
                    ),
                  ),
                  Consumer<ImagensService>(
                    builder: (context, service, child) {
                      var imagens = service.listaImagens;
                      if (imagens != null) {
                        var text = '${imagens.length} Fotos selecionadas';

                        return Text(text);
                      } else
                        return Text('');
                    },
                  ),
                ],
              ),

              // Botão para cadastrar o ponto turístico
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.lightGreen[900],
                    ),
                    child: Text(
                      "Cadastrar",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    onPressed: () {
                      _cadastrarPontoTuristico(context);
                      FormState? formState = _formKey.currentState;
                      String msg = 'Ponto turístico cadastrado com sucesso.';
                      if (!formState!.validate()) {
                        msg =
                            'Todos os campos obrigatórios devem ser preenchidos.';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                        ),
                      );
                      //_getPathAndCallUpload();
                      _textEditingController.clear();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
