import 'dart:io';

import 'package:flutter/material.dart';
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
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  String settingsTabName = "Settings";
  bool hasIrEmitter = true;

  TabsManager tabs = new TabsManager(
      fixedTabs: {
        -1: "Settings"
      }
  );

  List<RemoteController> rcList = [
    new RemoteController("1", 3, 3, buttonStyle: buttonStyle1),
    new RemoteController("2", 2, 2, buttonStyle: buttonStyle1),
    new RemoteController("3", 2, 5, buttonStyle: buttonStyle1)
  ];

  List<bool> activeTabs = [false,false,false];

  Future<void> getIRStatus() async
  {
    hasIrEmitter = await IrSensorPlugin.hasIrEmitter;
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
            rcList.removeAt(index);
            activeTabs.removeAt(index);
          },
          onRCSettings: (int index)
          {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (BuildContext context){
                return RCSettings(title: "Настройка пульта - " + rcList[index].name, remoteController: rcList[index]);
              })
            );
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