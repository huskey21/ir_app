import 'package:flutter/material.dart';

class TabsManager
{
  int get length => _tabs.length + _fixedTabs.length;

  List<String> _tabs = [];
  Map<int, String> _fixedTabs = {};

  TabsManager({Map<int, String>? fixedTabs, List<String>? tabs})
  {
    if (fixedTabs != null) {
      _fixedTabs = fixedTabs;
    }
    if (tabs != null) {
      _tabs = tabs;
    }
  }

  void addTab(String value, {int? index})
  {
    if (index == null) {
      _tabs.add(value);
    }
    else
    {
      _tabs.insert(index, value);
    }
  }

  void removeTabAt(int index)
  {
    if (index < 0 || index >= _tabs.length)
    {
      throw RangeError("Out of range");
    }
    _tabs.removeAt(index);
  }

  void removeTab(String value)
  {
    if (!_tabs.contains(value))
    {
      throw ArgumentError("The element does not exist");
    }
    _tabs.remove(value);
  }

  List<String> getTabs()
  {
    List<String> tabs = [];
    for (int i = 0; i < _tabs.length; i++)
    {
      tabs.add(_tabs[i]);
    }
    for (int key in _fixedTabs.keys)
    {
      if (tabs.length == 0)
      {
        tabs.add(_fixedTabs[key].toString());
      }
      else
      {
        if (key > 0)
        {
          tabs.insert(key, _fixedTabs[key].toString());
        }
        if (key < 0)
        {
          tabs.insert(tabs.length + key + 1, _fixedTabs[key].toString());
        }
      }
    }
    return tabs;
  }

  List<Widget> build()
  {
    List<Widget> tabs = [];
    for (int i = 0; i < _tabs.length; i++)
    {
      tabs.add(Text(_tabs[i]));
    }
    for (int key in _fixedTabs.keys)
    {
      if (tabs.length == 0)
      {
        tabs.add(Text(_fixedTabs[key].toString()));
      }
      else
      {
        if (key > 0)
        {
          tabs.insert(key, Text(_fixedTabs[key].toString()));
        }
        if (key < 0)
        {
          tabs.insert(tabs.length + key + 1, Text(_fixedTabs[key].toString()));
        }
      }
    }
    return tabs;
  }
}