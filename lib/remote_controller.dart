import 'package:flutter/material.dart';

class RemoteController
{
  late String name;
  late int _rows, _columns;
  List<Function()> onPressed = [];
  List<String> content = [];
  late ButtonStyle? _buttonStyle;

  RemoteController(this.name, int rows, int columns, {List<String>? content, ButtonStyle? buttonStyle})
  {
    if (content != null)
    {
      if (rows * columns != content.length)
      {
        throw ArgumentError("Wrong size of content");
      }
      this.content = content;
    }
    else
    {
      for (int i = 0; i < rows * columns;i++)
      {
        this.content.add("default");
      }
    }
    for (int i = 0; i < rows * columns;i++)
    {
      onPressed.add((){});
    }
    _rows = rows;
    _columns = columns;
    _buttonStyle = buttonStyle;
  }

  RemoteController.clone(RemoteController rc): this(rc.name, rc._rows, rc._columns, content: rc.content, buttonStyle: rc._buttonStyle);

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