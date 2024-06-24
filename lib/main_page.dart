import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ir_app/library.dart';
import 'package:ir_app/rc_settings.dart';
import 'package:ir_app/tabs_manager.dart';
import 'package:ir_app/remote_controller.dart';
import 'package:ir_app/settings_tab.dart';
import 'package:ir_sensor_plugin/ir_sensor_plugin.dart';

ButtonStyle buttonStyle1 = ButtonStyle(
    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
            side: const BorderSide(color: Colors.green, width: 2)
        )
    )
);

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.onThemeBrightnessChange});
  final String title;
  final void Function()? onThemeBrightnessChange;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  String settingsTabName = "Settings";
  String libraryTabName = "Library";
  bool hasIrEmitter = true;

  late TabsManager tabs;

  List<RemoteController> rcList = [
    new RemoteController("1", 3, 3, buttonStyle: buttonStyle1),
    new RemoteController("2", 2, 2, buttonStyle: buttonStyle1),
    new RemoteController("3", 2, 5, buttonStyle: buttonStyle1)
  ];
  List<RemoteController> rcLibraryList = [new RemoteController("1", 3, 3, buttonStyle: buttonStyle1)];

  List<bool> activeTabs = [false,false,false];
  List<bool> activeLibraryTabs = [false,false,false];

  Future<void> getIRStatus() async
  {
    hasIrEmitter = await IrSensorPlugin.hasIrEmitter;
  }

  Future<List<RemoteController>> _getLibrary()
  async {
    List<RemoteController> result = [];
    var file = await rootBundle.loadString('assets/codes.json');
    var data = jsonDecode(file);
    for (String rcName in data.keys)
    {
      int columns = data[rcName].length ~/ 3 + 1, buttonsCount = data[rcName].length;
      RemoteController rc = RemoteController(rcName, 3, columns, buttonStyle: buttonStyle1);
      for (int i = 0; i < buttonsCount; i++)
      {
        var button = data[rcName][i];
        String protocol = RCSettings.hexName;
        String message = "";
        if (button['protocol'].contains("NEC"))
        {
          if (button['subdevice'] == -1)
          {
            protocol = RCSettings.necName;
            message = getBitString(button['device'], 8);
          }
          else
          {
            protocol = RCSettings.extendedNecName;
            message = getBitString(button['device'], 8) + getBitString(button['subdevice'], 8);
          }
          message += getBitString(button['function'], 8);
        }
        else if (button['protocol'].contains("Sony"))
        {
          message = getBitString(button['device'], 5);
          if (button['protocol'].contains("20"))
          {
            protocol = RCSettings.sirc12Name;
            message += getBitString(button['function'], 15);
          }
          else if (button['protocol'].contains("15"))
          {
            protocol = RCSettings.sirc15Name;
            message += getBitString(button['function'], 10);
          }
          else if (button['protocol'].contains("12"))
          {
            protocol = RCSettings.sirc12Name;
            message += getBitString(button['function'], 7);
          }
        }
        RCSettings.setRCButton(rc, i, message, protocol, button['functionname']);
      }
      rc.update();
      result.add(rc);
    }
    return result;
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
  void initState() {
    super.initState();
    tabs = new TabsManager(
        fixedTabs: {
          -1: libraryTabName,
          -2: settingsTabName
        }
    );
    _getLibrary().then((List<RemoteController> rcList){
      setState(() {
        rcLibraryList = rcList;
        activeLibraryTabs = List<bool>.filled(rcList.length, false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    getIRStatus().whenComplete((){
      if (!hasIrEmitter){
        showDialog(context: context, builder: (BuildContext context){
          return AlertDialog(
            title: Text("Отсутствует ИК датчик"),
            actions: [
              TextButton(
                  onPressed: (){
                    exit(0);
                  },
                  child: Text("Ok")
              )
            ],
          );
        });
      }
    });
    List<Widget> tabsList = [];
    for (int i = 0; i < tabs.length; i++)
    {
      if (tabs.getTabs()[i] == libraryTabName)
      {
        tabsList.add(LibraryTab(
          onRCTabChange: (int index, bool toggle)
          {
            setState(() {
              activeLibraryTabs[index] = toggle;
              if (toggle == true)
              {
                tabs.addTab(rcLibraryList[index].name);
              }
              else
              {
                tabs.removeTab(rcLibraryList[index].name);
              }
            });
          },
          rcList: rcLibraryList,
          activeTabs: activeLibraryTabs,
        ));
      }
      if (tabs.getTabs()[i] == settingsTabName)
      {
        tabsList.add(SettingsTab(
          onRCAdd: (String rcName, int rows, int columns){
            setState(() {
              rcList.add(new RemoteController(rcName, rows, columns, buttonStyle: buttonStyle1));
              activeTabs.add(false);
            });
          },
          onRCTabChange: (int index, bool toggle)
          {
            setState(() {
              activeTabs[index] = toggle;
              if (toggle == true)
              {
                tabs.addTab(rcList[index].name);
              }
              else
              {
                tabs.removeTab(rcList[index].name);
              }
            });
          },
          onRCRemove: (int index)
          {
            setState(() {
              rcList.removeAt(index);
              activeTabs.removeAt(index);
            });
          },
          onRCSettings: (int index)
          {
            setState(() {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (BuildContext context){
                    return RCSettings(title: "Настройка пульта - " + rcList[index].name, remoteController: rcList[index]);
                  })
              );
            });
          },
          onSQLRequest: (List<RemoteController> newRsList)
          {
            setState(() {
              rcList = newRsList;
            });
          },
          onThemeBrightnessChange: ()
          {
            widget.onThemeBrightnessChange!();
          },
          rcList: rcList,
          activeTabs: activeTabs,
        ));
      }
      else
      {
        for (int a = 0; a < rcList.length; a++) {
          if (tabs.getTabs()[i] == rcList[a].name) {
            tabsList.add(rcList[a].build());
            break;
          }
        }
        for (int a = 0; a < rcLibraryList.length; a++) {
          if (tabs.getTabs()[i] == rcLibraryList[a].name) {
            tabsList.add(rcLibraryList[a].build());
            break;
          }
        }
      }
    }
    return DefaultTabController(
        length: tabs.length,
        child: Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(widget.title),
            ),
            bottomNavigationBar: Container(
              height: 40,
              color: Theme.of(context).colorScheme.inversePrimary,
              child: TabBar(
                  tabs: tabs.build()
              ),
            ),
            body: TabBarView(
              children: tabsList,
            )
        )
    );
  }
}