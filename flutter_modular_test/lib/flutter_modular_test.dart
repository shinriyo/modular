library flutter_modular_test;

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

void initModule(ChildModule module, {List<Bind<Object>> replaceBinds = const [], bool initialModule = false}) {
  //Modular.debugMode = false;
  final list = module.binds;
  for (var item in list) {
    var dep = (replaceBinds).firstWhere((dep) {
      return item.runtimeType == dep.runtimeType;
    }, orElse: () => BindEmpty());
    if (dep is! BindEmpty) {
      module.binds[module.binds.indexOf(item)] = dep;
    }
  }
  //module.changeBinds(changedList);
  if (initialModule) {
    Modular.init(module);
  } else {
    Modular.bindModule(module);
  }
}

void initModules(List<ChildModule> modules, {List<Bind<Object>> replaceBinds = const []}) {
  for (var module in modules) {
    initModule(module, replaceBinds: replaceBinds);
  }
}

Widget buildTestableWidget(Widget widget) {
  return MediaQuery(
    data: MediaQueryData(),
    child: MaterialApp(
      home: widget,
    ),
  );
}
