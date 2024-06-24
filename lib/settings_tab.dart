import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:ir_app/main.dart';
import 'package:ir_app/main_page.dart';
import 'package:ir_app/models/ir_pattern.dart';
import 'package:mysql1/mysql1.dart';
import 'package:ir_app/SQL.dart';
import 'package:ir_app/remote_controller.dart';
import 'package:ir_app/rc_settings.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({
    super.key,
    required this.rcList,
    required this.activeTabs,
    this.onRCAdd,
    this.onRCRemove,
    this.onRCTabChange,
    this.onRCSettings,
    this.onSQLRequest,
    this.onThemeBrightnessChange
  });
  final void Function(String name, int rows, int columns)? onRCAdd;
  final void Function(int index)? onRCRemove;
  final void Function(int index)? onRCSettings;
  final void Function(int index, bool toggle)? onRCTabChange;
  final void Function(List<RemoteController> rcList)? onSQLRequest;
  final void Function()? onThemeBrightnessChange;
  final List<RemoteController> rcList;
  final List<bool> activeTabs;

  static String getBitString(int number)
  {
    return getReverseBitString(number).split('').reversed.join();
  }

  static String getReverseBitString(int number)
  {
    if (number < 2)
    {
      return "$number";
    }
    else
    {
      if (number % 2 == 0)
      {
        return "0" + getBitString(number ~/ 2);
      }
      else
      {
        return "1" + getBitString(number ~/ 2);
      }
    }
  }

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

  List<int> getPattern(String code)
  {
    List<int> pattern = [];
    List<String> symbols = code.split('');
    for (String symbol in symbols)
    {
      if (symbol == "1")
      {
        pattern.addAll([1200,600]);
      }
      else if(symbol == "0")
      {
        pattern.addAll([600,600]);
      }
      else
      {
        return [-1];
      }
    }
    pattern.insertAll(0, [2400,600]);
    return pattern;
  }

  void _getRC(Results results)
  {
    List<RemoteController> rcs = [];
    List<List<String>> rcCommands = [];
    List<List<String>> rcProtocols = [];
    List<String> rcNames = [];
    List<List<String>> rcButtonsNames = [];
    for (var row in results)
    {
      int lastIndex = rcNames.length - 1;
      if (rcNames.isNotEmpty || rcNames[lastIndex] == row[0])
      {
        var protocolAndCommand = getCommandAndProtocol(row);
        rcProtocols[lastIndex].add(protocolAndCommand.keys.toList()[0]);
        rcCommands[lastIndex].add(protocolAndCommand.values.toList()[0]);
        rcButtonsNames[lastIndex].add(row[1]);
      }
      else
      {
        rcNames.add(row[0]);
        var protocolAndCommand = getCommandAndProtocol(row);
        rcProtocols.add([protocolAndCommand.keys.toList()[0]]);
        rcCommands.add([protocolAndCommand.values.toList()[0]]);
        rcButtonsNames.add([row[1]]);
      }
    }
    for (int i = 0; i < rcNames.length; i++)
    {
      List<String> commands = rcCommands[i];
      List<String> protocols = rcProtocols[i];
      List<String> names = rcButtonsNames[i];
      int rows = commands.length ~/ 3 + 1;
      RemoteController remoteController = new RemoteController(rcNames[i], rows, 3);
      for (int a = 0; a < commands.length; a++)
      {
        RCSettings.setRCButton(remoteController, a, commands[a], protocols[a], names[a]);
      }
      remoteController.update();
      rcs.add(remoteController);
    }
    widget.onSQLRequest!(rcs);
  }

  void _sendSQlSave(String ip, int port, String user, String password, String dbName)
  {
    String query = "insert into rc values\n";
    for (RemoteController rc in widget.rcList)
    {
      query += rc.getSQLSave();
      for (int i = 0; i < rc.content.length; i++)
      {
        int command = 0;
        for (int a = rc.commands[i].length - 2;  a >= 2; a -= 2)
        {
          command += (((rc.commands[i][a] / 600) as int) - 1) * 2^(((a/2)as int)-1);
        }
        query += "(${rc.name},${rc.content[i]},${command},0)\n";
      }
    }
    SQL sql = new SQL();
    sql.connectToDB(ip, port, user, password, dbName).whenComplete((){
      sql.sendQuery(query);
    });
  }

  Map<String, String> getCommandAndProtocol(var data)
  {
    String protocol = RCSettings.hexName;
    String message = data[5];
    if (data[2].contains("NEC"))
    {
      if (data[4] == -1)
      {
        protocol = RCSettings.necName;
        message = getBitString(data[3], 8);
      }
      else
      {
        protocol = RCSettings.extendedNecName;
        message = getBitString(data[3], 8) + getBitString(data[4], 8);
      }
      message += getBitString(data[5], 8);
    }
    else if (data[2].contains("Sony"))
    {
      message = getBitString(data[3], 5);
      if (data[2].contains("20"))
      {
        protocol = RCSettings.sirc12Name;
        message += getBitString(data[5], 15);
      }
      else if (data[2].contains("15"))
      {
        protocol = RCSettings.sirc15Name;
        message += getBitString(data[5], 10);
      }
      else if (data[2].contains("12"))
      {
        protocol = RCSettings.sirc12Name;
        message += getBitString(data[5], 7);
      }
    }
    return {protocol: message};
  }

  String getBitString(int number, symbolCount)
  {
    String result = SettingsTab.getBitString(number);
    while (result.length < symbolCount)
    {
      result += "0" + result;
    }
    if (result.length > symbolCount)
    {
      var slices = result.split('');
      result = "";
      for (int i = slices.length - 1; i > slices.length - 1 - symbolCount; i--)
      {
        result += slices[i];
      }
    }
    return result;
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
        Padding(padding: EdgeInsets.only(bottom: 30)),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(child: Text("Темный режим:"), onPressed: ()
              {
                widget.onThemeBrightnessChange!();
              }, style: buttonStyle1)
            ]
        ),
        Padding(padding: EdgeInsets.only(bottom: 25)),
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
                child: Text("Добавить"), style: buttonStyle1
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
        Center(
         child: Row(
          children: [
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
                              title: Text("Некорректная ip адрес"),
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
                child: Text("Загрузить из MySQL"), style: buttonStyle1
            ),
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
                              title: Text("Некорректная ip адрес"),
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
                        _sendSQlSave(parts[0], port, user, password, dbName);
                      },
                    );
                  });
                },
                child: Text("Загрузить в MySQL"), style: buttonStyle1
              ),
            ],
           mainAxisAlignment: MainAxisAlignment.spaceAround,
          )
        )
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

