import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart';

class Configuracao {
  static String obterUrlGeral() {
    return 'https://api.themoviedb.org/3/';
  }

  static String obterUrlImagem() {
    return 'https://image.tmdb.org/t/p/w500';
  }

  static String obterChave() {
    return 'api_key=3a06110bb4560d0e68265abfb5c87e5b&';
  }

  static String obterIdioma() {
    return 'language=pt-BR&';
  }

  static String obterSubUrlLista(String tipo) {
    // movie, tv ou person
    return 'trending/$tipo/week?';
  }

  static String obterSubUrlDetalhe(String tipo, String id) {
    // movie, tv pu person
    return '$tipo/$id?';
  }

  static String obterSubUrlElenco(String tipo, String id) {
    // movie ou tv
    return '$tipo/$id/credits?';
  }

  static String obterSubUrlHistorico(String id) {
    return 'person/$id/combined_credits?';
  }
}

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
        child: ListView(
          children: <Widget>[
            ContainerLista('Filmes', 'movie'),
            ContainerLista('Series', 'tv'),
            ContainerLista('Personalidades', 'person')
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

class ContainerLista extends StatelessWidget {
  String _titulo;
  String _subUrl;
  String _tipo;
  bool _ehMisturada = false;

  ContainerLista(String titulo, String tipo, {String id}) {
    this._titulo = titulo;
    this._tipo = tipo;
    switch (tipo) {
      case 'movie_cast':
        this._subUrl = Configuracao.obterSubUrlElenco('movie', id);
        this._tipo = 'person';
        break;
      case 'tv_cast':
        this._subUrl = Configuracao.obterSubUrlElenco('tv', id);
        this._tipo = 'person';
        break;
      case 'person_works':
        this._ehMisturada = true;
        this._subUrl = Configuracao.obterSubUrlHistorico(id);
        break;
      default:
        this._subUrl = Configuracao.obterSubUrlLista(tipo);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 256,
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(_titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        )),
                  ),
                  Expanded(flex: 6, child: Lista(_subUrl, _tipo, _ehMisturada))
                ])));
  }
}

class Lista extends StatefulWidget {
  String _subUrl;
  String _tipo;
  bool _ehMisturada;

  Lista(String urlSub, String tipo, bool ehMisturada) {
    this._subUrl = urlSub;
    this._tipo = tipo;
    this._ehMisturada = ehMisturada;
  }

  @override
  _ListaState createState() => _ListaState();
}

class _ListaState extends State<Lista> {
  List<dynamic> lista;
  bool estaCarregando = true;

  @override
  void initState() {
    _obterLista();
    super.initState();
  }

