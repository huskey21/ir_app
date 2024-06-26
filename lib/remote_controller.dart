import 'package:flutter/material.dart';
import 'package:ir_sensor_plugin/ir_sensor_plugin.dart';

class RemoteController
{
  late String name;
  late int _rows, _columns;
  List<Function()> onPressed = [];
  List<List<int>> commands = [];
  List<String> hexCommands = [];
  List<String> content = [];
  late ButtonStyle? _buttonStyle;

  RemoteController(this.name, int rows, int columns, {List<String>? content, ButtonStyle? buttonStyle})
  {
    if (content != null)
    {
      this.content = content;
    }
    else
    {
      this.content = new List<String>.filled(rows * columns, "");
    }
    for (int i = 0; i < rows * columns;i++)
    {
      onPressed.add((){});
    }
    _rows = columns;
    _columns = rows;
    _buttonStyle = buttonStyle;
    onPressed = new List<Function()>.filled(this.content.length, (){});
    commands = new List<List<int>>.filled(this.content.length, []);
    hexCommands = new List<String>.filled(this.content.length, "");
  }

  RemoteController.clone(RemoteController rc): this(rc.name, rc._rows, rc._columns, content: rc.content, buttonStyle: rc._buttonStyle);

  Future<void> IRTransmit(List<int> pattern) async
  {
    final String result = await IrSensorPlugin.transmitListInt(list: pattern);
  }

  Future<void> IRTransmitHex(String pattern) async
  {
    final String result = await IrSensorPlugin.transmitString(pattern: pattern);
  }

  void update()
  {
    for (int i = 0; i < commands.length; i++)
    {
      if (!commands[i].isEmpty){
        onPressed[i] = (){
          IRTransmit(commands[i]);
        };
      }
      else if (!hexCommands[i].isEmpty)
      {
        onPressed[i] = (){
          IRTransmitHex(hexCommands[i]);
        };
      }
    }
  }

  String getSQLSave()
  {
    return "($name,$_rows,$_columns,1)\n";
  }

  Row _getRow(List<String> content)
  {
    List<TextButton> buttons = [];
    for (int i = 0; i < content.length;i++)
    {
      buttons.add(TextButton(onPressed: onPressed[i], style: _buttonStyle, child: Text(content[i])));
    }
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: buttons);
  }

  Widget build()
  {
    List<Row> rows = [];
    for (int row = 0; row < _rows; row++)
    {
      List<String> local_content = [];
      for (int column = 0; column < _columns; column++)
      {
        local_content.add(content[row * _columns + column]);
      }
      rows.add(_getRow(local_content));
    }
    return Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: rows);
  }
}