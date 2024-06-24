import 'package:flutter/material.dart';
import 'package:ir_app/remote_controller.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({
    super.key,
    required this.rcList,
    required this.activeTabs,
    this.onRCTabChange,
  });
  final void Function(int index, bool toggle)? onRCTabChange;
  final List<RemoteController> rcList;
  final List<bool> activeTabs;

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab>
{

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("Библиотека", style: TextStyle(fontSize: 36),)
            ]
        ),
        Padding(padding: EdgeInsets.only(bottom: 50)),
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(15)
          ),
          height: 600,
          width: 350,
          child: ListView.builder(
              itemCount: widget.rcList.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  child: ListTile(title: Text(widget.rcList[index].name), trailing: Container(
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
                      ],
                    ),
                  )
                  ),
                );
              }
          ),
        ),
      ],
    );
  }
}