import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main(){

  runApp(MaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List toDoList = [];
  Map<String,dynamic> _lastRemoved;
  int _lastRemovedPos;


  @override
  void initState() {
    super.initState();
    _readData().then((data){
      setState(() {
        toDoList = json.decode(data);
      });

    });
    
  }

  final _todoController = TextEditingController();

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _todoController.text;
      newToDo["ok"] = false;
      _todoController.text = '';
      toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      toDoList.sort((a,b){
        if(a["ok"] && !b["ok"]) return 1;
        if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                  controller: _todoController,
                  decoration: InputDecoration(
                  labelText: "Nova Tarefa",
                  labelStyle: TextStyle(color: Colors.blueAccent)
                  ),
                ),
                ),
                RaisedButton(
                  color: Colors.blue,
                  child: Text("Criar"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                child: ListView.builder(
                padding: EdgeInsets.only(top:10.0),
                itemCount: toDoList.length,
                itemBuilder: buildItem
            ),
            onRefresh: _refresh)
          )

        ],
      ),
    );
  }

  Widget buildItem (context,index){
    return Dismissible(
      key:Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background:Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9,0.0),
          child: Icon(Icons.delete,color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(toDoList[index]["title"]),
        value:toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(toDoList[index]["ok"] ?
          Icons.check_circle : Icons.error
          ),
        ),
        onChanged: (c){
          setState(() {
            toDoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed:(direction){
        setState(() {
          _lastRemoved = Map.from(toDoList[index]);
          _lastRemovedPos = index;
          toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved["title"]} removida!"),
            action: SnackBarAction(label: "Desfazer",
              onPressed: (){
                setState(() {
                  toDoList.insert(_lastRemovedPos,_lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).showSnackBar(snack);
        });
      } ,
    );
  }

  Future<File> _getFile() async{
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");

  }

  Future<File> _saveData() async{
    String data = json.encode(toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async{
    try{
      final file = await _getFile();
      return file.readAsString();
    }catch(e){
      return null;
    }
  }
}

