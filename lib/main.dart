import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart';

final urlBase = 'https://api.themoviedb.org/3/';
final urlImageBase = 'https://image.tmdb.org/t/p/';
final parametroIdioma = 'language=pt-BR&';
final parametroChave = 'api_key=3a06110bb4560d0e68265abfb5c87e5b&';
final urlSubs = {
  'filmes': 'trending/movie/week?',
  'series': 'trending/tv/week?',
  'pessoas': 'trending/person/week?',
};

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie & TV Rank',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => PaginaInicial(),
      },
    );
  }
}

class PaginaInicial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Os mais populares'),
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ContainerLista('Filmes', urlSubs['filmes']),
            ContainerLista('Series', urlSubs['series']),
            ContainerLista('Personalidades', urlSubs['pessoas'])
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Em construcao',
        child: Icon(Icons.add),
      ),
    );
  }
}

class ContainerLista extends StatefulWidget {
  String _titulo;
  String _urlSub;
  bool _ehMisturada;

  ContainerLista(String titulo, String urlSub, {bool ehMisturada}) {
    this._titulo = titulo;
    this._urlSub = urlSub;
    this._ehMisturada = ehMisturada ?? false;
  }

  @override
  _ContainerListaState createState() => _ContainerListaState();
}

class Cartaz {
  String id;
  String title;
  String release_date;

  Cartaz(String id, String title, String release_date) {
    this.id = id;
    this.title = title;
    this.release_date = release_date;
  }
}

class _ContainerListaState extends State<ContainerLista> {
  List<dynamic> lista = List();
  bool estaCarregando = true;

  Future _obterListaOnline() async {
    Response response =
        await get(urlBase + widget._urlSub + parametroChave + parametroIdioma);
    print(response.statusCode);
    if (response.statusCode == 200) {
      lista = json.decode(response.body)['results'];
    } else {
      throw Exception('Falha ao obter a lista');
    }

    setState(() {
      estaCarregando = false;
    });
    print(lista);
  }

  @override
  void initState() {
    _obterListaOnline();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget._titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  )),
              estaCarregando
                  ? Center(child: CircularProgressIndicator())
                  : Expanded(
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: lista.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: SizedBox(
                                width: 200,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: <Widget>[
                                    Image.network(
                                        urlImageBase +
                                            'w500' +
                                            (lista[index]['backdrop_path'] ??
                                                lista[index]['profile_path']),
                                        fit: BoxFit.cover),
                                    Container(
                                      alignment: Alignment.bottomLeft,
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        color: Colors.black.withOpacity(0.4),
                                        child: Text(
                                            lista[index]['title'] ??
                                                lista[index]['name'],
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                    )
            ]),
      ),
    );
  }
}
