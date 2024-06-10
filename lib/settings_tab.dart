import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:ir_app/SQL.dart';
import 'package:ir_app/remote_controller.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({
    super.key,
    required this.rcList,
    required this.activeTabs,
    this.onRCAdd,
    this.onRCRemove,
    this.onRCTabChange,
    this.onRCSettings,
    this.onSQLRequest
  });
  final void Function(String name, int rows, int columns)? onRCAdd;
  final void Function(int index)? onRCRemove;
  final void Function(int index)? onRCSettings;
  final void Function(int index, bool toggle)? onRCTabChange;
  final void Function(List<RemoteController> rcList)? onSQLRequest;
  final List<RemoteController> rcList;
  final List<bool> activeTabs;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab>
{
  String _rcName = "";

  void _showRCAddMenu()
  {
    showDialog(context: context, builder: (BuildContext context)
    {
      return RCAddDialog(
        rcName: _rcName,
        onSubmit: (int rows, int columns)
        {
          widget.onRCAdd!(_rcName, rows, columns);
          Navigator.of(context).pop();
        },
      );
    });
  }

  void _getRC(Results results)
  {
    Map<String, Map<String, int>> rcButtons = {};
    for (var row in results)
    {
      if (!rcButtons.keys.contains(row[0]))
      {
        if (row[4] == 0x1)
        {
          rcButtons.addAll({row[0]: {"X": row[1], "Y": row[2]}});
        }
        else
        {
          rcButtons.addAll({row[0]: {row[1]: row[2]}});
        }
      }
      else
      {
        for (String key in rcButtons.keys)
        {
          if (row[4] == 0x1)
          {
            rcButtons[key]!.addAll({"X": row[1], "Y": row[2]});
          }
          if (key == row[0])
          {
            rcButtons[key]!.addAll({row[1]:row[2]});
          }
        }
      }
    }
    List<RemoteController> rcs = [];
    for (String rc in rcButtons.keys)
    {
      List<String> content = rcButtons[rc]!.keys.toList();
      content.remove("X");
      content.remove("Y");
      rcs.add(new RemoteController(rc, rcButtons[rc]!["X"]!, rcButtons[rc]!["Y"]!, content: content));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("Настройки", style: TextStyle(fontSize: 36),)
            ]
        ),
        Padding(padding: EdgeInsets.only(bottom: 50)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text("Пульт:"),
            SizedBox(
              width: 150,
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                  labelText: 'Имя',
                ),
                onChanged: (String value){
                  _rcName = value;
                },
              ),
            ),
            TextButton(
                onPressed: () {
                  _showRCAddMenu();
                },
                child: Text("Добавить")
            ),
          ],
        ),
        Padding(padding: EdgeInsets.only(bottom: 25)),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(15)
          ),
          height: 400,
          width: 350,
          child: ListView.builder(
            itemCount: widget.rcList.length,
            itemBuilder: (BuildContext context, int index) {
              return Dismissible(
                key: Key(widget.rcList[index].name),
                child: Card(
                  child: ListTile(
                    title: Text(widget.rcList[index].name),
                    trailing: Container(
                      width: 150,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                              onPressed: (){
                                widget.onRCTabChange!(index, !widget.activeTabs[index]);
                              },
                              icon: !widget.activeTabs[index] ? Icon(Icons.add) : Icon(Icons.remove)
                          ),
                          IconButton(
                            onPressed: (){
                              widget.onRCSettings!(index);
                            },
                            icon: Icon(Icons.settings)
                          ),
                        ],
                      ),
                    )
                  ),
                ),
                onDismissed: (direction)
                {
                  setState(() {
                    widget.onRCRemove!(index);
                  });
                },
              );
            }
          ),
        ),
        Padding(padding: EdgeInsets.only(bottom: 25)),
        TextButton(
            onPressed: () {
              showDialog(context: context, builder: (BuildContext context){
                return RCSQL(
                  onSubmit: (address, user, password, dbName){
                    var parts = address.split(":");
                    int port = 0;
                    try
                    {
                      port = int.parse(parts[1]);
                    }
                    catch(Exception)
                    {
                      showDialog(context: context, builder: (BuildContext context){
                        return AlertDialog(
                          title: Text("Некорректная команда"),
                          actions: [
                            TextButton(
                                onPressed: (){
                                  Navigator.pop(context);
                                },
                                child: Text("Ok")
                            )
                          ],
                        );
                      });
                      return;
                    }
                    SQL sql = new SQL();
                    sql.onResult = _getRC;
                    sql.connectToDB(parts[0], port, user, password, dbName).whenComplete((){
                      sql.sendQuery("select * from rc");
                    });
                  },
                );
              });
            },
            child: Text("Загрузить из MySQL")
        ),
      ],
    );
  }
}

class RCAddDialog extends StatelessWidget
{
  RCAddDialog({super.key, required this.rcName, this.onSubmit});
  final String rcName;
  final void Function(int rows, int columns)? onSubmit;

  int _columns = 0, _rows = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Добавление пульта $rcName"),
      content: Column(
        children: [
          Text("Кол-во строк:"),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              onChanged: (String value){
                _rows = int.parse(value);
              },
            ),
          ),
          Padding(padding: EdgeInsets.only(bottom: 25)),
          Text("Кол-во стобцов:"),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              onChanged: (String value){
                _columns = int.parse(value);
              },
            ),
          ),
          Padding(padding: EdgeInsets.only(bottom: 25)),
          TextButton(
              onPressed: () {
                onSubmit!(_rows, _columns);
              },
              child: Text("Добавить")
          ),
        ],
      ),
    );
  }

}

class RCSQL extends StatelessWidget
{
  RCSQL({super.key, this.onSubmit});

  final void Function(String address, String user, String password, String dbName)? onSubmit;

  String _address = "";
  String _user = "";
  String _password = "";
  String _dbName = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Подключение к БД"),
      content: Column(
        children: [
          Text("Внимание при загрузке данных с БД будут стерты все пульты на данный момент"),
          Padding(padding: EdgeInsets.only(bottom: 25)),
          Text("Ip:port"),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              onChanged: (String value){
                _address = value;
              },
            ),
          ),
          Padding(padding: EdgeInsets.only(bottom: 25)),
          Text("User"),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              onChanged: (String value){
                _user = value;
              },
            ),
          ),
          Padding(padding: EdgeInsets.only(bottom: 25)),
          Text("Password"),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              onChanged: (String value){
                _password = value;
              },
            ),
          ),
          Padding(padding: EdgeInsets.only(bottom: 25)),
          Text("Database"),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              onChanged: (String value){
                _dbName = value;
              },
            ),
          ),
          Padding(padding: EdgeInsets.only(bottom: 25)),
          TextButton(
              onPressed: () {
                onSubmit!(_address, _user, _password, _dbName);
              },
              child: Text("Добавить")
          ),
        ],
      ),
    );
  }

}

