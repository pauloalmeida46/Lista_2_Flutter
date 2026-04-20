import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Exercícios Flutter',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF0F0F0F),
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurple,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white, // <-- AQUI resolve
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: HomePage(),
    );
  }
}

//////////////////////////////////////////////////////
// HOME
//////////////////////////////////////////////////////

class HomePage extends StatelessWidget {
  Widget buildButton(BuildContext context, String text, Widget page) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        child: Text(text, style: TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Menu')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            buildButton(context, 'Perfil do Usuário', PerfilPage()),
            buildButton(context, 'Despesas', DespesasPage()),
            buildButton(context, 'Lista de Presença', PresencaPage()),
            buildButton(context, 'Estoque', EstoquePage()),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////
// PERFIL
//////////////////////////////////////////////////////

class PerfilPage extends StatefulWidget {
  @override
  _PerfilPageState createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/perfil.json');
  }

  Future<void> salvarDados() async {
    final file = await _getFile();

    await file.writeAsString(jsonEncode({
      'nome': nomeController.text,
      'email': emailController.text,
    }));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Salvo ✔')),
    );
  }

  Future<void> carregarDados() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final dados = jsonDecode(await file.readAsString());
        setState(() {
          nomeController.text = dados['nome'] ?? '';
          emailController.text = dados['email'] ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Perfil')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nomeController, decoration: InputDecoration(labelText: 'Nome')),
            SizedBox(height: 16),
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            SizedBox(height: 24),
            ElevatedButton(onPressed: salvarDados, child: Text('Salvar')),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////
// DESPESAS
//////////////////////////////////////////////////////

class DespesasPage extends StatefulWidget {
  @override
  _DespesasPageState createState() => _DespesasPageState();
}

class _DespesasPageState extends State<DespesasPage> {
  final descricaoController = TextEditingController();
  final valorController = TextEditingController();

  List<Map<String, dynamic>> despesas = [];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/despesas.json');
  }

  Future<void> salvar() async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(despesas));
  }

  Future<void> carregar() async {
    final file = await _getFile();
    if (await file.exists()) {
      despesas = List<Map<String, dynamic>>.from(
        jsonDecode(await file.readAsString()),
      );
      setState(() {});
    }
  }

  void adicionar() {
    if (descricaoController.text.isEmpty || valorController.text.isEmpty) return;

    setState(() {
      despesas.add({
        'descricao': descricaoController.text,
        'valor': double.tryParse(valorController.text) ?? 0,
      });
    });

    descricaoController.clear();
    valorController.clear();
    salvar();
  }

  void remover(int i) {
    setState(() => despesas.removeAt(i));
    salvar();
  }

  Widget card(item, VoidCallback onDelete) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(item['descricao']),
        subtitle: Text('R\$ ${item['valor']}'),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Despesas')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: descricaoController, decoration: InputDecoration(labelText: 'Descrição')),
            SizedBox(height: 8),
            TextField(controller: valorController, decoration: InputDecoration(labelText: 'Valor')),
            SizedBox(height: 16),
            ElevatedButton(onPressed: adicionar, child: Text('Adicionar')),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: despesas.length,
                itemBuilder: (_, i) => card(despesas[i], () => remover(i)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////
// DATABASE
//////////////////////////////////////////////////////

class DatabaseHelper {
  static final instance = DatabaseHelper._init();
  static Database? _db;

  DatabaseHelper._init();

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = p.join(await getDatabasesPath(), 'app.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE presenca(id INTEGER PRIMARY KEY, nome TEXT)');
        await db.execute('CREATE TABLE estoque(id INTEGER PRIMARY KEY, nome TEXT, quantidade INTEGER)');
      },
    );
  }

  Future inserirNome(String nome) async {
    final db = await database;
    await db.insert('presenca', {'nome': nome});
  }

  Future<List<Map<String, dynamic>>> listarNomes() async {
    final db = await database;
    return db.query('presenca');
  }

  Future deletar(int id) async {
    final db = await database;
    await db.delete('presenca', where: 'id=?', whereArgs: [id]);
  }

  Future inserirProduto(String nome, int qtd) async {
    final db = await database;
    await db.insert('estoque', {'nome': nome, 'quantidade': qtd});
  }

  Future<List<Map<String, dynamic>>> listarProdutos() async {
    final db = await database;
    return db.query('estoque');
  }

  Future deletarProduto(int id) async {
    final db = await database;
    await db.delete('estoque', where: 'id=?', whereArgs: [id]);
  }
}

//////////////////////////////////////////////////////
// PRESENÇA
//////////////////////////////////////////////////////

class PresencaPage extends StatefulWidget {
  @override
  _PresencaPageState createState() => _PresencaPageState();
}

class _PresencaPageState extends State<PresencaPage> {
  final controller = TextEditingController();
  List<Map<String, dynamic>> lista = [];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  carregar() async {
    lista = await DatabaseHelper.instance.listarNomes();
    setState(() {});
  }

  adicionar() async {
    await DatabaseHelper.instance.inserirNome(controller.text);
    controller.clear();
    carregar();
  }

  remover(id) async {
    await DatabaseHelper.instance.deletar(id);
    carregar();
  }

  Widget card(item) => Container(
        margin: EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          title: Text(item['nome']),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => remover(item['id']),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Presença')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: controller, decoration: InputDecoration(labelText: 'Nome')),
            SizedBox(height: 16),
            ElevatedButton(onPressed: adicionar, child: Text('Adicionar')),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: lista.length,
                itemBuilder: (_, i) => card(lista[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////
// ESTOQUE
//////////////////////////////////////////////////////

class EstoquePage extends StatefulWidget {
  @override
  _EstoquePageState createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  final nome = TextEditingController();
  final qtd = TextEditingController();

  List<Map<String, dynamic>> lista = [];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  carregar() async {
    lista = await DatabaseHelper.instance.listarProdutos();
    setState(() {});
  }

  adicionar() async {
    await DatabaseHelper.instance.inserirProduto(
      nome.text,
      int.tryParse(qtd.text) ?? 0,
    );
    nome.clear();
    qtd.clear();
    carregar();
  }

  remover(id) async {
    await DatabaseHelper.instance.deletarProduto(id);
    carregar();
  }

  Widget card(item) => Container(
        margin: EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          title: Text(item['nome']),
          subtitle: Text('Qtd: ${item['quantidade']}'),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => remover(item['id']),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Estoque')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nome, decoration: InputDecoration(labelText: 'Produto')),
            SizedBox(height: 8),
            TextField(controller: qtd, decoration: InputDecoration(labelText: 'Quantidade')),
            SizedBox(height: 16),
            ElevatedButton(onPressed: adicionar, child: Text('Adicionar')),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: lista.length,
                itemBuilder: (_, i) => card(lista[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}