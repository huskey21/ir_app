import 'package:flutter/material.dart';
import 'package:ir_app/remote_controller.dart';
import 'package:ir_app/models/ir_pattern.dart';

class RCSettings extends StatefulWidget {
  const RCSettings({super.key, required this.title, required this.remoteController});
  final String title;
  final RemoteController remoteController;

  static const String necName = "NEC", extendedNecName = "ExtendedNEC", sirc20Name = "SIRC20",
      sirc15Name = "SIRC15",sirc12Name = "SIRC12",hexName = "HEX";

  static Map<String, IrPattern?> protocols = {
    RCSettings.necName: Nec(),
    RCSettings.extendedNecName: ExtendedNec(),
    RCSettings.sirc20Name: Sirc20(),
    RCSettings.sirc15Name: Sirc15(),
    RCSettings.sirc12Name: Sirc12(),
    RCSettings.hexName: null
  };

  static int setRCButton(RemoteController rc, int index, String message, String protocol, String name)
  {
    if (protocol != "HEX" && message.length != protocol.length){

      return -1;
    }
    List<int>? pattern;
    if (protocol != "HEX")
    {
      pattern = protocols[protocol]?.getPattern(message);
    }
    if (protocol != "HEX" && pattern?.length == 1)
    {
      return -2;
    }
    else {
      rc.content[index] = name;
      if (protocol == "HEX")
      {
        rc.hexCommands[index] = message;
      }
      else
      {
        rc.commands[index] = pattern!;
      }
    }
    return 0;
  }

  @override
  State<RCSettings> createState() => _RCSettingsState();
}

class _RCSettingsState extends State<RCSettings> {

  late RemoteController _remoteController;

  @override
  void initState() {
    super.initState();
    _remoteController = RemoteController.clone(widget.remoteController);
  }

  @override
  Widget build(BuildContext context) {
    for (int i = 0; i < _remoteController.onPressed.length; i++)
    {
      _remoteController.onPressed[i] = ()
      {
        showDialog(context: context, builder: (BuildContext context){
          return RCSettingsDialog(
            protocols: RCSettings.protocols.keys.toList(),
            onSubmit: (String name, String message, String protocol){
              Navigator.pop(context);
              int result = RCSettings.setRCButton(widget.remoteController, i, message, protocol, name);
              if (result == -1)
              {
                showDialog(context: context, builder: (BuildContext context){
                  return AlertDialog(
                    title: Text("Неверная длина команды"),
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
              if (result == -2)
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
              widget.remoteController.update();
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
  const RCSettingsDialog({super.key, required this.protocols, this.onSubmit});
  final List<String> protocols;
  final void Function(String name, String message, String protocol)? onSubmit;

  @override
  State<RCSettingsDialog> createState() => _RCSettingsDialogState();
}

class _RCSettingsDialogState extends State<RCSettingsDialog>
{
  String _name = "";
  String _message = "";
  late String dropdownValue;


  @override
  void initState() {
    super.initState();
    dropdownValue = widget.protocols.first;
  }

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
          DropdownMenu<String>(
            initialSelection: widget.protocols.first,
            onSelected: (String? value) {
              setState(() {
                dropdownValue = value!;
              });
            },
            dropdownMenuEntries: widget.protocols.map<DropdownMenuEntry<String>>((String value) {
              return DropdownMenuEntry<String>(value: value, label: value);
            }).toList(),
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
                widget.onSubmit!(_name, _message, dropdownValue);
              },
              child: Text("Изменить")
          )
        ],
      ),
    );
  }
}