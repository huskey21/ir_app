import 'package:flutter/material.dart';
import 'package:ir_app/remote_controller.dart';

class RCSettings extends StatefulWidget {
  const RCSettings({super.key, required this.title, required this.remoteController});
  final String title;
  final RemoteController remoteController;

  @override
  State<RCSettings> createState() => _RCSettingsState();
}

class _RCSettingsState extends State<RCSettings> {

  late RemoteController _remoteController;

  @override
  void initState() {
    _remoteController = RemoteController.clone(widget.remoteController);
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
    pattern = pattern.reversed.toList();
    pattern.insertAll(0, [2400,600]);
    return pattern;
  }

  @override
  Widget build(BuildContext context) {
    for (int i = 0; i < _remoteController.onPressed.length; i++)
    {
      _remoteController.onPressed[i] = ()
      {
        showDialog(context: context, builder: (BuildContext context){
          return RCSettingsDialog(
            onSubmit: (String name, String message){
              Navigator.pop(context);
              if (getPattern(message).length == 1)
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
              }
              else {
                setState(() {
                  widget.remoteController.content[i] = name;
                  widget.remoteController.commands[i] = getPattern(message);
                  widget.remoteController.update();
                });
              }
            },
          );
        });
      };
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _remoteController.build()
    );
  }

}

class RCSettingsDialog extends StatefulWidget
{
  const RCSettingsDialog({super.key, this.onSubmit});
  final void Function(String name, String message)? onSubmit;

  @override
  State<RCSettingsDialog> createState() => _RCSettingsDialogState();
}

class _RCSettingsDialogState extends State<RCSettingsDialog>
{
  String _name = "";
  String _message = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Редактирование кнопки"),
      content: Column(
        children: [
          Text("Имя кнопки:"),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          SizedBox(
            width: 150,
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              onChanged: (String value){
                _name = value;
              },
            ),
          ),
          Padding(padding: EdgeInsets.only(bottom: 25)),
          Text("Сообщение:"),
          Padding(padding: EdgeInsets.only(bottom: 10)),
          SizedBox(
            width: 150,
            child: TextField(
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              onChanged: (String value){
                _message = value;
              },
            ),
          ),
          Padding(padding: EdgeInsets.only(bottom: 25)),
          TextButton(
              onPressed: () {
                widget.onSubmit!(_name, _message);
              },
              child: Text("Изменить")
          )
        ],
      ),
    );
  }
}