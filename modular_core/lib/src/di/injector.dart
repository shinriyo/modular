import 'package:meta/meta.dart';
import 'reassemble_mixin.dart';
import 'package:modular_interfaces/modular_interfaces.dart';
import 'bind_context.dart';
import 'resolvers.dart';
import 'package:characters/characters.dart';

class InjectorImpl<T> implements Injector<T> {
  final _allBindContexts = <Type, BindContext>{};

  @override
  B call<B extends Object>([BindContract<B>? bind]) => get<B>(bind);

  @override
  B get<B extends Object>([BindContract<B>? bind]) {
    B? bind;

    for (var module in _allBindContexts.values) {
      bind = module.getBind<B>(this);
      if (bind != null) {
        break;
      }
    }

    if (bind != null) {
      return bind;
    } else {
      throw BindNotFound(B.toString());
    }
  }

  @override
  @mustCallSuper
  bool isModuleAlive<B extends BindContext>() =>
      _allBindContexts.containsKey(_getType<B>());

  @override
  @mustCallSuper
  Future<bool> isModuleReady<M extends BindContext>() async {
    if (isModuleAlive<M>()) {
      await _allBindContexts[_getType<M>()]!.isReady();
      return true;
    }
    return false;
  }

  @override
  @mustCallSuper
  void addBindContext(covariant BindContextImpl module, {String tag = ''}) {
    final typeModule = module.runtimeType;
    if (!_allBindContexts.containsKey(typeModule)) {
      _allBindContexts[typeModule] = module;
      (_allBindContexts[typeModule] as BindContextImpl)
          .instantiateSingletonBinds(_getAllSingletons(), this);
      (_allBindContexts[typeModule] as BindContextImpl).tags.add(tag);
      debugPrint("-- $typeModule INITIALIZED");
    } else {
      (_allBindContexts[typeModule] as BindContextImpl?)?.tags.add(tag);
    }
  }

  @visibleForTesting
  void debugPrint(String text) {
    printResolverFunc?.call(text);
  }

  @override
  @mustCallSuper
  void disposeModuleByTag(String tag) {
    final trash = <Type>[];

    for (var key in _allBindContexts.keys) {
      final module = _allBindContexts[key]!;

      (module as BindContextImpl).tags.remove(tag);
      if (tag.characters.last == '/') {
        module.tags.remove('$tag/'.replaceAll('//', ''));
      }
      if (module.tags.isEmpty) {
        module.dispose();
        trash.add(key);
      }
    }

    for (final key in trash) {
      _allBindContexts.remove(key);
      debugPrint("-- $key DISPOSED");
    }
  }

  @override
  @mustCallSuper
  bool dispose<B extends Object>() {
    for (var binds in _allBindContexts.values) {
      final r = binds.remove<B>();
      if (r) return r;
    }
    return false;
  }

  @override
  void reassemble() {
    for (var binds in _allBindContexts.values) {
      for (var bind in binds.instanciatedSingletons) {
        final value = bind.value;
        if (value is ReassembleMixin) {
          value.reassemble();
        }
      }
    }
  }

  @override
  void updateBinds(BindContext context) {
    final key = _allBindContexts.keys.firstWhere(
        (key) => key.toString() == context.runtimeType.toString(),
        orElse: () => _KeyNotFound);
    if (key == _KeyNotFound) {
      return;
    }
    final module = _allBindContexts[key]!;
    module.changeBinds(List<BindContract>.from(context.getProcessBinds()));
  }

  @override
  @mustCallSuper
  void destroy() {
    for (var binds in _allBindContexts.values) {
      binds.dispose();
    }
    _allBindContexts.clear();
  }

  @override
  @mustCallSuper
  void removeBindContext<B extends BindContext>() {
    final module = _allBindContexts.remove(_getType<B>());
    if (module != null) {
      module.dispose();
      debugPrint("-- ${module.runtimeType} DISPOSED");
    }
  }

  Type _getType<G>() => G;

  List<SingletonBind> _getAllSingletons() {
    final list = <SingletonBind>[];
    for (var module in _allBindContexts.values) {
      list.addAll((module as BindContextImpl).instanciatedSingletons);
    }
    return list;
  }

  @mustCallSuper
  @override
  void removeScopedBinds() {
    for (var context in _allBindContexts.values.cast<BindContextImpl>()) {
      context.removeScopedBind();
    }
  }
}

class BindNotFound extends ModularError {
  BindNotFound(String message) : super(message);
}

class _KeyNotFound {}