  Future _obterLista() async {
    String url = Configuracao.obterUrlGeral();
    String chave = Configuracao.obterChave();
    String idioma = Configuracao.obterIdioma();

    Response response = await get(url + widget._subUrl + chave + idioma);
    print('Pedido: ' + url + widget._subUrl + chave + idioma);
    print('Resposta: ' + response.statusCode.toString());

    if (response.statusCode == 200) {
      lista = json.decode(response.body)['results'] ??
          json.decode(response.body)['cast'] ??
          List();
    } else {
      throw Exception('Falha ao obter a lista');
    }

    //print(lista);
    if (mounted) {
      setState(() {
        estaCarregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: estaCarregando
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: lista.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: SizedBox(
                            width: 200,
                            child: GestureDetector(
                              onTap: () {
                                Route route = MaterialPageRoute(
                                    builder: (context) => PaginaDetalhes(
                                        tipo: lista[index]['media_type'] ??
                                            widget._tipo,
                                        id: lista[index]['id'].toString()));
                                Navigator.push(context, route);
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  obterImagem(lista[index]),
                                  Container(
                                    alignment: Alignment.bottomLeft,
                                    child: Container(
                                      color: Colors.black.withOpacity(0.4),
                                      child: ListTile(
                                        title: Text(
                                            lista[index]['title'] ??
                                                lista[index]['name'],
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      );
                    }) ??
                Text('Lista vazia'));
  }
}

class PaginaDetalhes extends StatefulWidget {
  final String id;
  final String tipo;

  PaginaDetalhes({@required this.tipo, @required this.id});

  _PaginaDetalhesState createState() => _PaginaDetalhesState();
}

class _PaginaDetalhesState extends State<PaginaDetalhes> {
  Detalhes objDetalhes;
  Map<String, dynamic> detalhes = Map();
  Map<String, String> camposDetalhes = {
    'title': 'Título',
    'name': 'Nome',
    'release_date': 'Lançamento',
    'birthday': 'Nascimento',
    'place_of_birth': 'Origem',
    'original_language': 'Idioma',
    'vote_average': 'Nota IMDB',
  };
  bool estaCarregando = true;

  initState() {
    _obterDetalhes();
    super.initState();
  }

  Future _obterDetalhes() async {
    String url = Configuracao.obterUrlGeral();
    String subUrl = Configuracao.obterSubUrlDetalhe(widget.tipo, widget.id);
    String chave = Configuracao.obterChave();
    String idioma = Configuracao.obterIdioma();

    print(url + subUrl + chave + idioma);

    Response response = await get(url + subUrl + chave + idioma);

    if (response.statusCode == 200) {
      objDetalhes = Detalhes.fromJson(json.decode(response.body));
      detalhes = json.decode(response.body);
    } else {
      throw Exception('Falha ao obter a lista');
    }
    if (mounted) {
      setState(() {
        estaCarregando = false;
      });
    }

    //print(detalhes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Detalhes'),
        ),
        body: estaCarregando
            ? Center(child: CircularProgressIndicator())
            : ListView(children: <Widget>[
                Card(
                    child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: obterImagem(detalhes)),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Column(children: objDetalhes.obterDetalhes()),
                        ),
                      ),
                    ],
                  ),
                )),
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: obterDescricao(detalhes))),
                Card(
                    child: ContainerLista(
                        widget.tipo == 'person' ? 'Trabalhos' : 'Elenco',
                        obterTipoItemLista('detalhes', widget.tipo),
                        id: detalhes['id'].toString()))
              ]));
  }
}

class Detalhes {
  List<List> linhas = List();

  Detalhes({this.linhas});

  factory Detalhes.fromJson(Map<String, dynamic> parsedJson) {
    List<List> lista = [
      parsedJson['title'] != null
          ? ['Titulo', parsedJson['title']]
          : ['Nome', parsedJson['name']],
      parsedJson['release_date'] != null
          ? ['Lançamento', parsedJson['release_date']]
          : ['Nascimento', parsedJson['birthday']],
      parsedJson['place_of_birth'] != null
          ? ['Origem', parsedJson['place_of_birth']]
          : ['Idioma', parsedJson['original_language']]
    ];
    if(parsedJson.containsKey('vote_average')){
      lista.add(['Nota IMDB', parsedJson['vote_average']]);
    }
    return Detalhes(linhas: lista);
  }

  List<Widget> obterDetalhes() {
    return List.generate(linhas.length, (index) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            linhas[index][0],
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Flexible(child: Text(linhas[index][1].toString()))
        ],
      );
    });
  }
}

String obterTipoItemLista(String pagina, String tipo) {
  if (pagina == 'detalhes') {
    if (tipo == 'movie') {
      return 'movie_cast';
    } else if (tipo == 'tv') {
      return 'tv_cast';
    }
    return 'person_works';
  }
  return tipo;
}

Widget obterDescricao(Map<String, dynamic> obj) {
  String titulo = 'Sinopse';
  String conteudo = obj['overview'];

  if (obj.containsKey('biography')) {
    titulo = 'Biografia';
    conteudo = obj['biography'];
  }
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(titulo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          )),
      Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(conteudo, textAlign: TextAlign.justify),
      )
    ],
  );
}

Widget obterImagem(Map<String, dynamic> obj) {
  String nomeImagem = '';
  if (obj.containsKey('poster_path')) {
    nomeImagem = obj['poster_path'];
  } else if (obj.containsKey('backdrop_path')) {
    nomeImagem = obj['backdrop_path'];
  } else if (obj.containsKey('profile_path')) {
    nomeImagem = obj['profile_path'];
  }

  if (nomeImagem == null) {
    return Image.asset('assets/imagens/sem-foto.jpg', fit: BoxFit.cover);
  }

  return Image.network(Configuracao.obterUrlImagem() + nomeImagem,
      fit: BoxFit.cover);
}
